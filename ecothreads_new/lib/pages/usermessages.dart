import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecothreads/pages/messagedonor.dart';

class UserMessages extends StatelessWidget {
  const UserMessages({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Text(
          'Messages',
          style: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 5),
          Divider(color: Colors.grey, indent: 20.0, endIndent: 20.0),
          SizedBox(height: 20),
          Expanded(
            // If user isn't logged in, show login prompt instead of placeholder
            child: currentUser != null
                ? _buildChatsList(context, currentUser.uid)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Please log in',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'You need to be logged in to view messages',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          child: Text('Go to Login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  // Firebase-connected chat list
  Widget _buildChatsList(BuildContext context, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Check if it's an index error
          if (snapshot.error.toString().contains("requires an index")) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Setting up message system...',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'This may take a few minutes',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Center(child: Text('Error loading messages'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Start a conversation by messaging a donor',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final chatDoc = snapshot.data!.docs[index];
            final chatData = chatDoc.data() as Map<String, dynamic>;

            // Find the other user's ID
            final participants =
                List<String>.from(chatData['participants'] ?? []);
            final otherUserId = participants.firstWhere(
              (id) => id != userId,
              orElse: () => 'unknown',
            );

            // Get unread status and message preview
            final bool hasUnread = chatData['hasUnreadMessages'] ?? false;
            final int unreadCount = (chatData['unreadCount'] ?? 0).toInt();
            final bool isFromOther = (chatData['lastSenderId'] ?? '') != userId;

            // Only show as unread if the last message was from the other person
            final bool showAsUnread = hasUnread && isFromOther;

            // Get message preview - truncate if too long
            String messagePreview = chatData['lastMessage'] ?? '';
            if (messagePreview.length > 30) {
              messagePreview = messagePreview.substring(0, 27) + '...';
            }

            // Format last message time
            String formattedTime = 'Recently';
            if (chatData['lastMessageTime'] != null) {
              final timestamp = chatData['lastMessageTime'] as Timestamp;
              final dateTime = timestamp.toDate();
              final now = DateTime.now();
              final difference = now.difference(dateTime);

              if (difference.inDays > 0) {
                formattedTime = 'seen ${difference.inDays}d ago';
              } else if (difference.inHours > 0) {
                formattedTime = 'seen ${difference.inHours}h ago';
              } else if (difference.inMinutes > 0) {
                formattedTime = 'seen ${difference.inMinutes}m ago';
              } else {
                formattedTime = 'just now';
              }
            }

            // Fetch the other user's information
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .get(),
              builder: (context, userSnapshot) {
                // Default values if user info not found
                String userName = 'User';
                String? imagePath;

                if (userSnapshot.hasData && userSnapshot.data != null) {
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  if (userData != null) {
                    userName =
                        userData['fullName'] ?? userData['name'] ?? 'User';
                    imagePath = userData['profileImageUrl'];
                  }
                }

                return buildMessageItem(
                  context,
                  chatId: chatDoc.id,
                  donorId: otherUserId,
                  userName: userName,
                  userTitle: messagePreview,
                  seenTime: formattedTime,
                  imagePath: imagePath ?? '',
                  itemName: chatData['itemName'] ?? 'Item',
                  hasUnread: showAsUnread,
                  unreadCount: unreadCount,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget buildMessageItem(
    BuildContext context, {
    required String chatId,
    required String donorId,
    required String userName,
    required String userTitle,
    required String seenTime,
    required String imagePath,
    required String itemName,
    bool hasUnread = false,
    int unreadCount = 0,
  }) {
    // Check if the image is a network URL or an asset
    final bool isNetworkImage = imagePath.startsWith('http');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageDonor(
              chatId: chatId,
              donorId: donorId,
              donorName: userName,
              itemName: itemName,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        // Highlight background if unread
        color: hasUnread
            ? const Color.fromARGB(255, 41, 40, 40).withOpacity(0.1)
            : Colors.transparent,
        child: Row(
          children: [
            // Profile pic with optional unread badge
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: isNetworkImage && imagePath.isNotEmpty
                      ? NetworkImage(imagePath) as ImageProvider
                      : null,
                  child: isNetworkImage && imagePath.isNotEmpty
                      ? null // Don't show icon if we have a valid network image
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.grey.shade600,
                        ),
                ),
                // Show unread badge if message is unread
                if (hasUnread && unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 16),
            // Message preview with sender name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          hasUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    userTitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: hasUnread ? Colors.black87 : Colors.grey,
                      fontWeight:
                          hasUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Time and read status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  seenTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: hasUnread ? Colors.black87 : Colors.grey[400],
                    fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(hasUnread ? Icons.circle : Icons.check,
                        size: 14,
                        color: hasUnread ? Color(0xFF16A637) : Colors.grey),
                    if (!hasUnread)
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
