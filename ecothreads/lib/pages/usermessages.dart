import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UserMessages(),
    );
  }
}

class UserMessages extends StatelessWidget {
  const UserMessages({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 16, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Text(
          'Messages',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 10), 
          Divider(color: Colors.grey, indent: 45.0, endIndent: 45.0),
          SizedBox(height: 20), 
          Expanded(
            child: ListView(
              children: [
                buildMessageItem(
                  context,
                  userName: 'Cory Koss',
                  userTitle: 'Designer',
                  seenTime: 'seen 7:48pm',
                  imagePath: 'assets/images/Corry.png',
                ),
                buildMessageItem(
                  context,
                  userName: 'Miss Donald Boyar',
                  userTitle: 'Saving bypassing Wisconsin',
                  seenTime: 'seen 3:00pm',
                  imagePath: 'assets/images/Miss.png',
                ),
                buildMessageItem(
                  context,
                  userName: 'Elsa Pouros V',
                  userTitle: 'Manager Chips',
                  seenTime: 'seen 12:22am',
                  imagePath: 'assets/images/Elsa.png',
                ),
                buildMessageItem(
                  context,
                  userName: 'Christian Marks',
                  userTitle: 'Generating',
                  seenTime: 'seen 5:45pm',
                  imagePath: 'assets/images/Christian.png',
                ),
                buildMessageItem(
                  context,
                  userName: 'Mabel Kovacek DDS',
                  userTitle: 'Buckinghamshire focus',
                  seenTime: 'seen 1:30pm',
                  imagePath: 'assets/images/Mabel.png',
                ),
                buildMessageItem(
                  context,
                  userName: 'Mariam Douglas',
                  userTitle: 'Corporate Manager',
                  seenTime: 'seen 8:59am',
                  imagePath: 'assets/images/Mariam.png',
                ),
                buildMessageItem(
                  context,
                  userName: 'Juana Vandervort',
                  userTitle: 'Blue Sticky Granite',
                  seenTime: 'seen 11:00pm',
                  imagePath: 'assets/images/Juana.png',
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget buildMessageItem(
    BuildContext context, {
    required String userName,
    required String userTitle,
    required String seenTime,
    required String imagePath,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(userName: userName, userTitle: userTitle),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage(imagePath),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  userTitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  seenTime,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
                Row(
                  children: [
                    Icon(Icons.check, size: 14, color: Colors.grey),
                    Icon(Icons.check, size: 14, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatPage extends StatelessWidget {
  final String userName;
  final String userTitle;

  ChatPage({required this.userName, required this.userTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Chat with $userName - $userTitle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Container(),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    // functionality
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
