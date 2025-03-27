import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecothreads/pages/messagedonor.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shimmer/shimmer.dart';
import 'donor_profile_page.dart';

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
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(
                  context, '/main'); // Go to Home if at root
            }
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
          return _buildLoadingList();
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

        // Filter out chats that the current user has deleted
        // Also filter out empty chats with just "Chat started" message
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Check if the chat is deleted for this user
          final List<dynamic> deletedFor = data['deletedFor'] ?? [];
          if (deletedFor.contains(userId)) {
            return false; // Skip chats this user has deleted
          }

          // Check if this is an empty chat with just "Chat started"
          final String lastMessage = data['lastMessage'] ?? '';
          final bool hasRealMessages = lastMessage != 'Chat started';

          // Only include chats with actual messages
          return hasRealMessages;
        }).toList();

        if (filteredDocs.isEmpty) {
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
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final chatDoc = filteredDocs[index];
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
            final List<dynamic> readBy = chatData['readBy'] ?? [];

            // Only show as unread if the last message was from the other person
            final bool showAsUnread = hasUnread && isFromOther;

            // Get message preview - truncate if too long
            String messagePreview = chatData['lastMessage'] ?? '';
            if (messagePreview.length > 30) {
              messagePreview = messagePreview.substring(0, 27) + '...';
            }

            // Format last message time and status (relative time)
            String formattedTime = 'Recently';
            String statusText = '';

            if (chatData['lastMessageTime'] != null) {
              final timestamp = chatData['lastMessageTime'] as Timestamp;
              final dateTime = timestamp.toDate();
              final now = DateTime.now();

              // Calculate time difference
              final difference = now.difference(dateTime);

              // Format time relatively based on the time difference
              if (difference.inSeconds < 60) {
                formattedTime = '${difference.inSeconds}s';
              } else if (difference.inMinutes < 60) {
                formattedTime = '${difference.inMinutes}m';
              } else if (difference.inHours < 24) {
                formattedTime = '${difference.inHours}h';
              } else {
                formattedTime = '${difference.inDays}d';
              }

              // Determine status text
              if (!isFromOther) {
                if (readBy.contains(otherUserId)) {
                  statusText = "Seen $formattedTime";
                } else {
                  statusText = "Sent $formattedTime";
                }
              } else {
                statusText = formattedTime;
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
                    imagePath = userData['profileImageUrl'] ??
                        userData['profileImage'] ??
                        userData['userProfileImage'] ??
                        userData['photoURL'] ??
                        userData['avatar'];
                  }
                }

                return buildMessageItem(
                  context,
                  chatId: chatDoc.id,
                  donorId: otherUserId,
                  userName: userName,
                  userTitle: messagePreview,
                  statusText: statusText,
                  imagePath: imagePath ?? '',
                  itemName: chatData['itemName'] ?? 'Item',
                  hasUnread: showAsUnread,
                  unreadCount: unreadCount,
                  userId: userId,
                  itemImage: chatData['itemImage'],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
            ),
            title: Container(
              height: 16,
              width: double.infinity,
              color: Colors.white,
            ),
            subtitle: Container(
              height: 12,
              width: 100,
              margin: EdgeInsets.only(top: 4),
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  // Delete chat for the current user only
  Future<void> _deleteChat(
      BuildContext context, String chatId, String userId) async {
    // Show confirmation dialog
    bool confirmDelete = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Conversation'),
            content: Text('Are you sure you want to delete this conversation?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmDelete) return;

    try {
      // Get a reference to the chat document
      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(chatId);

      // Get the current chat data
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) {
        // Chat doesn't exist, nothing to delete
        return;
      }

      final chatData = chatDoc.data() as Map<String, dynamic>;

      // Add or update the deletedFor array with the current user's ID
      List<dynamic> deletedFor = chatData['deletedFor'] ?? [];
      if (!deletedFor.contains(userId)) {
        deletedFor.add(userId);
      }

      // Update the chat document with the updated deletedFor array
      await chatRef.update({'deletedFor': deletedFor});

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversation deleted from your messages')),
      );
    } catch (e) {
      print('Error deleting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting conversation')),
      );
    }
  }

  // In your buildMessageItem method in UserMessages class:

  Widget buildMessageItem(
    BuildContext context, {
    required String chatId,
    required String donorId,
    required String userName,
    required String userTitle,
    required String statusText,
    required String imagePath,
    required String itemName,
    required String userId,
    String? itemImage,
    bool hasUnread = false,
    int unreadCount = 0,
  }) {
    // Check if the image is a network URL or an asset
    final bool isNetworkImage = imagePath.startsWith('http');
    final bool hasItemImage = itemImage != null && itemImage.isNotEmpty;

    return Slidable(
      key: Key(chatId),
      endActionPane: ActionPane(
        motion: ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) {
              _deleteChat(context, chatId, userId);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessageDonor(
                chatId: chatId,
                donorId: donorId,
                donorName: userName,
                itemName: itemName != 'Item' ? itemName : null,
                itemImage: itemImage,
                // Add this parameter to show the shipping button
                showShippingButton: true,
              ),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          color: hasUnread
              ? const Color.fromARGB(255, 41, 40, 40).withOpacity(0.1)
              : Colors.transparent,
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: hasItemImage
                        ? NetworkImage(itemImage!) as ImageProvider
                        : (isNetworkImage && imagePath.isNotEmpty
                            ? NetworkImage(imagePath) as ImageProvider
                            : null),
                    child: (!hasItemImage &&
                            (!isNetworkImage || imagePath.isEmpty))
                        ? Icon(
                            Icons.checkroom,
                            size: 30,
                            color: Colors.grey.shade600,
                          )
                        : null,
                  ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName != 'Item' ? '$userName • $itemName' : userName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            hasUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusText.startsWith('Seen')
                          ? Colors.blue
                          : Colors.grey[600],
                      fontWeight: statusText.startsWith('Seen')
                          ? FontWeight.w500
                          : FontWeight.normal,
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
      ),
    );
  }
}
