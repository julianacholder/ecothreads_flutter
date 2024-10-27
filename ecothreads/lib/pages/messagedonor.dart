import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importing intl package for date formatting

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
  final List<Map<String, dynamic>> messages = []; // Changed to dynamic to support voice messages

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
          "isSent": true, // Mark the message as sent
        });
      });
      messageController.clear();
    }
  }

  void _sendVoiceNote() {
    // Placeholder for voice note functionality
    String messageDate = DateFormat('EEEE').format(DateTime.now());
    String messageTime = DateFormat('hh:mm a').format(DateTime.now());

    setState(() {
      messages.add({
        "text": "Voice Note", // Placeholder text for the voice note
        "date": messageDate,
        "time": messageTime,
        "isSent": true,
      });
    });
  }

  void _uploadImage() {
    // Handle image upload here
    // This is a placeholder for image upload functionality
    String messageDate = DateFormat('EEEE').format(DateTime.now());
    String messageTime = DateFormat('hh:mm a').format(DateTime.now());

    setState(() {
      messages.add({
        "text": "Image Uploaded", // Placeholder text for the image upload
        "date": messageDate,
        "time": messageTime,
        "isSent": true,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          padding: EdgeInsets.all(6), // Add padding around the icon
          decoration: BoxDecoration(
            color: Colors.grey, // Set the background color to grey
            shape: BoxShape.circle, // Make it circular
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white), // Icon with white color for contrast
            onPressed: () {
              Navigator.pop(context); // Navigate back on button press
            },
          ),
        ),
        title: Center(child: Text('Messages')), // Centered title
      ),
      body: Column(
        children: [
          // Top Separator Line
          Container(
            height: 2, // Adjust height as needed
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
          SizedBox(height: 5), // Add some spacing below the AppBar
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                bool isSent = message["isSent"];

                // Check if it's the first message of the day or from a new sender
                bool showDate = false;
                if (index == 0 || message["date"] != messages[index - 1]["date"] || messages[index - 1]["isSent"] != isSent) {
                  showDate = true;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (showDate)
                        Center(
                          child: Text(
                            message["date"]!,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      Container(
                        margin: EdgeInsets.only(top: 4.0),
                        padding: EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: isSent ? Colors.black : Colors.grey[300], // Change color to black for sent messages
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message["text"]!,
                              style: TextStyle(fontSize: 16, color: isSent ? Colors.white : Colors.black), // Change text color to white for readability
                            ),
                            SizedBox(height: 4),
                            // Display the time below the message text
                            Text(
                              message["time"]!,
                              style: TextStyle(fontSize: 10, color: Colors.grey),
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
          SizedBox(height: 5), // Add some spacing above the input field
          ChatInputField(
            messageController: messageController,
            onSend: _sendMessage,
            onVoice: _sendVoiceNote, // Pass the voice note function
            onUpload: _uploadImage, // Pass the upload function
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
