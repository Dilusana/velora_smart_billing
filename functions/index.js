const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Normalizes Sri Lankan phone numbers to international format (947XXXXXXXX).
 * Examples:
 * - "0771234567" -> "94771234567"
 * - "+94771234567" -> "94771234567"
 * - "94771234567" -> "94771234567"
 * - "771234567" -> "94771234567"
 */
function normalizeSriLankanPhone(phone) {
  if (!phone) return null;

  // Remove non-digit characters
  let clean = phone.toString().replace(/[^0-9]/g, "");

  if (!clean) return null;

  if (clean.startsWith("0")) {
    clean = "94" + clean.substring(1);
  } else if (clean.startsWith("7") && clean.length === 9) {
    clean = "94" + clean;
  }

  // Validate final format: 11 digits starting with 947
  if (clean.length === 11 && clean.startsWith("947")) {
    return clean;
  }

  return null;
}

/**
 * Firestore Event Trigger on 'orders/{orderId}' creation.
 * Automatically sends SMS notification via Text.lk API when a new order is created.
 */
exports.sendOrderSmsNotification = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snap, context) => {
    const orderId = context.params.orderId;
    const orderData = snap.data();

    if (!orderData) {
      console.log(`[SMS Warning] No data found for order: ${orderId}`);
      return null;
    }

    // 1. DUPLICATE SMS PREVENTION CHECK
    if (orderData.smsSent === true) {
      console.log(`[SMS Skip] SMS already sent for order: ${orderId}`);
      return null;
    }

    // 2. EXTRACT PHONE NUMBER
    const rawPhone = orderData.customerPhone || orderData.phone || orderData.phoneNumber || "";
    const recipient = normalizeSriLankanPhone(rawPhone);

    if (!recipient) {
      console.log(`[SMS Skip] Invalid or missing customer phone number for order: ${orderId}. Raw value: '${rawPhone}'`);
      await snap.ref.update({
        smsSent: false,
        smsError: `Invalid or missing phone number: '${rawPhone}'`,
      });
      return null;
    }

    // 3. EXTRACT TOTAL AMOUNT & ORDER ID
    const totalAmount = orderData.total !== undefined ? Number(orderData.total).toFixed(0) : "0";
    const displayOrderId = orderData.orderId || orderId;

    // 4. CONSTRUCT SMS MESSAGE
    const message = `Velora: Your order has been successfully placed. Order ID: ${displayOrderId}. Amount: Rs.${totalAmount}. Thank you for shopping with us.`;

    // 5. FETCH TEXT.LK API TOKEN FROM SECURE ENVIRONMENT / CONFIG
    const apiToken = process.env.TEXTLK_API_TOKEN || (functions.config().textlk ? functions.config().textlk.token : null);

    if (!apiToken) {
      console.error(`[SMS Error] Text.lk API token is not configured on the server.`);
      await snap.ref.update({
        smsSent: false,
        smsError: "Text.lk API token not configured in Cloud Functions environment",
      });
      return null;
    }

    const senderId = process.env.TEXTLK_SENDER_ID || (functions.config().textlk ? functions.config().textlk.sender_id : "VeloraSmart");

    console.log(`[SMS Sending] Sending SMS for order ${displayOrderId} to ${recipient}...`);

    try {
      // 6. CALL TEXT.LK API
      const response = await fetch("https://app.text.lk/api/v3/sms/send", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${apiToken}`,
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: JSON.stringify({
          recipient: recipient,
          sender_id: senderId,
          type: "plain",
          message: message,
        }),
      });

      const responseData = await response.json();
      console.log(`[SMS Response] Text.lk API response:`, JSON.stringify(responseData));

      if (response.ok && (responseData.status === "success" || responseData.code === 200 || responseData.data)) {
        const smsId = responseData.data ? (responseData.data.id || responseData.data.uid || "") : "";
        
        // 7. RECORD SUCCESS IN FIRESTORE
        await snap.ref.update({
          smsSent: true,
          smsSentAt: admin.firestore.FieldValue.serverTimestamp(),
          smsId: smsId ? String(smsId) : "SENT_SUCCESS",
          smsError: admin.firestore.FieldValue.delete(),
        });

        console.log(`[SMS Success] SMS sent successfully for order: ${orderId}`);
      } else {
        const errorMsg = responseData.message || responseData.error || JSON.stringify(responseData);
        console.error(`[SMS Failure] Text.lk returned error for order ${orderId}: ${errorMsg}`);
        
        // RECORD FAILURE IN FIRESTORE WITHOUT BREAKING ORDER
        await snap.ref.update({
          smsSent: false,
          smsError: errorMsg,
        });
      }
    } catch (error) {
      console.error(`[SMS Error] Exception during SMS sending for order ${orderId}:`, error);
      await snap.ref.update({
        smsSent: false,
        smsError: error.message || String(error),
      });
    }

    return null;
  });

/**
 * Firestore Event Trigger on 'notifications/{notificationId}' creation.
 * Securely delivers push notifications to User devices via Firebase Cloud Messaging (FCM).
 */
exports.sendPushNotificationOnCreate = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const notificationId = context.params.notificationId;
    const data = snap.data();

    if (!data) {
      console.log(`[FCM Warning] No data found for notification: ${notificationId}`);
      return null;
    }

    // Duplicate check
    if (data.status === "Sent") {
      console.log(`[FCM Skip] Notification ${notificationId} has already been sent.`);
      return null;
    }

    const title = data.title || "Velora Supermarket";
    const body = data.message || data.body || "";
    const targetType = (data.targetType || "all").toLowerCase();
    const targetUserId = data.targetUserId || "";

    console.log(`[FCM Start] Sending notification '${title}' (target: ${targetType}${targetUserId ? ` -> ${targetUserId}` : ""})`);

    const payload = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        notificationId: notificationId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        targetType: targetType,
        timestamp: String(Date.now()),
      },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "velora_notifications",
          priority: "high",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    try {
      let successCount = 0;
      let failureCount = 0;

      if (targetType === "all") {
        // Send to topic 'all_users'
        try {
          const topicMessage = {
            ...payload,
            topic: "all_users",
          };
          const response = await admin.messaging().send(topicMessage);
          console.log(`[FCM Success] Sent topic message: ${response}`);
          successCount = 1;
        } catch (topicErr) {
          console.warn(`[FCM Topic Warning] Could not send via topic: ${topicErr.message}. Fallback to token multicast...`);
        }

        // Multicast to all registered tokens in customers collection
        const customersSnap = await admin.firestore().collection("customers").get();
        const tokens = new Set();

        customersSnap.forEach((doc) => {
          const c = doc.data();
          if (c.fcmToken && typeof c.fcmToken === "string" && c.fcmToken.trim().length > 10) {
            tokens.add(c.fcmToken.trim());
          }
          if (Array.isArray(c.fcmTokens)) {
            c.fcmTokens.forEach((t) => {
              if (t && typeof t === "string" && t.trim().length > 10) tokens.add(t.trim());
            });
          }
        });

        const tokenList = Array.from(tokens);
        if (tokenList.length > 0) {
          // Batch multicast (up to 500 per batch)
          const chunkSize = 500;
          for (let i = 0; i < tokenList.length; i += chunkSize) {
            const chunk = tokenList.slice(i, i + chunkSize);
            const multicastMessage = {
              ...payload,
              tokens: chunk,
            };
            const batchResponse = await admin.messaging().sendEachForMulticast(multicastMessage);
            successCount += batchResponse.successCount;
            failureCount += batchResponse.failureCount;
          }
        }
      } else if (targetType === "employees" || targetType === "all_employees") {
        // Send to topic 'all_employees'
        try {
          const topicMessage = {
            ...payload,
            topic: "all_employees",
          };
          const response = await admin.messaging().send(topicMessage);
          console.log(`[FCM Success] Sent employees topic message: ${response}`);
          successCount = 1;
        } catch (topicErr) {
          console.warn(`[FCM Topic Warning] Could not send via employees topic: ${topicErr.message}`);
        }

        // Multicast to all registered tokens in employees / staff collection
        const employeesSnap = await admin.firestore().collection("employees").get();
        const tokens = new Set();

        employeesSnap.forEach((doc) => {
          const e = doc.data();
          if (e.fcmToken && typeof e.fcmToken === "string" && e.fcmToken.trim().length > 10) {
            tokens.add(e.fcmToken.trim());
          }
          if (Array.isArray(e.fcmTokens)) {
            e.fcmTokens.forEach((t) => {
              if (t && typeof t === "string" && t.trim().length > 10) tokens.add(t.trim());
            });
          }
        });

        const tokenList = Array.from(tokens);
        if (tokenList.length > 0) {
          const chunkSize = 500;
          for (let i = 0; i < tokenList.length; i += chunkSize) {
            const chunk = tokenList.slice(i, i + chunkSize);
            const multicastMessage = {
              ...payload,
              tokens: chunk,
            };
            const batchResponse = await admin.messaging().sendEachForMulticast(multicastMessage);
            successCount += batchResponse.successCount;
            failureCount += batchResponse.failureCount;
          }
        }
      } else {
        // Specific user or employee target
        let tokens = [];

        // 1. Fetch user doc by ID from customers or employees
        if (targetUserId) {
          const userDoc = await admin.firestore().collection("customers").doc(targetUserId).get();
          if (userDoc.exists) {
            const userData = userDoc.data();
            if (userData.fcmToken) tokens.push(userData.fcmToken);
            if (Array.isArray(userData.fcmTokens)) tokens.push(...userData.fcmTokens);
          }

          const empDoc = await admin.firestore().collection("employees").doc(targetUserId).get();
          if (empDoc.exists) {
            const empData = empDoc.data();
            if (empData.fcmToken) tokens.push(empData.fcmToken);
            if (Array.isArray(empData.fcmTokens)) tokens.push(...empData.fcmTokens);
          }
        }

        // 2. Query by email / phone fallback
        if (tokens.length === 0 && targetUserId) {
          const emailQuery = await admin.firestore().collection("customers").where("email", "==", targetUserId).get();
          emailQuery.forEach((d) => {
            const ud = d.data();
            if (ud.fcmToken) tokens.push(ud.fcmToken);
            if (Array.isArray(ud.fcmTokens)) tokens.push(...ud.fcmTokens);
          });

          const empEmailQuery = await admin.firestore().collection("employees").where("email", "==", targetUserId).get();
          empEmailQuery.forEach((d) => {
            const ed = d.data();
            if (ed.fcmToken) tokens.push(ed.fcmToken);
            if (Array.isArray(ed.fcmTokens)) tokens.push(...ed.fcmTokens);
          });
        }

        tokens = Array.from(new Set(tokens.filter((t) => t && t.trim().length > 10)));

        if (tokens.length > 0) {
          const multicastMessage = {
            ...payload,
            tokens: tokens,
          };
          const response = await admin.messaging().sendEachForMulticast(multicastMessage);
          successCount = response.successCount;
          failureCount = response.failureCount;
        } else {
          console.log(`[FCM Warning] No active FCM tokens found for target user: ${targetUserId}`);
        }
      }

      // Also create an in-app user_notifications document for the user(s) to view in their notification history
      await admin.firestore().collection("user_notifications").add({
        notificationId: notificationId,
        title: title,
        message: body,
        targetType: targetType,
        targetUserId: targetUserId,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update the admin notification record
      await snap.ref.update({
        status: "Sent",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        successCount: successCount,
        failureCount: failureCount,
      });

      console.log(`[FCM Complete] Notification ${notificationId} marked as Sent (Success: ${successCount}, Failed: ${failureCount})`);
    } catch (err) {
      console.error(`[FCM Error] Failed sending push notification ${notificationId}:`, err);
      await snap.ref.update({
        status: "Failed",
        error: err.message || String(err),
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return null;
  });

