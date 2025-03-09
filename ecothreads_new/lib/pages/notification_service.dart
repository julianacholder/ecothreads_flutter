import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static Stream<QuerySnapshot>? _notificationStream;
  static bool _isInitialized = false;

  static void initialize(BuildContext context) {
    if (_isInitialized) return;
    _isInitialized = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _notificationStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots();

    _notificationStream?.listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final notification = change.doc.data() as Map<String, dynamic>;

          if (notification['type'] == 'restriction') {
            _showRestrictionDialog(context, notification, change.doc.id);
          }
        }
      }
    });
  }

  static void _showRestrictionDialog(
    BuildContext context,
    Map<String, dynamic> notification,
    String notificationId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Account Restricted'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['message'] ?? 'Your account has been restricted.',
            ),
            SizedBox(height: 16),
            Text(
              'To appeal this restriction, please contact:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('support@ecothreads.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Mark notification as read
              await FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(notificationId)
                  .update({'isRead': true});
              Navigator.pop(context);
            },
            child: Text('I Understand'),
          ),
        ],
      ),
    );
  }

  static void dispose() {
    _isInitialized = false;
  }
}
