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
