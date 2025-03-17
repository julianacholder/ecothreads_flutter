import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/notification_service.dart';
import 'messagedonor.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _notificationsStream;
  bool _isInitialized = false;
  bool isSubmitting = false; // Add this line at the class level

  @override
  void initState() {
    super.initState();
    _initializeNotificationsStream();
  }

  void _initializeNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _notificationsStream = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title placeholder
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Message placeholder
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Time placeholder
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Image placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _buildShimmerLoading(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll notify you when something arrives',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final notification = {
                ...doc.data() as Map<String, dynamic>,
                'notificationId':
                    doc.id, // Add document ID to the notification map
              };

              // Update read status if needed
              if (notification['isRead'] == false) {
                doc.reference.update({'isRead': true});
              }

              return NotificationTile(
                type: notification['type'] ?? 'info',
                title: notification['title'] ?? '',
                message: notification['message'] ?? '',
                timestamp: notification['timestamp'] as Timestamp?,
                imageUrl: notification['imageUrl'],
                itemImage: notification['itemImage'],
                isRead: notification['isRead'] ?? false,
                onTap: () => _handleNotificationTap(context, notification),
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(
      BuildContext context, Map<String, dynamic> notification) {
    switch (notification['type']) {
      case 'item_request':
        if (notification['isFirstView'] != false) {
          // First view - show action dialog
          _showRequestActionDialog(context, notification);
          // Mark as viewed for future
          FirebaseFirestore.instance
              .collection('notifications')
              .doc(notification['notificationId'])
              .update({'isFirstView': false});
        } else {
          // Subsequent views - just open the chat
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            final chatId =
                '${notification['buyerId']}_${currentUser.uid}_${notification['itemId']}';

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MessageDonor(
                  chatId: chatId,
                  donorId: notification['buyerId'],
                  donorName: notification['buyerName'] ?? 'Buyer',
                  itemName: notification['itemName'],
                  itemId: notification['itemId'],
                  itemImage: notification['imageUrl'],
                  showShippingButton: true,
                ),
              ),
            );
          }
        }
        break;
      // ...existing cases...
    }
  }

  void _showRequestActionDialog(
      BuildContext context, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_bag_outlined, color: Colors.blue),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'New Item Request',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What would you like to do with this request?'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () =>
                        _showDenyReasonDialog(context, notification),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Deny'),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _confirmRequest(context, notification),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Confirm',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDenyReasonDialog(
      BuildContext context, Map<String, dynamic> notification) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Deny Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please provide a reason for denying this request:'),
              SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: 'Enter reason',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isSubmitting ? null : () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: isSubmitting
                  ? null
                  : () {
                      setDialogState(() => isSubmitting = true);
                      _processDenyRequest(
                        context,
                        notification,
                        reasonController.text,
                        setDialogState,
                      );
                    },
              child: isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Submit',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processDenyRequest(
    BuildContext context,
    Map<String, dynamic> notification,
    String reason,
    StateSetter setState,
  ) async {
    if (reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a reason')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Get points from donation document
      final donationDoc = await FirebaseFirestore.instance
          .collection('donations')
          .doc(notification['itemId'])
          .get();

      final itemPoints = donationDoc.data()?['points'] ?? 0;

      // Refund points to buyer
      final buyerRef = FirebaseFirestore.instance
          .collection('users')
          .doc(notification['buyerId']);

      batch.update(buyerRef, {
        'points': FieldValue.increment(itemPoints),
      });

      // Create denial notification
      final denialNotificationRef =
          FirebaseFirestore.instance.collection('notifications').doc();

      batch.set(denialNotificationRef, {
        'userId': notification['buyerId'],
        'type': 'request_denied',
        'title': 'Request Denied',
        'message': 'Your request has been denied. Reason: $reason',
        'itemId': notification['itemId'],
        'itemName': notification['itemName'],
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Create points refund notification
      final refundNotificationRef =
          FirebaseFirestore.instance.collection('notifications').doc();

      batch.set(refundNotificationRef, {
        'userId': notification['buyerId'],
        'type': 'points_refunded',
        'title': 'Points Refunded',
        'message': '${itemPoints} points have been refunded to your account',
        'itemId': notification['itemId'],
        'itemName': notification['itemName'],
        'pointsAmount': itemPoints,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Update item status back to available
      final itemRef = FirebaseFirestore.instance
          .collection('donations')
          .doc(notification['itemId']);

      batch.update(itemRef, {'status': 'available'});

      await batch.commit();

      Navigator.of(context).pop(); // Close deny reason dialog
      Navigator.of(context).pop(); // Close action dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request denied'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error processing denial: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing denial'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmRequest(
      BuildContext context, Map<String, dynamic> notification) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) return;

      // Generate chat ID
      final chatId =
          '${notification['buyerId']}_${currentUser.uid}_${notification['itemId']}';

      // Create system message in chat
      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages');

      // Add the confirmation message (visible only to the donor)
      batch.set(messageRef.doc(), {
        'text': 'Request Confirmed',
        'actionText':
            'Once you have shipped the item, click "Mark as Shipped" to notify the buyer.',
        'type': 'systemAction', // Set the message type to 'systemAction'
        'timestamp': FieldValue.serverTimestamp(),
        'isShippingAction': true,
        'isSystemMessage': true,
        'visibleTo': currentUser.uid, // Only visible to the donor
      });

      // Create confirmation notification for buyer
      final confirmNotificationRef =
          FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(confirmNotificationRef, {
        'userId': notification['buyerId'],
        'type': 'request_confirmed',
        'title': 'Request Confirmed',
        'message':
            'Your request for "${notification['itemName']}" has been confirmed!',
        'itemId': notification['itemId'],
        'itemName': notification['itemName'],
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await batch.commit();

      // Close any open dialogs before navigation
      Navigator.of(context).popUntil((route) => route.isFirst);

      // Navigate to MessageDonor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessageDonor(
            chatId: chatId,
            donorId: notification['buyerId'],
            donorName: notification['buyerName'] ?? 'Buyer',
            itemName: notification['itemName'],
            itemId: notification['itemId'],
            itemImage: notification['imageUrl'],
            showShippingButton: true,
          ),
        ),
      );
    } catch (e) {
      print('Error confirming request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming request')),
      );
    }
  }
}

