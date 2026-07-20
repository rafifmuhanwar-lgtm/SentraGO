import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'appwrite_client.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService(ref.watch(databasesProvider));
});

class DatabaseService {
  final Databases _databases;

  DatabaseService(this._databases);

  // ─── User Methods ───

  Future<void> createUser({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _databases.createDocument(
      databaseId: AppConfig.appwriteDatabaseId,
      collectionId: AppConfig.usersCollection,
      documentId: userId,
      data: data,
    );
  }

  Future<void> updateUser({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _databases.updateDocument(
      databaseId: AppConfig.appwriteDatabaseId,
      collectionId: AppConfig.usersCollection,
      documentId: userId,
      data: data,
    );
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.usersCollection,
        documentId: userId,
      );
      return doc.data;
    } catch (e) {
      return null;
    }
  }

  // ─── Order Methods ───

  Future<void> createOrder({
    required String orderId,
    required Map<String, dynamic> data,
  }) async {
    await _databases.createDocument(
      databaseId: AppConfig.appwriteDatabaseId,
      collectionId: AppConfig.ordersCollection,
      documentId: orderId,
      data: data,
    );
  }

  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final docs = await _databases.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.ordersCollection,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('createdAt'),
        ],
      );
      return docs.documents.map((doc) => doc.data).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _databases.updateDocument(
      databaseId: AppConfig.appwriteDatabaseId,
      collectionId: AppConfig.ordersCollection,
      documentId: orderId,
      data: {'status': status},
    );
  }
}
