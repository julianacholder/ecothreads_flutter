import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importing intl package for date formatting

class MessageDonor extends StatefulWidget {
  const MessageDonor({super.key});

  @override
  State<MessageDonor> createState() => _MessageDonorState();
}

class _MessageDonorState extends State<MessageDonor> {
  final TextEditingController messageController = TextEditingController();
  final List<Map<String, dynamic>> messages = [];

  void _sendMessage() {
    if (messageController.text.isNotEmpty) {
      String messageText = messageController.text;
      String messageDate = DateFormat('EEEE').format(DateTime.now());
      String messageTime = DateFormat('hh:mm a').format(DateTime.now());

      setState(() {
        messages.add({
          "text": messageText,
          "date": messageDate,
          "time": messageTime,
          "isSent": true,
        });
      });
      messageController.clear();
    }
  }

  void _sendVoiceNote() {
    String messageDate = DateFormat('EEEE').format(DateTime.now());
    String messageTime = DateFormat('hh:mm a').format(DateTime.now());

    setState(() {
      messages.add({
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
      messages.add({
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
      backgroundColor: Colors.white, // Add this
      appBar: AppBar(
        backgroundColor: Colors.white, // Add this
        elevation: 0, // Add this
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
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black), // Add this
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
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                bool isSent = message["isSent"];
                bool showDate = false;
                if (index == 0 ||
                    message["date"] != messages[index - 1]["date"] ||
                    messages[index - 1]["isSent"] != isSent) {
                  showDate = true;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: isSent
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (showDate)
                        Center(
                          child: Text(
                            message["date"]!,
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
                              message["text"]!,
                              style: TextStyle(
                                fontSize: 16,
                                color: isSent ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message["time"]!,
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
              },
            ),
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
}

class ChatInputField extends StatelessWidget {
  final TextEditingController messageController;
  final VoidCallback onSend;
  final VoidCallback onVoice; // Add a callback for voice notes
  final VoidCallback onUpload; // Add a callback for upload images

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
            onPressed: onVoice, // Call the voice note function
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
                onUpload(); // Call the upload function
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
