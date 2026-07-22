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

  Future<List<Map<String, dynamic>>> getOrdersByQuery(List<String> queries) async {
    try {
      final docs = await _databases.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.ordersCollection,
        queries: queries,
      );
      return docs.documents.map((doc) => {...doc.data, '\$id': doc.$id}).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    Map<String, dynamic>? extraData,
  }) async {
    final data = <String, dynamic>{'status': status};
    if (extraData != null) {
      data.addAll(extraData);
    }
    await _databases.updateDocument(
      databaseId: AppConfig.appwriteDatabaseId,
      collectionId: AppConfig.ordersCollection,
      documentId: orderId,
      data: data,
    );
  }
}
