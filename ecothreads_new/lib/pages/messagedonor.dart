import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageDonor extends StatefulWidget {
  // Add parameters to MessageDonor
  final String? chatId;
  final String? donorId;
  final String? donorName;
  final String? itemName;

  // Make parameters optional to maintain backward compatibility
  const MessageDonor({
    Key? key,
    this.chatId,
    this.donorId,
    this.donorName,
    this.itemName,
  }) : super(key: key);

  @override
  State<MessageDonor> createState() => _MessageDonorState();
}

class _MessageDonorState extends State<MessageDonor> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // For local messages when chatId is not provided
  final List<Map<String, dynamic>> localMessages = [];

  // Firebase messages stream
  Stream<QuerySnapshot>? _messagesStream;

  @override
  void initState() {
    super.initState();

    // Initialize Firebase message stream if chatId is provided
    if (widget.chatId != null) {
      _messagesStream = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots();

      // Mark chat as read when opened
      _markChatAsRead();
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
        final List<String> readBy =
            List<String>.from(messageData['readBy'] ?? []);

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
    String messageText = messageController.text;
    String messageDate = DateFormat('EEEE').format(DateTime.now());
    String messageTime = DateFormat('hh:mm a').format(DateTime.now());

    // If we have a chatId and user is logged in, use Firebase
    if (widget.chatId != null && user != null) {
      try {
        // Get the other user's ID
        final otherUserId = widget.donorId;

        // Add message to Firestore
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .add({
          'text': messageText,
          'senderId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'date': messageDate,
          'time': messageTime,
          'readBy': [user.uid], // Mark as read by sender only
        });

        // Update last message in chat document
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .update({
          'lastMessage': messageText,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': user.uid,
          'hasUnreadMessages': true,
          'unreadCount': FieldValue.increment(1),
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
      // Use local state for compatibility with original code
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

  void _sendVoiceNote() {
    String messageDate = DateFormat('EEEE').format(DateTime.now());
    String messageTime = DateFormat('hh:mm a').format(DateTime.now());

    setState(() {
      localMessages.add({
        "text": "Voice Note",
        "date": messageDate,
        "time": messageTime,
        "isSent": true,
      });
    });
  }

  void _uploadImage() {
    String messageDate = DateFormat('EEEE').format(DateTime.now());
    String messageTime = DateFormat('hh:mm a').format(DateTime.now());

    setState(() {
      localMessages.add({
        "text": "Image Uploaded",
        "date": messageDate,
        "time": messageTime,
        "isSent": true,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Colors.black,
            ),
          ),
        ),
        title: Column(
          children: [
            Text(
              widget.donorName ?? 'Messages',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            if (widget.itemName != null)
              Text(
                'Item: ${widget.itemName}',
                style: TextStyle(color: Colors.grey, fontSize: 12),
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
            child: widget.chatId != null
                ? _buildFirebaseMessages()
                : _buildLocalMessages(),
          ),
          const SizedBox(height: 5),
          ChatInputField(
            messageController: messageController,
            onSend: _sendMessage,
            onVoice: _sendVoiceNote,
            onUpload: _uploadImage,
          ),
        ],
      ),
    );
  }

  // Display Firebase messages
  Widget _buildFirebaseMessages() {
    return StreamBuilder<QuerySnapshot>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No messages yet. Say hello!'));
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
              message: messageData,
              isSent: isSent,
              showDate: showDate,
            );
          },
        );
      },
    );
  }

  // Display local messages (compatibility with original code)
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
          message: message,
          isSent: isSent,
          showDate: showDate,
        );
      },
    );
  }

  // Common message item widget
  Widget _buildMessageItem({
    required Map<String, dynamic> message,
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
              child: Text(
                message["date"] ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(top: 4.0),
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: isSent ? Colors.black : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message["text"] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: isSent ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message["time"] ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSent
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatInputField extends StatelessWidget {
  final TextEditingController messageController;
  final VoidCallback onSend;
  final VoidCallback onVoice;
  final VoidCallback onUpload;

  ChatInputField({
    required this.messageController,
    required this.onSend,
    required this.onVoice,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
      child: Row(
        children: [
          // TextField for message input
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'Write your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
          ),
          // Voice Note Icon
          IconButton(
            icon: Icon(Icons.mic),
            onPressed: onVoice,
          ),
          // Popup Menu for Image Upload
          PopupMenuButton(
            icon: Icon(Icons.image),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                child: Text("Upload Image"),
                value: "upload",
              ),
            ],
            onSelected: (value) {
              if (value == "upload") {
                onUpload();
              }
            },
          ),
          // Send Button
          IconButton(
            icon: Icon(Icons.send),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
