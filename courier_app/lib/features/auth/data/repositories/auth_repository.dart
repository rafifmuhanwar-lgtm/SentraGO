import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter/foundation.dart';
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
      debugPrint('getCurrentCourier - Appwrite user found: ${appwriteUser.$id}, email: ${appwriteUser.email}');
      Map<String, dynamic> courierData = _mapAppwriteUser(appwriteUser);

      // Try to fetch additional courier profile data from database
      try {
        final doc = await _databases.getDocument(
          databaseId: AppConfig.appwriteDatabaseId,
          collectionId: AppConfig.couriersCollection,
          documentId: appwriteUser.$id,
        );
        final docData = doc.data;
        debugPrint('getCurrentCourier - DB doc found: $docData');
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
      } catch (e) {
        debugPrint('getCurrentCourier - DB doc fetch error (creating new courier doc): $e');
        final newCourier = CourierModel.fromJson(courierData, appwriteUser.$id);
        try {
          await _databases.createDocument(
            databaseId: AppConfig.appwriteDatabaseId,
            collectionId: AppConfig.couriersCollection,
            documentId: appwriteUser.$id,
            data: newCourier.toJson(),
          );
        } catch (e) {
          debugPrint('getCurrentCourier - Error creating courier doc: $e');
          try {
            await _databases.createDocument(
              databaseId: AppConfig.appwriteDatabaseId,
              collectionId: AppConfig.couriersCollection,
              documentId: appwriteUser.$id,
              data: newCourier.toJsonBasic(),
            );
          } catch (e2) {
            debugPrint('getCurrentCourier - Error creating basic courier doc: $e2');
          }
        }
      }

      final courier = CourierModel.fromJson(courierData, appwriteUser.$id);
      debugPrint('getCurrentCourier - Result: name=${courier.name}, vehicle=${courier.vehicleType}, area=${courier.selectedArea}, kyc=${courier.kycVerified}');
      return courier;
    } catch (e) {
      debugPrint('getCurrentCourier ERROR: $e');
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
    if (kIsWeb) {
      final currentOrigin = Uri.base.origin;
      await _account.createOAuth2Session(
        provider: OAuthProvider.google,
        success: '$currentOrigin/#/home',
        failure: '$currentOrigin/#/login',
      );
    } else {
      final callbackUrl = 'appwrite-callback-${AppConfig.appwriteProjectId}://';
      await _account.createOAuth2Session(
        provider: OAuthProvider.google,
        success: callbackUrl,
        failure: callbackUrl,
      );
    }
  }

  Future<void> signInWithEmail({required String email, required String password}) async {
    try {
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUpWithEmail({required String name, required String email, required String password}) async {
    try {
      // Clear any lingering session first just in case
      try {
        await _account.deleteSession(sessionId: 'current');
      } catch (_) {}

      await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      // Auto login after sign up
      await signInWithEmail(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<CourierModel> saveCourierToDatabase(CourierModel courier) async {
    try {
      bool docExists = false;
      try {
        await _databases.getDocument(
          databaseId: AppConfig.appwriteDatabaseId,
          collectionId: AppConfig.couriersCollection,
          documentId: courier.id,
        );
        docExists = true;
      } catch (_) {
        docExists = false;
      }

      if (docExists) {
        // Update: only send non-null fields to avoid overwriting existing profile data
        final updateData = courier.toJsonNonNull();
        debugPrint('saveCourierToDatabase - Updating existing doc with: $updateData');
        await _databases.updateDocument(
          databaseId: AppConfig.appwriteDatabaseId,
          collectionId: AppConfig.couriersCollection,
          documentId: courier.id,
          data: updateData,
        );
      } else {
        // Create new document
        debugPrint('saveCourierToDatabase - Creating new doc');
        try {
          await _databases.createDocument(
            databaseId: AppConfig.appwriteDatabaseId,
            collectionId: AppConfig.couriersCollection,
            documentId: courier.id,
            data: courier.toJson(),
          );
        } catch (createError) {
          // If create with full fields fails (schema mismatch), try with basic fields
          debugPrint('saveCourierToDatabase - Full create failed, trying basic: $createError');
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
