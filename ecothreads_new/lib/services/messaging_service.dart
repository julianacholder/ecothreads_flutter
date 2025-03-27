import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MessagingService {
  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  static String? token;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request permission
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    token = await messaging.getToken();
    print('FCM Token: $token');

    // Create separate channels for messages and other notifications
    const androidMessageChannel = AndroidNotificationChannel(
      'messages', // channel ID
      'Messages', // channel name
      description: 'Chat messages', // channel description
      importance: Importance.high,
      showBadge: true,
    );

    const androidNotificationChannel = AndroidNotificationChannel(
      'notifications',
      'Notifications',
      description: 'General notifications',
      importance: Importance.high,
      showBadge: true,
    );

    // Create the channels
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidMessageChannel);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);

    // Initialize local notifications
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        print('Notification tapped: ${details.payload}');
      },
    );

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Handle notification open events
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationOpen(message);
    });
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
    // Handle background message
  }

  static void _handleForegroundMessage(RemoteMessage message) async {
    // Skip creating notification document for messages
    if (message.data['type'] == 'new_message') {
      // Only show local notification
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'messages', // Use messages channel
              'Messages',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: message.data.toString(),
        );
      }
      return;
    }

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  static void _handleNotificationOpen(RemoteMessage message) {
    // Handle notification tap
    print('Notification tapped: ${message.messageId}');
    // Add navigation logic here
  }

  static Future<void> sendPushMessage({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // This would typically be done from your backend
    // For testing, you can use Firebase Cloud Functions or your server
    print('Would send message to token: $token');
    print('Title: $title');
    print('Body: $body');
    print('Data: $data');
  }
}
