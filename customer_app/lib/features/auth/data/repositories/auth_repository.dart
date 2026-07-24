import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/appwrite_client.dart';
import '../models/user_model.dart';

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

  Future<UserModel?> getCurrentUser() async {
    try {
      final appwriteUser = await _account.get();
      Map<String, dynamic> userData = _mapAppwriteUser(appwriteUser);

      // Try to fetch additional user profile data from database
      try {
        final doc = await _databases.getDocument(
          databaseId: AppConfig.appwriteDatabaseId,
          collectionId: AppConfig.usersCollection,
          documentId: appwriteUser.$id,
        );
        final docData = doc.data;
        userData = {
          ...userData,
          'phone': docData['phone'] ?? userData['phone'],
          'photoUrl': docData['photoUrl'] ?? userData['photoUrl'],
          'selectedArea': docData['selectedArea'] ?? userData['selectedArea'],
        };
        if ((userData['name'] as String).isEmpty && docData['name'] != null) {
          userData['name'] = docData['name'];
        }
      } catch (e) {
        // Document does not exist yet for this new user -> create initial document in database
        final newUser = UserModel.fromJson(userData, appwriteUser.$id);
        try {
          await _databases.createDocument(
            databaseId: AppConfig.appwriteDatabaseId,
            collectionId: AppConfig.usersCollection,
            documentId: appwriteUser.$id,
            data: newUser.toJson(),
          );
        } catch (e) {
          debugPrint('getCurrentUser - Error creating user doc: $e');
          try {
            await _databases.createDocument(
              databaseId: AppConfig.appwriteDatabaseId,
              collectionId: AppConfig.usersCollection,
              documentId: appwriteUser.$id,
              data: newUser.toJsonBasic(),
            );
          } catch (e2) {
            debugPrint('getCurrentUser - Error creating basic user doc: $e2');
          }
        }
      }

      return UserModel.fromJson(userData, appwriteUser.$id);
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
    if (kIsWeb) {
      final currentOrigin = Uri.base.origin;
      await _account.createOAuth2Session(
        provider: OAuthProvider.google,
        success: '$currentOrigin/#/main',
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

  Future<UserModel> saveUserToDatabase(UserModel user) async {
    try {
      try {
        await _databases.getDocument(
          databaseId: AppConfig.appwriteDatabaseId,
          collectionId: AppConfig.usersCollection,
          documentId: user.id,
        );
        await _databases.updateDocument(
          databaseId: AppConfig.appwriteDatabaseId,
          collectionId: AppConfig.usersCollection,
          documentId: user.id,
          data: user.toJsonNonNull(),
        );
      } catch (e) {
        await _databases.createDocument(
          databaseId: AppConfig.appwriteDatabaseId,
          collectionId: AppConfig.usersCollection,
          documentId: user.id,
          data: user.toJson(),
        );
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> updateUserProfile(UserModel user) async {
    try {
      try {
        if (user.name.isNotEmpty) {
          await _account.updateName(name: user.name);
        }
      } catch (_) {
        // Account update might require specific auth type, but proceed to database
      }
      return await saveUserToDatabase(user);
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
