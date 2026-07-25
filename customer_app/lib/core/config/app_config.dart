import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  /// Load environment variables from .env file.
  /// Call once at startup (e.g. in main() before runApp).
  static Future<void> load() => dotenv.load();

  // ── Appwrite ──
  static String get appwriteEndpoint =>
      dotenv.env['APPWRITE_ENDPOINT'] ?? 'https://sgp.cloud.appwrite.io/v1';
  static String get appwriteProjectId =>
      dotenv.env['APPWRITE_PROJECT_ID'] ?? '6a5a2ab80012a3e5860a';
  static String get appwriteDatabaseId =>
      dotenv.env['APPWRITE_DATABASE_ID'] ?? '6a5a2cca002aaa8dd6f8';

  // ── Appwrite Collection IDs ──
  static const String usersCollection = 'users';
  static const String ordersCollection = 'orders';
  static const String chatsCollection = 'chats';
  static const String couriersCollection = 'couriers';
  static const String notificationsCollection = 'notifications';

  // ── Appwrite Storage Bucket IDs ──
  static String get storageBucketId =>
      dotenv.env['APPWRITE_STORAGE_BUCKET_ID'] ?? '6a5d565700192c93077a';

  // ── Appwrite OAuth Redirect URLs ──
  static String get oauthSuccessRedirect =>
      dotenv.env['APPWRITE_OAUTH_SUCCESS_REDIRECT'] ??
      'appwrite-custom-6a5a2ab80012a3e5860a://success';
  static String get oauthFailureRedirect =>
      dotenv.env['APPWRITE_OAUTH_FAILURE_REDIRECT'] ??
      'appwrite-custom-6a5a2ab80012a3e5860a://failure';

  // ── Pakasir Payment Gateway ──
  static String get pakasirBaseUrl =>
      dotenv.env['PAKASIR_BASE_URL'] ?? 'https://app.pakasir.com';
  static String get pakasirProjectSlug =>
      dotenv.env['PAKASIR_PROJECT_SLUG'] ?? 'sentrago';
  static String get pakasirApiKey =>
      dotenv.env['PAKASIR_API_KEY'] ?? '';

  // ── Mapbox ──
  static String get mapboxAccessToken =>
      dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
}
