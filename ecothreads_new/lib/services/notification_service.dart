import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'messaging_service.dart';

enum NotificationType { systemNotification, firebasePush, both }

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static Stream<QuerySnapshot>? _notificationStream;
  static bool _isInitialized = false;

  // Deduplication tracking
  static final Set<String> _processedNotificationIds = {};
  static final Set<String> _processedDedupeIds = {};

  // Initialize the notification service
  static Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Load previously processed notifications
    await _loadProcessedNotifications();

    // Initialize messaging and get token
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
      // Configure foreground message handling with deduplication
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(context, message);
      });

      // Handle background/terminated messages
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleForegroundMessage(context, message);
      });
    }

    // Initialize local notifications
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Initialize Firestore notification stream with deduplication
    if (currentUser != null) {
      _notificationStream = FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('timestamp', descending: true)
          .snapshots();

      _notificationStream?.listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final notification = change.doc.data() as Map<String, dynamic>;
            final notificationId = change.doc.id;
            final dedupeId = notification['dedupeId'] ?? notificationId;

            // Skip if already processed
            if (_processedNotificationIds.contains(notificationId) ||
                _processedDedupeIds.contains(dedupeId)) {
              continue;
            }

            // Mark as processed
            _processedNotificationIds.add(notificationId);
            _processedDedupeIds.add(dedupeId);
            _saveProcessedNotification(notificationId, dedupeId);

            // Handle specific notification types
            if (notification['type'] == 'restriction') {
              _showRestrictionDialog(context, notification, notificationId);
            } else {
              showLocalNotification(
                id: dedupeId.hashCode, // Use hash of dedupeId for stable ID
                title: notification['title'] ?? 'Notification',
                body: notification['message'] ?? '',
                payload: notificationId,
                notificationType: NotificationType.both,
              );
            }
          }
        }
      });
    }
  }

  // Load previously processed notifications from cache
  static Future<void> _loadProcessedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationIds =
        prefs.getStringList('processed_notification_ids') ?? [];
    final dedupeIds = prefs.getStringList('processed_dedupe_ids') ?? [];

    _processedNotificationIds.addAll(notificationIds);
    _processedDedupeIds.addAll(dedupeIds);

    // Clean up old entries if too many
    if (_processedNotificationIds.length > 100) {
      _processedNotificationIds.clear();
      _processedDedupeIds.clear();
      await prefs.remove('processed_notification_ids');
      await prefs.remove('processed_dedupe_ids');
    }
  }

  // Save processed notifications to cache
  static Future<void> _saveProcessedNotification(
      String notificationId, String dedupeId) async {
    _processedNotificationIds.add(notificationId);
    _processedDedupeIds.add(dedupeId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'processed_notification_ids',
      _processedNotificationIds.toList(),
    );
    await prefs.setStringList(
      'processed_dedupe_ids',
      _processedDedupeIds.toList(),
    );
  }

  // Handle foreground messages with deduplication
  static void _handleForegroundMessage(
      BuildContext context, RemoteMessage message) {
    final notificationId = message.data['originalNotificationId'] ?? '';
    final dedupeId = message.data['dedupeId'] ?? notificationId;

    // Skip if already processed
    if (_processedNotificationIds.contains(notificationId) ||
        _processedDedupeIds.contains(dedupeId)) {
      return;
    }

    // Mark as processed
    _processedNotificationIds.add(notificationId);
    _processedDedupeIds.add(dedupeId);
    _saveProcessedNotification(notificationId, dedupeId);

    // Show notification
    showLocalNotification(
      id: dedupeId.hashCode,
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      payload: notificationId,
      notificationType: NotificationType.systemNotification,
    );
  }

  // Show local notification with deduplication
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationType notificationType = NotificationType.systemNotification,
  }) async {
    if (notificationType != NotificationType.firebasePush) {
      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'item_requests',
          'Item Requests',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          channelShowBadge: true,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotificationsPlugin.show(
        id, // Use stable ID based on dedupeId
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    }
  }

  // Restriction dialog remains the same
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
    _notificationStream = null;
  }
}
