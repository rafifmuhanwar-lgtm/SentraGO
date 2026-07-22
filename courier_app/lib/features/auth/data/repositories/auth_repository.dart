import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/appwrite_client.dart';
import '../../domain/models/courier_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    account: ref.watch(accountProvider),
    databases: ref.watch(databasesProvider),
  );
});

class AuthRepository {
  final Account _account;
  final Databases _databases;

  AuthRepository({
    required Account account,
    required Databases databases,
  })  : _account = account,
        _databases = databases;

  Future<bool> isAuthenticated() async {
    try {
      await _account.get();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<CourierModel?> getCurrentCourier() async {
    try {
      final appwriteUser = await _account.get();
      Map<String, dynamic> courierData = _mapAppwriteUser(appwriteUser);

      // Try to fetch additional courier profile data from database
      try {
        final doc = await _databases.getDocument(
          databaseId: AppConfig.appwriteDatabaseId,
          collectionId: AppConfig.couriersCollection,
          documentId: appwriteUser.$id,
        );
        final docData = doc.data;
        courierData = {
          ...courierData,
          'phone': docData['phone'] ?? courierData['phone'],
          'photoUrl': docData['photoUrl'] ?? courierData['photoUrl'],
          'vehicleType': docData['vehicleType'] ?? courierData['vehicleType'],
          'vehiclePlate': docData['vehiclePlate'] ?? courierData['vehiclePlate'],
          'selectedArea': docData['selectedArea'] ?? courierData['selectedArea'],
          'isOnline': docData['isOnline'] ?? courierData['isOnline'],
          'isActive': docData['isActive'] ?? courierData['isActive'],
          'kycVerified': docData['kycVerified'] ?? courierData['kycVerified'],
        };
        if ((courierData['name'] as String).isEmpty && docData['name'] != null) {
          courierData['name'] = docData['name'];
        }
      } catch (_) {
        // Document might not exist yet, ignore
      }

      return CourierModel.fromJson(courierData, appwriteUser.$id);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> _mapAppwriteUser(dynamic user) {
    return {
      'name': user.name ?? '',
      'email': user.email ?? '',
      'phone': user.phone,
      'photoUrl': null,
    };
  }

  Future<void> signInWithGoogle() async {
    // Login Google via Appwrite OAuth
    await _account.createOAuth2Session(
      provider: OAuthProvider.google,
    );
  }

  Future<CourierModel> saveCourierToDatabase(CourierModel courier) async {
    try {
      try {
        await _databases.getDocument(
          databaseId: AppConfig.appwriteDatabaseId,
          collectionId: AppConfig.couriersCollection,
          documentId: courier.id,
        );
        await _databases.updateDocument(
          databaseId: AppConfig.appwriteDatabaseId,
          collectionId: AppConfig.couriersCollection,
          documentId: courier.id,
          data: courier.toJson(),
        );
      } catch (e) {
        // If update fails (bad schema), fallback to create with basic fields
        try {
          await _databases.createDocument(
            databaseId: AppConfig.appwriteDatabaseId,
            collectionId: AppConfig.couriersCollection,
            documentId: courier.id,
            data: courier.toJson(),
          );
        } catch (createError) {
          // If create with full fields fails (schema mismatch), try with basic fields
          await _databases.createDocument(
            databaseId: AppConfig.appwriteDatabaseId,
            collectionId: AppConfig.couriersCollection,
            documentId: courier.id,
            data: courier.toJsonBasic(),
          );
        }
      }
      return courier;
    } catch (e) {
      rethrow;
    }
  }

  Future<CourierModel> updateCourierProfile(CourierModel courier) async {
    try {
      try {
        if (courier.name.isNotEmpty) {
          await _account.updateName(name: courier.name);
        }
      } catch (_) {
        // Account update might require specific auth type, but proceed to database
      }
      return await saveCourierToDatabase(courier);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } catch (e) {
      // Session may already be invalid
    }
  }
}
