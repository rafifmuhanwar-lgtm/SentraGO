import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'appwrite_client.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService(
    ref.watch(databasesProvider),
    ref.watch(appwriteStorageProvider),
  );
});

class DatabaseService {
  final Databases _databases;
  final Storage _storage;

  DatabaseService(this._databases, this._storage);

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

  Future<List<Map<String, dynamic>>> getChatMessages(String orderId) async {
    try {
      final docs = await _databases.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.chatsCollection,
        queries: [
          Query.equal('orderId', orderId),
          Query.orderAsc('timestamp'),
          Query.limit(200),
        ],
      );
      return docs.documents.map((doc) => {...doc.data, '\$id': doc.$id}).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> createChatMessage({required Map<String, dynamic> data}) async {
    await _databases.createDocument(
      databaseId: AppConfig.appwriteDatabaseId,
      collectionId: AppConfig.chatsCollection,
      documentId: 'unique()',
      data: data,
    );
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final doc = await _databases.getDocument(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.usersCollection,
        documentId: userId,
      );
      return {...doc.data, '\$id': doc.$id};
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadChatMedia(String filePath, String fileName) async {
    try {
      final file = await _storage.createFile(
        bucketId: AppConfig.storageBucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: filePath, filename: fileName),
      );
      return 'https://sgp.cloud.appwrite.io/v1/storage/buckets/${AppConfig.storageBucketId}/files/${file.$id}/view?project=${AppConfig.appwriteProjectId}';
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadProfileImage(String filePath, String fileName) async {
    return uploadChatMedia(filePath, fileName);
  }

  Future<void> updateChatStatus(String roomId, bool isOnline) async {
    try {
      await _databases.updateDocument(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.chatsCollection,
        documentId: roomId,
        data: {
          'isOnline': isOnline,
          'lastUpdatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Update chat status error: $e');
    }
  }

  // ─── Withdrawal Methods ───
  Future<void> createWithdrawal(Map<String, dynamic> data) async {
    try {
      await _databases.createDocument(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.withdrawalsCollection,
        documentId: ID.unique(),
        data: data,
      );
    } catch (e) {
      print('createWithdrawal error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getWithdrawals(String courierId) async {
    try {
      final docs = await _databases.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.withdrawalsCollection,
        queries: [
          Query.equal('courierId', courierId),
        ],
      );
      // Filter di dart lagi untuk keamanan index
      return docs.documents
          .where((doc) => doc.data['courierId'] == courierId)
          .map((doc) => doc.data)
          .toList();
    } catch (e) {
      print('getWithdrawals error: $e');
      return [];
    }
  }

  Future<void> updateCourierLocation(String orderId, double lat, double lng) async {
    try {
      await _databases.updateDocument(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.ordersCollection,
        documentId: orderId,
        data: {
          'courierLat': lat,
          'courierLng': lng,
        },
      );
    } catch (e) {
      print('updateCourierLocation error: $e');
      rethrow;
    }
  }
}
