import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'donor_profile_page.dart';
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
  final bool showShippingButton;

  const MessageDonor({
    Key? key,
    this.chatId,
    this.donorId,
    this.donorName,
    this.itemName,
    this.itemId, // Added parameter
    this.itemImage, // Added parameter
    this.showShippingButton = false,
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

  // Add new state variable
  bool _hasBeenShipped = false;
  bool _isLoadingStatus = true;

  // Add this helper method
  bool get isDonor {
    final currentUser = FirebaseAuth.instance.currentUser;
    // The current user is the donor if they are NOT the donorId
    // (since donorId in this case is actually the buyer's ID)
    return currentUser?.uid != widget.donorId;
  }

  @override
  void initState() {
    super.initState();

    // Load shipping status immediately when page opens
    _loadShippingStatus();

    // Initialize Firebase message stream immediately if chatId is provided
    if (widget.chatId != null) {
      _messagesStream = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots();

      // Mark chat as read
      _markChatAsRead();
    } else if (widget.donorId != null && widget.itemId != null) {
      // Generate chat ID if not provided
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _generatedChatId =
            '${currentUser.uid}_${widget.donorId}_${widget.itemId}';

        // Initialize message stream with generated ID
        _messagesStream = FirebaseFirestore.instance
            .collection('chats')
            .doc(_generatedChatId)
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .snapshots();

        // Mark chat as read
        _markChatAsRead();
      }
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

  Future<void> _markChatAsRead() async {
    String? chatIdToUse = widget.chatId ?? _generatedChatId;
    if (chatIdToUse == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Check if chat document exists
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatIdToUse)
          .get();

      if (!chatDoc.exists) {
        // Create chat document if it doesn't exist
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatIdToUse)
            .set({
          'participants': [user.uid, widget.donorId],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': user.uid,
          'itemId': widget.itemId,
          'itemName': widget.itemName,
          'itemImage': widget.itemImage,
          'hasUnreadMessages': false,
          'unreadCount': 0,
          'deletedFor': [],
          'readBy': [user.uid],
        });
      }

      final batch = FirebaseFirestore.instance.batch();

      // Update chat document
      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(chatIdToUse);
      batch.update(chatRef, {
        'hasUnreadMessages': false,
        'unreadCount': 0,
      });

      // Get all unread messages
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatIdToUse)
          .collection('messages')
          .where('readBy', arrayContains: user.uid)
          .get();

      // Mark all messages as read
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([user.uid]),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  Future<bool> _checkUserRestriction() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Check the current user's restriction status
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final bool isRestricted = userDoc.data()?['isRestricted'] ?? false;

      if (isRestricted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Your account is currently restricted. Please contact support@ecothreads.com'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () {},
                textColor: Colors.white,
              ),
            ),
          );
        }
      }

      return isRestricted;
    } catch (e) {
      print('Error checking restriction: $e');
      return false;
    }
  }

  Future<void> _sendMessage() async {
    if (messageController.text.isEmpty) return;

    // Check for restriction before sending
    bool isRestricted = await _checkUserRestriction();
    if (isRestricted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Your account is currently restricted. Please contact support@ecothreads.com'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
            textColor: Colors.white,
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String messageText = messageController.text;
    String messageDate = DateFormat('EEEE').format(DateTime.now());
    String messageTime =
        DateFormat('h:mm a').format(DateTime.now()); // Removed seconds

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
        final batch = FirebaseFirestore.instance.batch();
        final currentUser = FirebaseAuth.instance.currentUser;

        // Get current user's name
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .get();
        final senderName = userDoc.data()?['fullName'] ?? 'User';

        // Add message to messages collection
        final messageRef = FirebaseFirestore.instance
            .collection('chats')
            .doc(chatIdToUse)
            .collection('messages')
            .doc();

        batch.set(messageRef, {
          'text': messageText,
          'senderId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'date': messageDate,
          'time': messageTime,
          'readBy': [user.uid],
        });

        // Create notification document
        final notificationRef =
            FirebaseFirestore.instance.collection('notifications').doc();

        batch.set(notificationRef, {
          'userId': widget.donorId, // Recipient
          'type': 'new_message',
          'title': senderName, // Just the sender's name
          'message': messageText, // The actual message
          'senderId': user.uid,
          'senderName': senderName,
          'chatId': chatIdToUse,
          'itemId': widget.itemId,
          'itemName': widget.itemName,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'doNotCount':
              true, // Add this flag to exclude from notification count
        });

        // Update chat document
        batch.update(
          FirebaseFirestore.instance.collection('chats').doc(chatIdToUse),
          {
            'lastMessage': messageText,
            'lastMessageTime': FieldValue.serverTimestamp(),
            'lastSenderId': user.uid,
            'hasUnreadMessages': true,
            'unreadCount': FieldValue.increment(1),
            'readBy': [user.uid],
          },
        );

        await batch.commit();

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
          DateFormat('h:mm a').format(DateTime.now()); // Removed seconds

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

  Widget _buildFirebaseMessages() {
    if (widget.chatId == null && _generatedChatId == null) {
      return _buildEmptyState();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading messages'),
          );
        }

        final messages = snapshot.data?.docs ?? [];
        final currentUser = FirebaseAuth.instance.currentUser;

        // Return ListView directly without loading check
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: () {
            if (widget.donorId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DonorProfilePage(
                    donorId: widget.donorId!,
                    donorName: widget.donorName ?? 'Donor',
                  ),
                ),
              );
            }
          },
          child: Row(
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
        ),
        centerTitle: true,
        actions: [
          if (widget.showShippingButton &&
              isDonor &&
              !_isLoadingStatus) // Only show if user is donor
            TextButton.icon(
              icon: Icon(
                Icons.local_shipping,
                color: _hasBeenShipped ? Colors.grey : Colors.blue,
              ),
              label: Text(
                _hasBeenShipped ? 'Shipped' : 'Mark as Shipped',
                style: TextStyle(
                  color: _hasBeenShipped ? Colors.grey : Colors.blue,
                ),
              ),
              onPressed: _hasBeenShipped ? null : () => _markAsShipped(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 5),
          Expanded(
            child: widget.chatId != null || _generatedChatId != null
                ? _buildFirebaseMessages()
                : _buildEmptyState(),
          ),
          const SizedBox(height: 5),
          ChatInputField(
            messageController: messageController,
            onSend: _sendMessage,
            onImagePick: _sendImageMessage,
            isDisabled: false,
          ),
        ],
      ),
    );
  }

  // Add method to check shipping status
  Future<void> _loadShippingStatus() async {
    if (widget.chatId != null) {
      try {
        final chatDoc = await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .get();

        if (mounted && chatDoc.exists) {
          setState(() {
            _hasBeenShipped =
                chatDoc.data()?['donorShippingStatus'] == 'shipped';
            _isLoadingStatus = false;
          });
        }
      } catch (e) {
        print('Error loading shipping status: $e');
      }
    }
  }

  Future<void> _markAsShipped(BuildContext context) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      // Add shipping status message to chat
      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc();

      batch.set(messageRef, {
        'text': 'Item Shipped Successfully!',
        'subtext': 'The item has been shipped and is on its way.',
        'type': 'shipping',
        'senderId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateFormat('EEEE').format(DateTime.now()),
        'time': DateFormat('h:mm:ss a').format(DateTime.now()),
        'details': [
          '• Item: ${widget.itemName}',
        ],
        'readBy': [user.uid],
      });

      // Update item status to sold in donations collection
      final itemRef =
          FirebaseFirestore.instance.collection('donations').doc(widget.itemId);

      batch.update(itemRef, {
        'status': 'sold',
        'soldDate': FieldValue.serverTimestamp(),
      });

      // Create shipping notification for buyer
      final notificationRef =
          FirebaseFirestore.instance.collection('notifications').doc();

      batch.set(notificationRef, {
        'userId': widget.donorId,
        'type': 'item_shipped',
        'title': 'Item Shipped',
        'message': 'Your item "${widget.itemName}" has been shipped!',
        'itemId': widget.itemId,
        'itemName': widget.itemName,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Update chat status
      batch.update(
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId),
        {
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': user.uid,
          'donorShippingStatus': 'shipped',
          'shippingDate': FieldValue.serverTimestamp(),
          'status': 'completed', // Add chat status
        },
      );

      await batch.commit();

      setState(() {
        _hasBeenShipped = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item marked as shipped and sold'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error marking as shipped: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating shipping status'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Widget _buildMessageItem({
    required Map<String, dynamic> messageData,
    required bool isSent,
    required bool showDate,
  }) {
    // Check if this message is only visible to a specific user
    if (messageData['visibleTo'] != null) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || messageData['visibleTo'] != currentUser.uid) {
        return SizedBox.shrink(); // Hide the message for other users
      }
    }

    // Handle systemAction messages (e.g., "Request Confirmed")
    if (messageData['type'] == 'systemAction') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  messageData['text'] ?? '',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (messageData['actionText'] != null) ...[
              SizedBox(height: 8),
              Text(
                messageData['actionText'],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    // Handle shipping messages (e.g., "Item Shipped Successfully")
    if (messageData['type'] == 'shipping') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_shipping, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text(
                  messageData['text'] ?? '',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (messageData['subtext'] != null) ...[
              SizedBox(height: 8),
              Text(
                messageData['subtext'],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (messageData['details'] != null) ...[
              SizedBox(height: 12),
              ...List<Widget>.from(
                (messageData['details'] as List).map(
                  (detail) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      detail,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Regular message handling below
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
            child: Column(
              crossAxisAlignment:
                  isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Message content
                Container(
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
                // Time stamp
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    messageData["time"] ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
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
  final VoidCallback? onSend;
  final VoidCallback? onImagePick;
  final bool isDisabled;

  ChatInputField({
    required this.messageController,
    this.onSend,
    this.onImagePick,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image,
                color: isDisabled ? Colors.grey.shade300 : Colors.grey),
            onPressed: isDisabled ? null : onImagePick,
          ),
          Expanded(
            child: TextField(
              controller: messageController,
              enabled: !isDisabled,
              decoration: InputDecoration(
                hintText: isDisabled
                    ? 'Messaging restricted'
                    : 'Write your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    isDisabled ? Colors.grey.shade100 : Colors.grey.shade100,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: isDisabled ? Colors.grey.shade300 : Colors.black,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send,
                  color: isDisabled ? Colors.grey.shade400 : Colors.white,
                  size: 18),
              onPressed: isDisabled ? null : onSend,
            ),
          ),
        ],
      ),
    );
  }
}
