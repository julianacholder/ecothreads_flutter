import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'messaging_service.dart';

// Enum defined outside the class to ensure it's accessible
enum NotificationType { systemNotification, firebasePush, both }

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static Stream<QuerySnapshot>? _notificationStream;
  static bool _isInitialized = false;

  // Initialize both Firebase notifications listening and local notifications
  static Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Request notification permissions and get token
    await MessagingService.initialize();
    final fcmToken = await MessagingService.messaging.getToken();

    // Save FCM token to user's document
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && fcmToken != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'fcmToken': fcmToken});
    }

    // Request notification permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get the token for this device
      String? token = await _firebaseMessaging.getToken();
      print('Firebase Messaging Token: $token');

      // Configure foreground message handling
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(context, message);
      });
    }

    // Initialize local notifications
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotificationsPlugin.initialize(initializationSettings);

    // Initialize Firebase notification listening using the existing currentUser
    if (currentUser != null) {
      _notificationStream = FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .snapshots();

      _notificationStream?.listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final notification = change.doc.data() as Map<String, dynamic>;

            if (notification['type'] == 'restriction') {
              _showRestrictionDialog(context, notification, change.doc.id);
            } else if (notification['type'] == 'item_request') {
              // Assuming item request notifications should use both methods
              showLocalNotification(
                title: notification['title'] ?? 'Item Request',
                body: notification['body'] ?? 'You have a new item request',
                notificationType: NotificationType.both,
              );
            }
          }
        }
      });
    }
  }

  // Handle foreground messages
  static void _handleForegroundMessage(
      BuildContext context, RemoteMessage message) {
    if (message.notification != null) {
      showLocalNotification(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        notificationType: NotificationType.systemNotification,
      );
    }
  }

  // Show local notification or Firebase push notification
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    NotificationType notificationType = NotificationType.systemNotification,
  }) async {
    // System Notification (Mobile Notification Tray)
    if (notificationType == NotificationType.systemNotification ||
        notificationType == NotificationType.both) {
      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'item_requests',
          'Item Requests',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotificationsPlugin.show(
        DateTime.now().millisecond,
        title,
        body,
        notificationDetails,
      );
    }

    // Firebase Push Notification
    if (notificationType == NotificationType.firebasePush ||
        notificationType == NotificationType.both) {
      final token = await MessagingService.messaging.getToken();
      if (token != null) {
        await MessagingService.sendPushMessage(
          token: token,
          title: title,
          body: body,
          data: {'type': 'notification'},
        );
      }
    }
  }

  // Get device token to send to your backend
  static Future<String?> getDeviceToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Show restriction dialog
  static void _showRestrictionDialog(BuildContext context,
      Map<String, dynamic> notification, String notificationId) {
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
                notification['message'] ?? 'Your account has been restricted.'),
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
