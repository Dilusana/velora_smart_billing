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

    const senderId = process.env.TEXTLK_SENDER_ID || (functions.config().textlk ? functions.config().textlk.sender_id : "TextLKDemo");

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