class NotificationTile extends StatelessWidget {
  final String type;
  final String title;
  final String message;
  final Timestamp? timestamp;
  final String? imageUrl; // User profile image
  final String? itemImage; // Item image
  final bool isRead;
  final VoidCallback onTap;

  const NotificationTile({
    Key? key,
    required this.type,
    required this.title,
    required this.message,
    this.timestamp,
    this.imageUrl,
    this.itemImage,
    required this.isRead,
    required this.onTap,
  }) : super(key: key);

  IconData _getIcon() {
    switch (type) {
      case 'item_request':
        return Icons.shopping_bag_outlined;
      case 'request_confirmed':
        return Icons.shopping_cart_checkout;
      case 'item_shipped':
        return Icons.local_shipping;
      case 'confirm_receipt':
        return Icons.check_circle_outline;
      case 'request_denied':
        return Icons.cancel_outlined;
      case 'points_refunded':
        return Icons.currency_exchange;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case 'item_request':
        return Colors.blue;
      case 'confirm_receipt':
        return Colors.green;
      case 'request_denied':
        return Colors.red;
      case 'points_refunded':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : Colors.grey[50],
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left side - always show user profile for item_request, otherwise show icon
            if (type == 'item_request')
              Container(
                width: 45,
                height: 45,
                margin: EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[200]!, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22.5),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.person,
                      color: Colors.grey[400],
                      size: 25,
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getIconColor().withOpacity(0.1),
                ),
                child: Icon(_getIcon(), color: _getIconColor()),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timestamp != null
                        ? timeago.format(timestamp!.toDate())
                        : '',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Right side - show item image for item requests
            if (type == 'item_request' && itemImage != null)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: itemImage!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              )
            // For other notification types that have images
            else if (imageUrl != null && type != 'item_request')
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
