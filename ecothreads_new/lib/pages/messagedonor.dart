import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:cached_network_image/cached_network_image.dart';

class MessageDonor extends StatefulWidget {
  final String? chatId;
  final String? donorId;
  final String? donorName;
  final String? itemName;
  final String? itemId; // Added parameter
  final String? itemImage; // Added parameter

  const MessageDonor({
    Key? key,
    this.chatId,
    this.donorId,
    this.donorName,
    this.itemName,
    this.itemId, // Added parameter
    this.itemImage, // Added parameter
  }) : super(key: key);

  @override
  State<MessageDonor> createState() => _MessageDonorState();
}

class _MessageDonorState extends State<MessageDonor> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // For local messages when chatId is not provided
  final List<Map<String, dynamic>> localMessages = [];

  // Firebase messages stream
  Stream<QuerySnapshot>? _messagesStream;

  // Generated chatId for new conversations
  String? _generatedChatId;

  // Donor profile image
  String? _donorProfileImage;

  @override
  void initState() {
    super.initState();

    // Initialize Firebase message stream if chatId is provided
    if (widget.chatId != null) {
      _checkChatAccess();
    }

    // Fetch donor profile image if donorId is provided
    if (widget.donorId != null) {
      _fetchDonorProfileImage();
    }
  }

  // Check if user can access this chat and initialize streams
  Future<void> _checkChatAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.chatId == null) return;

    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      if (chatDoc.exists) {
        final chatData = chatDoc.data() as Map<String, dynamic>;
        final List<dynamic> deletedFor = chatData['deletedFor'] ?? [];

        // If this user previously deleted the chat, remove them from deletedFor
        // because they're reopening the chat
        if (deletedFor.contains(user.uid)) {
          final updatedDeletedFor = List<dynamic>.from(deletedFor);
          updatedDeletedFor.remove(user.uid);

          await FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .update({'deletedFor': updatedDeletedFor});
        }

        // Initialize the message stream now that we confirmed access
        _messagesStream = FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .snapshots();

        // Mark chat as read when opened
        _markChatAsRead();
      }
    } catch (e) {
      print('Error checking chat access: $e');
    }
  }

  // Fetch donor's profile image
  void _fetchDonorProfileImage() async {
    if (widget.donorId == null) return;

    try {
      final donorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.donorId)
          .get();

      if (donorDoc.exists) {
        final userData = donorDoc.data();
        if (userData != null) {
          // Try different possible field names for profile image
          final profileImage = userData['profileImage'] ??
              userData['profileImageUrl'] ??
              userData['userProfileImage'] ??
              userData['photoURL'] ??
              userData['avatar'];

          if (profileImage != null && mounted) {
            setState(() {
              _donorProfileImage = profileImage;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching donor profile: $e');
    }
  }

  void _markChatAsRead() async {
    if (widget.chatId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get the chat document
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      final chatData = chatDoc.data();

      // Only reset unread count if the last message was not from the current user
      if (chatData != null && chatData['lastSenderId'] != user.uid) {
        // Reset unread count for this chat
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .update({'hasUnreadMessages': false, 'unreadCount': 0});
      }

      // Get all unread messages
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .get();

      // Batch update for better performance
      final batch = FirebaseFirestore.instance.batch();

      for (final messageDoc in messagesSnapshot.docs) {
        final messageData = messageDoc.data();
        final List<dynamic> readBy = messageData['readBy'] ?? [];

        // If user hasn't read this message yet
        if (!readBy.contains(user.uid)) {
          readBy.add(user.uid);
          batch.update(messageDoc.reference, {'readBy': readBy});
        }
      }

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  void _sendMessage() async {
    if (messageController.text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String messageText = messageController.text;
    String messageDate = DateFormat('EEEE').format(DateTime.now());
    String messageTime =
        DateFormat('h:mm:ss a').format(DateTime.now()); // Added seconds

    // Determine which chatId to use
    String? chatIdToUse = widget.chatId ?? _generatedChatId;

    // If no chatId exists yet, we need to create a new chat
    if (chatIdToUse == null &&
        widget.donorId != null &&
        widget.itemId != null) {
      // Generate a new chat ID incorporating item ID for separate conversations per item
      chatIdToUse = '${user.uid}_${widget.donorId}_${widget.itemId}';

      // Save it for future messages
      setState(() {
        _generatedChatId = chatIdToUse;
      });

      // Create the chat document first time a message is sent
      try {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatIdToUse)
            .set({
          'participants': [user.uid, widget.donorId],
          'lastMessage': messageText,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': user.uid,
          'itemId': widget.itemId,
          'itemName': widget.itemName,
          'itemImage': widget.itemImage,
          'hasUnreadMessages': true,
          'unreadCount': 1,
          'deletedFor': [],
          'readBy': [user.uid],
        });

        // Initialize the message stream immediately after creating chat
        setState(() {
          _messagesStream = FirebaseFirestore.instance
              .collection('chats')
              .doc(chatIdToUse)
              .collection('messages')
              .orderBy('timestamp', descending: false)
              .snapshots();
        });
      } catch (e) {
        print('Error creating chat: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating chat')),
        );
        return;
      }
    }

    // Send the message now that we have a valid chatId
    if (chatIdToUse != null) {
      try {
        // Add message to Firestore
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatIdToUse)
            .collection('messages')
            .add({
          'text': messageText,
          'senderId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'date': messageDate,
          'time': messageTime,
          'readBy': [user.uid],
        });

        // Update last message in chat document
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatIdToUse)
            .update({
          'lastMessage': messageText,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': user.uid,
          'hasUnreadMessages': true,
          'unreadCount': FieldValue.increment(1),
          'readBy': [user.uid],
        });

        // Clear the text field
        messageController.clear();

        // Scroll to bottom of chat
        _scrollToBottom();
      } catch (e) {
        print('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message')),
        );
      }
    } else {
      // If we somehow still don't have a chatId, fall back to local messages
      setState(() {
        localMessages.add({
          "text": messageText,
          "date": messageDate,
          "time": messageTime,
          "isSent": true,
        });
      });
      messageController.clear();
      _scrollToBottom();
    }
  }

  Future<File> _compressImage(File file) async {
    // Read file bytes
    final bytes = await file.readAsBytes();

    // Decode image
    final image = img.decodeImage(bytes);
    if (image == null) return file;

    // Calculate new dimensions while maintaining aspect ratio
    final maxWidth = 800.0;
    final maxHeight = 800.0;
    double width = image.width.toDouble();
    double height = image.height.toDouble();

    if (width > maxWidth || height > maxHeight) {
      final ratio = width / height;

      if (width > height) {
        width = maxWidth;
        height = width / ratio;
      } else {
        height = maxHeight;
        width = height * ratio;
      }
    }

    // Resize image
    final resized = img.copyResize(
      image,
      width: width.toInt(),
      height: height.toInt(),
      interpolation: img.Interpolation.linear,
    );

    // Encode to jpg with reduced quality
    final compressed = img.encodeJpg(resized, quality: 70);

    // Create temporary file
    final tempPath = file.parent.path;
    final tempFile = File(
        '$tempPath/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');

    // Write compressed data to file
    await tempFile.writeAsBytes(compressed);

    return tempFile;
  }

  Future<void> _sendImageMessage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Compress image
      final File compressedFile = await _compressImage(File(image.path));

      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(
        compressedFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Delete temporary compressed file
      await compressedFile.delete();

      final imageUrl = await storageRef.getDownloadURL();

      // Prepare message data
      String messageDate = DateFormat('EEEE').format(DateTime.now());
      String messageTime =
          DateFormat('h:mm:ss a').format(DateTime.now()); // Added seconds

      // Get or create chat ID
      String? chatIdToUse = widget.chatId ?? _generatedChatId;
      if (chatIdToUse == null) {
        // Create new chat if needed (similar to text message logic)
        // ...existing chat creation code...
      }

      if (chatIdToUse != null) {
        // Add image message to Firestore
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatIdToUse)
            .collection('messages')
            .add({
          'imageUrl': imageUrl,
          'type': 'image',
          'senderId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'date': messageDate,
          'time': messageTime,
          'readBy': [user.uid],
        });

        // Update last message in chat document
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatIdToUse)
            .update({
          'lastMessage': '📸  Image',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': user.uid,
          'hasUnreadMessages': true,
          'unreadCount': FieldValue.increment(1),
          'readBy': [user.uid],
        });
      }

      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error sending image: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending image')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          // Fixed back button
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context)
                .pop(); // Use Navigator.of(context) for safer navigation
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Only show donor profile image
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                backgroundImage: _donorProfileImage != null
                    ? NetworkImage(_donorProfileImage!)
                    : null,
                child: _donorProfileImage == null
                    ? Icon(
                        Icons.person,
                        color: Colors.grey.shade600,
                        size: 20,
                      )
                    : null,
              ),
            ),
            // Donor name and item info
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.donorName ?? 'Donor',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.itemName != null)
                    Text(
                      'Item: ${widget.itemName}',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 5),
          Expanded(
            // Show Firebase messages if chatId is provided, otherwise show local messages
            child: widget.chatId != null || _generatedChatId != null
                ? _buildFirebaseMessages()
                : _buildLocalMessages(),
          ),
          const SizedBox(height: 5),
          ChatInputField(
            messageController: messageController,
            onSend: _sendMessage,
            onImagePick: _sendImageMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseMessages() {
    if (widget.chatId == null && _generatedChatId == null) {
      return _buildEmptyState();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return _buildLoadingState();
        }

        final messages = snapshot.data!.docs;
        final currentUser = FirebaseAuth.instance.currentUser;

        return ListView.builder(
          controller: scrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageData = messages[index].data() as Map<String, dynamic>;
            final bool isSent = messageData['senderId'] == currentUser?.uid;

            bool showDate = false;
            if (index == 0) {
              showDate = true;
            } else {
              final prevMessageData =
                  messages[index - 1].data() as Map<String, dynamic>;
              if (messageData['date'] != prevMessageData['date']) {
                showDate = true;
              }
            }

            return _buildMessageItem(
              messageData: messageData,
              isSent: isSent,
              showDate: showDate,
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 6,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemBuilder: (context, index) {
        final bool isEven = index.isEven;
        return Align(
          alignment: isEven ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 40,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          TextButton(
            onPressed: _checkChatAccess,
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Start the conversation',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Send a message to begin chatting',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Display local messages
  Widget _buildLocalMessages() {
    return ListView.builder(
      controller: scrollController,
      itemCount: localMessages.length,
      itemBuilder: (context, index) {
        final message = localMessages[index];
        bool isSent = message["isSent"];
        bool showDate = false;

        if (index == 0 ||
            message["date"] != localMessages[index - 1]["date"] ||
            localMessages[index - 1]["isSent"] != isSent) {
          showDate = true;
        }

        return _buildMessageItem(
          messageData: message,
          isSent: isSent,
          showDate: showDate,
        );
      },
    );
  }

  // Common message item widget without individual status text
  Widget _buildMessageItem({
    required Map<String, dynamic> messageData,
    required bool isSent,
    required bool showDate,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4.0,
        horizontal: 8.0,
      ),
      child: Column(
        crossAxisAlignment:
            isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showDate)
            Center(
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 16),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  messageData["date"] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(top: 4.0),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: isSent ? Colors.black : Colors.grey[300],
              borderRadius: isSent
                  ? BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(4),
                    )
                  : BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
            ),
            child: messageData['type'] == 'image'
                ? _buildImageMessage(messageData['imageUrl'], isSent)
                : _buildTextMessage(messageData["text"] ?? '', isSent),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(String url, bool isSent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 200,
          height: 200,
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isSent ? Colors.white70 : Colors.black26,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 200,
          height: 200,
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                color: isSent ? Colors.white70 : Colors.black26,
              ),
              SizedBox(height: 4),
              Text(
                'Image not available',
                style: TextStyle(
                  fontSize: 12,
                  color: isSent ? Colors.white70 : Colors.black26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextMessage(String text, bool isSent) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: isSent ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

class ChatInputField extends StatelessWidget {
  final TextEditingController messageController;
  final VoidCallback onSend;
  final VoidCallback onImagePick;

  ChatInputField({
    required this.messageController,
    required this.onSend,
    required this.onImagePick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Image picker button
          IconButton(
            icon: Icon(Icons.image, color: Colors.grey),
            onPressed: onImagePick,
          ),
          // TextField for message input
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'Write your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
            ),
          ),
          SizedBox(width: 8),
          // Send Button
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}
