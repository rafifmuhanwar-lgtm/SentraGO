class AppConfig {
  AppConfig._();

  // ── Appwrite ──
  static const String appwriteEndpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String appwriteProjectId = '6a5a2ab80012a3e5860a';
  static const String appwriteDatabaseId = '6a5a2cca002aaa8dd6f8';

  // ── Appwrite Collection IDs ──
  static const String usersCollection = 'users';
  static const String couriersCollection = 'couriers'; // Separate collection for couriers
  static const String ordersCollection = 'orders';
  static const String chatsCollection = 'chats';
  static const String withdrawalsCollection = 'withdrawals';

  // ── Appwrite Storage Bucket IDs ──
  static const String storageBucketId = '6a5d565700192c93077a';

  // ── Appwrite OAuth Redirect URLs ──
  static const String oauthSuccessRedirect = 'appwrite-custom-6a5a2ab80012a3e5860a://success';
  static const String oauthFailureRedirect = 'appwrite-custom-6a5a2ab80012a3e5860a://failure';

  // ── Mapbox ──
  // Token dibaca dari --dart-define=MAPBOX_ACCESS_TOKEN=...
  // (bisa dari .env atau environment variable)
  static const String mapboxAccessToken =
      String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: '');
}
