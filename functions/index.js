const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

// Initialize Firebase Admin
initializeApp();

// Send notification when a new notification document is created
exports.sendNotificationOnRequest = onDocumentCreated(
    "notifications/{notificationId}", 
    async (event) => {
      const snapshot = event.data;
      if (!snapshot) return;
      
      const notification = snapshot.data();
      
      // Skip if already processed
      if (notification.notificationSent === true) {
        console.log('Notification already sent, skipping');
        return;
      }
  
      // Enhanced deduplication - check for similar recent notifications
      const dedupeWindow = new Date(Date.now() - 5 * 60 * 1000); // 5 minute window
      
      const similarNotifications = await getFirestore()
        .collection('notifications')
        .where('userId', '==', notification.userId)
        .where('type', '==', notification.type)
        .where('itemId', '==', notification.itemId || '')
        .where('timestamp', '>', dedupeWindow)
        .where('notificationSent', '==', true)
        .limit(1)
        .get();
  
      if (!similarNotifications.empty) {
        console.log('Duplicate notification detected, skipping');
        await snapshot.ref.update({ notificationSent: false, duplicate: true });
        return;
      }
  
      try {
        const db = getFirestore();
        const userDoc = await db.collection("users").doc(notification.userId).get();
        
        if (!userDoc.exists) return;
        
        const fcmToken = userDoc.data().fcmToken;
        if (!fcmToken) return;
        
        // Add a unique deduplication ID
        const dedupeId = `${notification.userId}_${notification.type}_${notification.itemId || 'none'}_${Math.floor(Date.now() / (5 * 60 * 1000))}`; // 5-minute window
        
        const message = {
          token: fcmToken,
          notification: {
            title: notification.title,
            body: notification.message,
          },
          data: {
            ...notification.data, // preserve existing data
            type: notification.type,
            itemId: notification.itemId || '',
            dedupeId: dedupeId, // Add deduplication ID
            originalNotificationId: snapshot.id
          },
          android: {
            notification: {
              clickAction: 'FLUTTER_NOTIFICATION_CLICK',
              priority: 'high',
              sound: 'default',
              channelId: notification.type === 'new_donation' ? 
                'new_donations' : 'item_requests'
            }
          },
          apns: {
            headers: {
              'apns-collapse-id': dedupeId // iOS deduplication
            }
          }
        };
        
        await getMessaging().send(message);
        
        // Mark as sent with additional deduplication info
        await snapshot.ref.update({
          notificationSent: true,
          sentTimestamp: new Date(),
          dedupeId: dedupeId
        });
        
      } catch (error) {
        console.error('Error sending notification:', error);
        // Don't throw error to prevent retries that could cause duplicates
        await snapshot.ref.update({
          error: error.message,
          notificationSent: false
        });
      }
    }
  );
// Send notifications when a donor posts a new item
exports.notifySubscribersOnNewDonation = onDocumentCreated(
    "donations/{donationId}",
    async (event) => {
      try {
        const snapshot = event.data;
        if (!snapshot.exists) return;
  
        const donation = snapshot.data();
        if (donation.status !== 'available') return;
  
        const donorId = donation.userId;
        if (!donorId) return;
  
        const db = getFirestore();
        
        // Now we can directly query the donor's subscribers
        const subscribersSnapshot = await db.collection(`users/${donorId}/subscribers`).get();
        
        if (subscribersSnapshot.empty) {
          console.log('No subscribers found for this donor');
          return;
        }
  
        // Prepare notification
        const notificationTitle = "New Item Available!";
        const notificationBody = `${donation.userFullName} posted: ${donation.itemName}`;
        
        const batch = db.batch();
        const messaging = getMessaging();
        
        // Process each subscriber
        const promises = subscribersSnapshot.docs.map(async (subscriberDoc) => {
          const subscriberId = subscriberDoc.id;
          const subscriberData = subscriberDoc.data();
          
          // Get subscriber's FCM token
          const userDoc = await db.collection("users").doc(subscriberId).get();
          if (!userDoc.exists || !userDoc.data().fcmToken) {
            console.log(`No FCM token for subscriber ${subscriberId}`);
            return;
          }
  
          const fcmToken = userDoc.data().fcmToken;
          
          // Create notification
          const notificationRef = db.collection("notifications").doc();
          batch.set(notificationRef, {
            userId: subscriberId,
            type: 'new_donation',
            title: notificationTitle,
            message: notificationBody,
            itemId: snapshot.id,
            donorId: donorId,
            timestamp: new Date(),
            isRead: false,
            notificationSent: false
          });
  
          // Send FCM
          try {
            await messaging.send({
              token: fcmToken,
              notification: { title: notificationTitle, body: notificationBody },
              data: { 
                type: 'new_donation', 
                itemId: snapshot.id,
                notificationId: notificationRef.id
              }
            });
            
            batch.update(notificationRef, { notificationSent: true });
          } catch (error) {
            console.error(`Failed to send to ${subscriberId}:`, error);
            batch.update(notificationRef, { 
              error: error.message,
              notificationSent: false
            });
          }
        });
  
        await Promise.all(promises);
        await batch.commit();
        console.log(`Processed ${subscribersSnapshot.size} subscribers`);
        
      } catch (error) {
        console.error('Error in notifySubscribersOnNewDonation:', error);
      }
    }
  );
