import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importing intl package for date formatting
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(Messagedonor());
}

class Messagedonor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();

  // Fetch messages as a real-time stream
  Stream<List<Map<String, dynamic>>> fetchMessages(String chatId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                "text": data['text'],
                "time": DateFormat('hh:mm a').format(data['timestamp'].toDate()),
                "date": DateFormat('EEEE').format(data['timestamp'].toDate()),
                "isSent": data['senderId'] ==
                    FirebaseAuth.instance.currentUser!.uid,
              };
            }).toList());
  }

  // Send a message to Firestore
  Future<void> sendMessage(String chatId, String text) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _sendMessage() {
    if (messageController.text.isNotEmpty) {
      final chatId = "user1_user2"; // Replace with dynamic chatId if needed
      sendMessage(chatId, messageController.text);
      messageController.clear();
    }
  }

  void _sendVoiceNote() {
    // Placeholder for voice note functionality
    print("Voice note functionality triggered.");
  }

  void _uploadImage() {
    // Placeholder for image upload functionality
    print("Image upload functionality triggered.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
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
        title: const Center(child: Text('Messages')), // Centered title
      ),
      body: Column(
        children: [
          // Top Separator Line
          Container(
            height: 2,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5), // Spacing below the AppBar

          // Chat Messages Section
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: fetchMessages('user1_user2'), // user
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isSent = message["isSent"];

                    // Check if it's the first message of the day or from a new sender
                    final bool showDate = index == 0 ||
                        message["date"] != messages[index - 1]["date"];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: isSent
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (showDate)
                            Center(
                              child: Text(
                                message["date"]!,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
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
                                  message["text"]!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSent
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message["time"]!,
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Chat Input Field
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
}

class ChatInputField extends StatelessWidget {
  final TextEditingController messageController;
  final VoidCallback onSend;
  final VoidCallback onVoice; // Callback for voice notes
  final VoidCallback onUpload; // Callback for image upload

  ChatInputField({
    required this.messageController,
    required this.onSend,
    required this.onVoice,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Text Field for Message Input
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
          // Voice Note Button
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: onVoice,
          ),
          // Image Upload Button
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: onUpload,
          ),
          // Send Button
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
