import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'appwrite_client.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(appwriteStorageProvider));
});

class StorageService {
  final Storage _storage;

  StorageService(this._storage);

  /// Upload a file to Appwrite Storage
  Future<String?> uploadFile({
    required String filePath,
    required String fileName,
  }) async {
    try {
      final file = InputFile.fromPath(path: filePath, filename: fileName);
      final result = await _storage.createFile(
        bucketId: AppConfig.storageBucketId,
        fileId: ID.unique(),
        file: file,
      );
      // Return the file ID or view URL
      return result.$id;
    } catch (e) {
      return null;
    }
  }

  /// Get the download URL for a file
  Future<String> getFileUrl(String fileId) async {
    return '${AppConfig.appwriteEndpoint}/storage/buckets/${AppConfig.storageBucketId}/files/$fileId/view?project=${AppConfig.appwriteProjectId}';
  }

  /// Upload a profile photo
  Future<String?> uploadProfilePhoto({
    required String userId,
    required String imagePath,
  }) async {
    final fileId = await uploadFile(
      filePath: imagePath,
      fileName: 'profile_$userId.jpg',
    );
    return fileId;
  }

  /// Upload an order item photo
  Future<String?> uploadOrderPhoto({
    required String orderId,
    required String imagePath,
  }) async {
    final fileId = await uploadFile(
      filePath: imagePath,
      fileName: 'order_$orderId.jpg',
    );
    return fileId;
  }

  /// Delete a file from storage
  Future<void> deleteFile(String fileId) async {
    try {
      await _storage.deleteFile(
        bucketId: AppConfig.storageBucketId,
        fileId: fileId,
      );
    } catch (e) {
      // File may not exist
    }
  }
}