// Check for unconfirmed shipments daily
exports.checkUnconfirmedShipments = onSchedule(
  {schedule: "every 24 hours"}, 
  async (context) => {
    try {
      const db = getFirestore();
      
      // Get items marked as shipped but not completed/disputed
      const testTimeAgo = new Date(Date.now() - 1 * 60 * 1000); // 1 minute ago instead of 3 days
      
      const items = await db.collection('donations')
        .where('status', '==', 'sold')
        .where('soldDate', '<=', testTimeAgo)
        .get();
      
      const batch = db.batch();
      
      for (const item of items.docs) {
        const itemData = item.data();
        
        // Create follow-up notification
        const notificationRef = db.collection('notifications').doc();
        batch.set(notificationRef, {
          userId: itemData.buyerId,
          type: 'shipped_followup',
          title: 'Item Received?',
          message: `Have you received "${itemData.itemName}"? Please confirm or report an issue.`,
          itemId: item.id,
          itemName: itemData.itemName,
          sellerId: itemData.userId,
          timestamp: new Date(),
          isRead: false,
          isFirstView: true,
          needsAction: true
        });
        
        // Get buyer's FCM token
        const buyerDoc = await db.collection('users').doc(itemData.buyerId).get();
        
        if (buyerDoc.exists) {
          const buyerToken = buyerDoc.data().fcmToken;
          
          if (buyerToken) {
            await getMessaging().send({
              token: buyerToken,
              notification: {
                title: 'Item Received?',
                body: `Have you received "${itemData.itemName}"? Please confirm.`
              },
              data: {
                type: 'shipped_followup',
                itemId: item.id,
                notificationId: notificationRef.id
              }
            });
          }
        }
      }
      
      await batch.commit();
      console.log(`Sent follow-up notifications for ${items.docs.length} items`);
      
    } catch (error) {
      console.error('Error checking unconfirmed shipments:', error);
    }
  }
);

// Add new milestone notification handler
exports.handleSubscriberMilestone = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const notification = snapshot.data();
    
    // Only process subscriber milestone notifications
    if (notification.type !== 'subscriber_milestone') return;
    
    try {
      // Get the user's FCM token
      const userDoc = await getFirestore()
        .collection('users')
        .doc(notification.userId)
        .get();
        
      const fcmToken = userDoc.data()?.fcmToken;
      
      if (!fcmToken) {
        console.log('No FCM token found for user:', notification.userId);
        return;
      }

      // Send the push notification
      const message = {
        token: fcmToken,
        notification: {
          title: notification.title || 'Subscriber Milestone! 🎉',
          body: notification.message || 'You reached a subscriber milestone!',
        },
        data: {
          type: 'subscriber_milestone',
          notificationId: snapshot.id,
        },
        android: {
          notification: {
            icon: '@mipmap/ic_launcher',
            color: '#000000',
            priority: 'high',
            channelId: 'item_requests',
          },
        },
      };

      await getMessaging().send(message);
      
      // Mark notification as sent
      await snapshot.ref.update({
        notificationSent: true,
        sentTimestamp: new Date(),
      });

    } catch (error) {
      console.error('Error sending milestone notification:', error);
    }
  }
);

// Add new message notification handler
exports.handleMessageNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const notification = snapshot.data();
    
    // Skip processing message notifications completely
    if (notification.type === 'new_message') return;
    
    // ...rest of notification handling code...
  }
);