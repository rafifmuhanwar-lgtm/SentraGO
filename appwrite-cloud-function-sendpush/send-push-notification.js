const sdk = require('node-appwrite');
const admin = require('firebase-admin');

const client = new sdk.Client();
client
  .setEndpoint(process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1')
  .setProject(process.env.APPWRITE_PROJECT_ID)
  .setKey(process.env.APPWRITE_API_KEY);

const databases = new sdk.Databases(client);

const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || '6a5a2cca002aaa8dd6f8';
const USERS_COLLECTION = 'users';
const COURIERS_COLLECTION = 'couriers';

if (!admin.apps.length) {
  const serviceAccount = {
    projectId: process.env.FCM_PROJECT_ID,
    clientEmail: process.env.FCM_CLIENT_EMAIL,
    privateKey: (process.env.FCM_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
  };

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

module.exports = async function (req, res) {
  try {
    // Parse body — bisa string JSON atau udah object
    let body = req.body || req.payload || '{}';
    if (typeof body === 'string') {
      body = JSON.parse(body);
    }
    const payload = body;
    const { userId, title, body: notifBody, category, route, data } = payload;

    if (!userId) {
      res.json({ success: false, error: 'userId is required' });
      return;
    }

    if (!title || !notifBody) {
      res.json({ success: false, error: 'title and body are required' });
      return;
    }

    let fcmTokenResult = null;

    // 1. Coba dari couriers dulu
    try {
      const courierDoc = await databases.getDocument(DATABASE_ID, COURIERS_COLLECTION, userId);
      if (courierDoc.fcmToken) fcmTokenResult = courierDoc.fcmToken;
    } catch (e) { /* courier not found — lanjut */ }

    // 2. Fallback ke users
    if (!fcmTokenResult) {
      try {
        const userDoc = await databases.getDocument(DATABASE_ID, USERS_COLLECTION, userId);
        if (userDoc.fcmToken) fcmTokenResult = userDoc.fcmToken;
      } catch (e) {
        res.json({ success: false, error: 'User/courier not found' });
        return;
      }
    }

    if (!fcmTokenResult) {
      res.json({ success: false, error: 'No FCM token found for user' });
      return;
    }

    const message = {
      token: fcmTokenResult,
      notification: { title, body: notifBody },
      data: {
        ...(data || {}),
        route: route || '',
        category: category || '',
      },
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default', badge: 1 } } },
    };

    const response = await admin.messaging().send(message);

    // Simpan ke collection notifications
    try {
      await databases.createDocument(DATABASE_ID, 'notifications', sdk.ID.unique(), {
        userId,
        title,
        body: notifBody,
        category: category || 'Sistem & Akun',
        isRead: false,
        createdAt: new Date().toISOString(),
        routeName: route || '',
      });
    } catch (e) { /* skip */ }

    res.json({ success: true, messageId: response });

  } catch (error) {
    console.error('Function error:', error);
    res.json({ success: false, error: error.message || 'Internal error' });
  }
};
