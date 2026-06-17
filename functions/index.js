const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendPushOnNotification = functions.firestore
  .document("notifications/{notifId}")
  .onCreate(async (snap, context) => {
    const notif = snap.data();

    // Get userId from notification document
    const userId = notif.userId;
    if (!userId) return null;

    // Fetch user's FCM token
    const userSnap = await admin.firestore()
      .collection("users")
      .doc(userId)
      .get();

    const fcmToken = userSnap.data()?.fcmToken;
    if (!fcmToken) {
      console.log("No FCM token for user:", userId);
      return null;
    }

    // Build FCM message with image support
    const message = {
      token: fcmToken,
      notification: {
        title: notif.title || "Locaro",
        body: notif.body || "You have a new notification",
        imageUrl: notif.imageUrl || null,
      },
      data: {
        type: notif.type || "System",
        referenceId: notif.referenceId || "",
        notifId: context.params.notifId,
        imageUrl: notif.imageUrl || "",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "locaro_high_importance_v1",
          sound: "default",
          priority: "high",
          imageUrl: notif.imageUrl || null,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
        fcmOptions: {
          imageUrl: notif.imageUrl || null,
        },
      },
    };

    // Remove null imageUrl fields to avoid FCM errors
    if (!notif.imageUrl) {
      delete message.notification.imageUrl;
      delete message.android.notification.imageUrl;
      delete message.apns.fcmOptions.imageUrl;
      delete message.data.imageUrl;
    }

    // Send FCM push notification
    try {
      await admin.messaging().send(message);
      console.log("Push sent to user:", userId);
    } catch (error) {
      console.error("FCM error:", error);
      // If token invalid, remove it
      if (error.code === 
          "messaging/registration-token-not-registered") {
        await admin.firestore()
          .collection("users")
          .doc(userId)
          .update({ fcmToken: admin.firestore.FieldValue.delete() });
      }
    }

    return null;
  });
