const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotificationOnRequest = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snap, context) => {
        const notification = snap.data();
        
        try {
            const userDoc = await admin.firestore()
                .collection('users')
                .doc(notification.userId)
                .get();
            
            const fcmToken = userDoc.data().fcmToken;
            
            if (!fcmToken) return;

            const message = {
                token: fcmToken,
                notification: {
                    title: notification.title,
                    body: notification.message,
                },
                data: {
                    type: notification.type,
                    itemId: notification.itemId || '',
                },
                android: {
                    notification: {
                        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                        priority: 'high',
                        sound: 'default'
                    }
                },
            };

            await admin.messaging().send(message);
            console.log('Notification sent successfully');
            
        } catch (error) {
            console.error('Error sending notification:', error);
        }
    });
