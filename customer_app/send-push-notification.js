const sdk = require('node-appwrite');
const https = require('https');
const { GoogleAuth } = require('google-auth-library');

function getEnv(context, key) {
  return context?.req?.variables?.[key] || process.env[key] || '';
}

// ─── Rebuild PEM dari string yang mungkin rusak ───
function rebuildPEM(raw) {
  // Hapus semua "\\n", "\n", spasi, dan "-----BEGIN/END" yg salah format
  let cleaned = raw
    .replace(/\\n/g, '\n')      // literal \n → real newline
    .replace(/\\r/g, '')        // \\r → hapus
    .replace(/\r\n/g, '\n')     // windows CRLF → LF
    .trim();

  // Pastikan ada header/trailer
  if (!cleaned.startsWith('-----BEGIN')) {
    // Potensial: value cuma berisi base64 doang tanpa header
    cleaned = '-----BEGIN PRIVATE KEY-----\n' + cleaned;
  }
  if (!cleaned.endsWith('-----END PRIVATE KEY-----')) {
    cleaned = cleaned.replace(/PRIVATE KEY-----$/, 'PRIVATE KEY-----\n');
    if (!cleaned.endsWith('-----END PRIVATE KEY-----')) {
      cleaned = cleaned + '\n-----END PRIVATE KEY-----';
    }
  }

  return cleaned;
}

module.exports = async function (context) {
  try {
    const client = new sdk.Client();
    const databases = new sdk.Databases(client);

    client
      .setEndpoint(getEnv(context, 'APPWRITE_ENDPOINT'))
      .setProject(getEnv(context, 'APPWRITE_PROJECT_ID'))
      .setKey(getEnv(context, 'APPWRITE_API_KEY'));

    let parsedBody = context?.req?.body;
    if (typeof parsedBody === 'string') parsedBody = JSON.parse(parsedBody);
    if (!parsedBody || typeof parsedBody !== 'object') {
      context.res.send(JSON.stringify({ success: false, message: 'Invalid body' }), 400);
      return context.res.empty();
    }

    const { userId, title, body: notifBody, category, route, fcmToken } = parsedBody;

    let token = fcmToken;
    if (!token && userId) {
      try {
        const userDoc = await databases.getDocument(
          getEnv(context, 'APPWRITE_DATABASE_ID'), 'users', userId
        );
        token = userDoc.fcmToken;
      } catch (e) {
        context.res.send(JSON.stringify({ success: false, message: 'User not found' }), 400);
        return context.res.empty();
      }
    }

    if (!token) {
      context.res.send(JSON.stringify({ success: false, message: 'No FCM token' }), 400);
      return context.res.empty();
    }

    // Rebuild private key
    const rawKey = getEnv(context, 'FCM_PRIVATE_KEY');
    const privateKey = rebuildPEM(rawKey);

    // Log untuk debug (tampilkan 50 karakter pertama)
    context.log('Key length: ' + privateKey.length);
    context.log('Key starts with: ' + privateKey.substring(0, 40));

    const auth = new GoogleAuth({
      credentials: {
        client_email: getEnv(context, 'FCM_CLIENT_EMAIL'),
        private_key: privateKey,
      },
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    });

    const accessToken = await auth.getAccessToken();
    context.log('Access token: OK');

    const fcmMessage = JSON.stringify({
      message: {
        token: token,
        notification: { title, body: notifBody || '' },
        data: { userId: userId || '', route: route || '', category: category || 'Sistem & Akun' },
      },
    });

    const fcmResult = await new Promise((resolve, reject) => {
      const req = https.request({
        hostname: 'fcm.googleapis.com',
        path: `/v1/projects/${getEnv(context, 'FCM_PROJECT_ID')}/messages:send`,
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
      }, (res) => {
        let str = '';
        res.on('data', chunk => str += chunk);
        res.on('end', () => resolve({ status: res.statusCode, body: str }));
      });
      req.on('error', reject);
      req.write(fcmMessage);
      req.end();
    });

    context.log('FCM status: ' + fcmResult.status);
    context.log('FCM body: ' + fcmResult.body);

    context.res.send(JSON.stringify({ success: fcmResult.status < 300, fcmStatus: fcmResult.status }));
    return context.res.empty();

  } catch (error) {
    context.error('Error: ' + error.message);
    context.error('Stack: ' + (error.stack || ''));
    context.res.send(JSON.stringify({ success: false, error: error.message }));
    return context.res.empty();
  }
};
