class AppConfig {
  AppConfig._();

  // Appwrite Configuration
  // TODO: Ganti dengan Project ID kamu dari Appwrite Console
  static const String appwriteEndpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String appwriteProjectId = '6a5a2ab80012a3e5860a';
  static const String appwriteDatabaseId = '6a5a2cca002aaa8dd6f8';

  // Appwrite Collection IDs
  static const String usersCollection = 'users';
  static const String ordersCollection = 'orders';
  static const String chatsCollection = 'chats';
  static const String couriersCollection = 'couriers';

  // Appwrite Storage Bucket IDs
  // TODO: Ganti dengan Bucket ID kamu dari Appwrite Console
  static const String storageBucketId = '6a5d565700192c93077a';

  // Appwrite OAuth Redirect URLs
  static const String oauthSuccessRedirect = 'appwrite-custom-6a5a2ab80012a3e5860a://success';
  static const String oauthFailureRedirect = 'appwrite-custom-6a5a2ab80012a3e5860a://failure';

  // Port untuk Flutter Web dev server (sesuaikan jika beda)
  static const int webPort = 57552;

  // ── Pakasir Payment Gateway ──
  // TODO: Ganti dengan API Key dan Slug dari Pakasir Dashboard
  static const String pakasirBaseUrl = 'https://app.pakasir.com';
  static const String pakasirProjectSlug = 'sentrago'; // dari halaman Project
  static const String pakasirApiKey = 'NOZxCGsEnU4CA7kQD9snZnJM0E34EKsh'; // dari halaman Project

  // ── Mapbox ──
  // Token dibaca dari --dart-define=MAPBOX_ACCESS_TOKEN=...
  static const String mapboxAccessToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: '');
}
