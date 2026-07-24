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
    // Set permissions agar user yang buat bisa baca & edit order miliknya sendiri
    final userId = data['userId'] as String?;
    final permissions = userId != null
        ? [
            Permission.read(Role.user(userId)),
            Permission.update(Role.user(userId)),
            Permission.delete(Role.user(userId)),
          ]
        : <String>[];

    await _databases.createDocument(
      databaseId: AppConfig.appwriteDatabaseId,
      collectionId: AppConfig.ordersCollection,
      documentId: orderId,
      data: data,
      permissions: permissions,
    );
  }

  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    print('DEBUG: getUserOrders called for userId: $userId');
    try {
      // Filter langsung di Appwrite berdasarkan userId
      final docs = await _databases.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.ordersCollection,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('\$createdAt'),
          Query.limit(100),
        ],
      );
      print('DEBUG: Fetched ${docs.documents.length} orders for userId: $userId');
      return docs.documents.map((doc) => {...doc.data, '\$id': doc.$id}).toList();
    } catch (e) {
      print('DEBUG: getUserOrders error: $e');
      // Fallback: coba tanpa orderDesc kalau belum ada index
      try {
        print('DEBUG: Retrying without orderDesc...');
        final fallbackDocs = await _databases.listDocuments(
          databaseId: AppConfig.appwriteDatabaseId,
          collectionId: AppConfig.ordersCollection,
          queries: [
            Query.equal('userId', userId),
            Query.limit(100),
          ],
        );
        final orders = fallbackDocs.documents
            .map((doc) => {...doc.data, '\$id': doc.$id})
            .toList();
        orders.sort((a, b) {
          final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(0);
          final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(0);
          return dateB.compareTo(dateA);
        });
        print('DEBUG: Fallback fetched ${orders.length} orders');
        return orders;
      } catch (fallbackError) {
        print('DEBUG: Fallback also failed: $fallbackError');
        return [];
      }
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

  /// Ambil data kurir dari koleksi couriers berdasarkan courierId
  Future<Map<String, dynamic>?> getCourierById(String courierId) async {
    if (courierId.isEmpty) return null;
    try {
      final doc = await _databases.getDocument(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.couriersCollection,
        documentId: courierId,
      );
      return {...doc.data, '\$id': doc.$id};
    } catch (e) {
      print('getCourierById error: $e');
      return null;
    }
  }

  // ─── Chat Methods ───

  Future<void> createChatMessage({
    required Map<String, dynamic> data,
  }) async {
    await _databases.createDocument(
      databaseId: AppConfig.appwriteDatabaseId,
      collectionId: AppConfig.chatsCollection,
      documentId: 'unique()',
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
        ],
      );
      // Ensure we add \$id manually if needed by the models, though getDocument also has \$id in the object properties
      return docs.documents.map((doc) => {
        ...doc.data,
        '\$id': doc.$id,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> uploadChatMedia(String filePath, String fileName) async {
    try {
      final file = await _storage.createFile(
        bucketId: AppConfig.storageBucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: filePath, filename: fileName),
      );

      final fileUrl = 'https://sgp.cloud.appwrite.io/v1/storage/buckets/${AppConfig.storageBucketId}/files/${file.$id}/view?project=${AppConfig.appwriteProjectId}';
      return fileUrl;
    } catch (e) {
      print('uploadChatMedia error: $e');
      return null;
    }
  }

  Future<String?> uploadProfileImage(String filePath, String fileName) async {
    try {
      final file = await _storage.createFile(
        bucketId: AppConfig.storageBucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: filePath, filename: fileName),
      );

      final fileUrl = 'https://sgp.cloud.appwrite.io/v1/storage/buckets/${AppConfig.storageBucketId}/files/${file.$id}/view?project=${AppConfig.appwriteProjectId}';
      return fileUrl;
    } catch (e) {
      print('uploadProfileImage error: $e');
      return null;
    }
  }


  // ─── Profile Methods ───
  
  Future<List<Map<String, dynamic>>> getUserAddresses(String userId) async {
    try {
      final docs = await _databases.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: 'addresses',
        queries: [Query.equal('userId', userId)],
      );
      return docs.documents.map((doc) => {...doc.data, '\$id': doc.$id}).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveAddress(String addressId, Map<String, dynamic> data) async {
    try {
      await _databases.updateDocument(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: 'addresses',
        documentId: addressId,
        data: data,
      );
    } catch (_) {
      await _databases.createDocument(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: 'addresses',
        documentId: addressId,
        data: data,
      );
    }
  }
  
  Future<void> deleteAddress(String addressId) async {
    await _databases.deleteDocument(
      databaseId: AppConfig.appwriteDatabaseId,
      collectionId: 'addresses',
      documentId: addressId,
    );
  }

  Future<List<Map<String, dynamic>>> getUserPaymentMethods(String userId) async {
    try {
      final docs = await _databases.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: 'payment_methods',
        queries: [Query.equal('userId', userId)],
      );
      return docs.documents.map((doc) => {...doc.data, '\$id': doc.$id}).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> savePaymentMethod(String methodId, Map<String, dynamic> data) async {
    try {
      await _databases.updateDocument(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: 'payment_methods',
        documentId: methodId,
        data: data,
      );
    } catch (_) {
      await _databases.createDocument(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: 'payment_methods',
        documentId: methodId,
        data: data,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getPromos() async {
    try {
      final docs = await _databases.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: 'promos',
      );
      return docs.documents.map((doc) => {...doc.data, '\$id': doc.$id}).toList();
    } catch (e) {
      return [];
    }
  }

  // ─── SentraPay Wallet Methods ───

  Future<Map<String, dynamic>?> getWallet(String userId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: 'sentrapay_wallets',
        documentId: userId,
      );
      return {...doc.data, '\$id': doc.$id};
    } catch (e) {
      return null;
    }
  }

  Future<void> createWallet({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _databases.createDocument(
      databaseId: AppConfig.appwriteDatabaseId,
      collectionId: 'sentrapay_wallets',
      documentId: userId,
      data: data,
    );
  }

  Future<void> updateWallet({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _databases.updateDocument(
      databaseId: AppConfig.appwriteDatabaseId,
      collectionId: 'sentrapay_wallets',
      documentId: userId,
      data: data,
    );
  }

  // ─── Escrow Methods ───

  Future<void> createEscrow({
    required String escrowId,
    required Map<String, dynamic> data,
  }) async {
    await _databases.createDocument(
      databaseId: AppConfig.appwriteDatabaseId,
      collectionId: 'escrow_transactions',
      documentId: escrowId,
      data: data,
    );
  }

  Future<void> updateEscrow({
    required String escrowId,
    required Map<String, dynamic> data,
  }) async {
    await _databases.updateDocument(
      databaseId: AppConfig.appwriteDatabaseId,
      collectionId: 'escrow_transactions',
      documentId: escrowId,
      data: data,
    );
  }

  Future<List<Map<String, dynamic>>> getUserEscrows(String userId) async {
    try {
      final docs = await _databases.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: 'escrow_transactions',
        queries: [Query.equal('userId', userId), Query.orderDesc('createdAt')],
      );
      return docs.documents.map((doc) => {...doc.data, '\$id': doc.$id}).toList();
    } catch (e) {
      return [];
    }
  }

  // ─── TopUp Transaction Methods ───

  Future<void> createTopUpTransaction({
    required String transactionId,
    required Map<String, dynamic> data,
  }) async {
    await _databases.createDocument(
      databaseId: AppConfig.appwriteDatabaseId,
      collectionId: 'topup_transactions',
      documentId: transactionId,
      data: data,
    );
  }

  Future<void> updateTopUpTransaction({
    required String transactionId,
    required Map<String, dynamic> data,
  }) async {
    await _databases.updateDocument(
      databaseId: AppConfig.appwriteDatabaseId,
      collectionId: 'topup_transactions',
      documentId: transactionId,
      data: data,
    );
  }

  Future<List<Map<String, dynamic>>> getUserTopUpTransactions(
      String userId) async {
    try {
      final docs = await _databases.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: 'topup_transactions',
        queries: [Query.equal('userId', userId), Query.orderDesc('createdAt')],
      );
      return docs.documents.map((doc) => {...doc.data, '\$id': doc.$id}).toList();
    } catch (e) {
      return [];
    }
  }
}
