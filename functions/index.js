const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp }      = require('firebase-admin/app');
const { getFirestore }       = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();

// ── Play Integrity verification ───────────────────────────────────────────
exports.verifyIntegrity = onCall(async (request) => {
  const { token, deviceId } = request.data;
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Not authenticated');

  try {
    // In production: verify token with Google Play Integrity API
    console.log(`Integrity check for uid=${uid} deviceId=${deviceId}`);
    return { recognized: true };
  } catch (err) {
    await db.collection('suspicious_devices').add({
      uid, deviceId, error: err.message,
      timestamp: new Date()
    });
    return { recognized: false };
  }
});

// ── RevenueCat webhook → write entitlement ────────────────────────────────
const { onRequest } = require('firebase-functions/v2/https');

exports.revenuecatWebhook = onRequest(async (req, res) => {
  // Verify the webhook is from RevenueCat
  const authHeader = req.headers.authorization;
  const expectedSecret = process.env.REVENUECAT_WEBHOOK_SECRET;
  if (authHeader !== `Bearer ${expectedSecret}`) {
    res.status(401).send('Unauthorized');
    return;
  }

  const event = req.body;
  const { app_user_id, expiration_at_ms, event_type } = event;

  if (!app_user_id) {
    res.status(400).send('Missing app_user_id');
    return;
  }

  const activeEvents = [
    'INITIAL_PURCHASE', 'RENEWAL', 'PRODUCT_CHANGE',
    'UNCANCELLATION', 'SUBSCRIPTION_EXTENDED'
  ];
  const expiredEvents = [
    'EXPIRATION', 'CANCELLATION', 'BILLING_ISSUE'
  ];

  if (activeEvents.includes(event_type)) {
    const expiresAt = expiration_at_ms
      ? new Date(expiration_at_ms)
      : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    await db.collection('entitlements').doc(app_user_id).set({
      expiresAt:   expiresAt,
      updatedAt:   new Date(),
      eventType:   event_type,
      active:      true,
    });
    console.log(`Entitlement activated for ${app_user_id} until ${expiresAt}`);
  }

  if (expiredEvents.includes(event_type)) {
    await db.collection('entitlements').doc(app_user_id).set({
      expiresAt:   new Date(),
      updatedAt:   new Date(),
      eventType:   event_type,
      active:      false,
    });
    console.log(`Entitlement expired for ${app_user_id}`);
  }

  res.status(200).send('OK');
});

// ── FCM Fan-Out on Gym Events ─────────────────────────────────────────────
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { getMessaging }      = require('firebase-admin/messaging');

exports.fanOutGymNotification = onDocumentCreated('gyms/{gymId}/events/{eventId}', async (event) => {
  const gymId = event.params.gymId;
  const eventData = event.data.data();

  if (!eventData) return;

  // Get all active tokens for this gym
  const tokensSnap = await db
    .collection('gyms')
    .doc(gymId)
    .collection('device_tokens')
    .where('isActive', '==', true)
    .get();

  if (tokensSnap.empty) {
    console.log(`No active device tokens found for gym ${gymId}`);
    return;
  }

  const tokens = tokensSnap.docs.map(doc => doc.data().fcmToken);
  const messaging = getMessaging();

  // Send multicast message
  const message = {
    tokens,
    notification: {
      title: eventData.title,
      body: eventData.body,
    },
    data: {
      category: eventData.category || 'general',
      payload: JSON.stringify(eventData.payload || {}),
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'ironbook_alerts',
        priority: 'high',
        defaultSound: true,
      },
    },
  };

  try {
    const response = await messaging.sendEachForMulticast(message);

    // Clean up invalid tokens
    const invalidTokenDocs = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const token = tokens[idx];
        const code = resp.error?.code;
        if (
          code === 'messaging/invalid-registration-token' ||
          code === 'messaging/registration-token-not-registered'
        ) {
          const tokenDoc = tokensSnap.docs.find(d => d.data().fcmToken === token);
          if (tokenDoc) {
            invalidTokenDocs.push(tokenDoc.ref.update({ isActive: false }));
          }
        }
      }
    });

    await Promise.all(invalidTokenDocs);
    console.log(`Fan-out complete for gym ${gymId}: ${response.successCount} success, ${response.failureCount} failed`);
  } catch (err) {
    console.error(`Multicast send failed for gym ${gymId}:`, err);
  }
});
