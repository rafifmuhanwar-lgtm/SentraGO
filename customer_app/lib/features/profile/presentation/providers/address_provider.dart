import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/services/database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/address_model.dart';
import 'package:uuid/uuid.dart';

final savedAddressesProvider =
    NotifierProvider<SavedAddressesNotifier, List<AddressModel>>(() {
  return SavedAddressesNotifier();
});

class SavedAddressesNotifier extends Notifier<List<AddressModel>> {
  final _storage = const FlutterSecureStorage();
  bool _hasLoadedOnce = false;

  @override
  List<AddressModel> build() {
    Future.microtask(() => loadAddresses());
    return [];
  }

  String _getCacheKey(String? userId) => 'addresses_cache_${userId ?? "guest"}';

  Future<void> _saveToLocalCache(List<AddressModel> list) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    final jsonStr = jsonEncode(list.map((a) => a.toJson()..['id'] = a.id).toList());
    await _storage.write(key: _getCacheKey(userId), value: jsonStr);
  }

  Future<List<AddressModel>?> _loadFromLocalCache() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    final jsonStr = await _storage.read(key: _getCacheKey(userId));
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => AddressModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> loadAddresses() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    // First try loading from local cache for instant display
    final localCached = await _loadFromLocalCache();
    if (localCached != null) {
      state = localCached;
    }

    if (userId != null) {
      final db = ref.read(databaseServiceProvider);
      final docs = await db.getUserAddresses(userId);
      if (docs.isNotEmpty) {
        state = docs.map((d) => AddressModel.fromJson(d)).toList();
        _hasLoadedOnce = true;
        await _saveToLocalCache(state);
        return;
      }
    }

    // If both Appwrite and local storage are empty and we haven't initialized before
    if (state.isEmpty && !_hasLoadedOnce) {
      _hasLoadedOnce = true;
      state = [
        const AddressModel(
          id: 'addr_1',
          label: 'Rumah',
          recipientName: 'Budi Santoso',
          phone: '081234567890',
          fullAddress: 'Jl. Ahmad Yani No. 12, Bekasi Barat, Kota Bekasi, Jawa Barat 17144',
          details: 'Pagar hitam di sebelah minimarket, ketuk pintu depan.',
          isPrimary: true,
        ),
      ];
      await _saveToLocalCache(state);
    } else {
      _hasLoadedOnce = true;
    }
  }

  Future<void> addAddress(AddressModel address) async {
    final isFirst = state.isEmpty;
    final newAddress = address.copyWith(
      id: address.id.isEmpty ? const Uuid().v4() : address.id,
      isPrimary: isFirst ? true : address.isPrimary,
    );

    // 1. Optimistic UI update immediately
    List<AddressModel> updatedList = [...state];
    if (newAddress.isPrimary) {
      updatedList = updatedList.map((a) => a.copyWith(isPrimary: false)).toList();
    }
    state = [...updatedList, newAddress];
    _hasLoadedOnce = true;
    await _saveToLocalCache(state);

    // 2. Sync with Appwrite in background (unawaited so modal closes instantly)
    _syncAddToAppwrite(newAddress, updatedList);
  }

  void _syncAddToAppwrite(AddressModel newAddress, List<AddressModel> updatedList) {
    Future.microtask(() async {
      try {
        final authState = ref.read(authStateProvider);
        final userId = authState.user?.id;
        if (userId != null) {
          final db = ref.read(databaseServiceProvider);
          final dataToSave = newAddress.toJson();
          dataToSave['userId'] = userId;
          dataToSave.remove('id');
          await db.saveAddress(newAddress.id, dataToSave);

          if (newAddress.isPrimary) {
            for (var a in updatedList) {
              final oldData = a.toJson();
              oldData['userId'] = userId;
              oldData.remove('\$id');
              await db.saveAddress(a.id, oldData);
            }
          }
        }
      } catch (_) {}
    });
  }

  Future<void> updateAddress(AddressModel address) async {
    // 1. Optimistic UI update immediately
    List<AddressModel> updatedList = [...state];
    if (address.isPrimary) {
      updatedList = updatedList.map((a) => a.id == address.id ? address : a.copyWith(isPrimary: false)).toList();
    } else {
      updatedList = updatedList.map((a) => a.id == address.id ? address : a).toList();
    }
    state = updatedList;
    _hasLoadedOnce = true;
    await _saveToLocalCache(state);

    // 2. Sync with Appwrite in background (unawaited so modal closes instantly)
    _syncUpdateToAppwrite(address, updatedList);
  }

  void _syncUpdateToAppwrite(AddressModel address, List<AddressModel> updatedList) {
    Future.microtask(() async {
      try {
        final authState = ref.read(authStateProvider);
        final userId = authState.user?.id;
        if (userId != null) {
          final db = ref.read(databaseServiceProvider);
          if (address.isPrimary) {
            for (var a in updatedList) {
              if (a.id != address.id) {
                final oldData = a.toJson();
                oldData['userId'] = userId;
                oldData.remove('\$id');
                await db.saveAddress(a.id, oldData);
              }
            }
          }

          final dataToSave = address.toJson();
          dataToSave['userId'] = userId;
          dataToSave.remove('\$id');
          await db.saveAddress(address.id, dataToSave);
        }
      } catch (_) {}
    });
  }

  Future<void> deleteAddress(String id) async {
    // 1. Optimistic UI update immediately
    final deletedWasPrimary = state.any((a) => a.id == id && a.isPrimary);
    List<AddressModel> updatedList = state.where((a) => a.id != id).toList();

    if (deletedWasPrimary && updatedList.isNotEmpty) {
      updatedList = [
        updatedList.first.copyWith(isPrimary: true),
        ...updatedList.sublist(1),
      ];
    }
    state = updatedList;
    _hasLoadedOnce = true;
    await _saveToLocalCache(state);

    // 2. Sync with Appwrite in background (unawaited so modal closes instantly)
    _syncDeleteToAppwrite(id, deletedWasPrimary, updatedList);
  }

  void _syncDeleteToAppwrite(String id, bool deletedWasPrimary, List<AddressModel> updatedList) {
    Future.microtask(() async {
      try {
        final authState = ref.read(authStateProvider);
        final userId = authState.user?.id;
        if (userId != null) {
          final db = ref.read(databaseServiceProvider);
          await db.deleteAddress(id);
          if (deletedWasPrimary && updatedList.isNotEmpty) {
            final newPrimary = updatedList.first;
            final dataToSave = newPrimary.toJson();
            dataToSave['userId'] = userId;
            dataToSave.remove('\$id');
            await db.saveAddress(newPrimary.id, dataToSave);
          }
        }
      } catch (_) {}
    });
  }

  Future<void> setPrimaryAddress(String id) async {
    final target = state.firstWhere((a) => a.id == id);
    if (!target.isPrimary) {
      await updateAddress(target.copyWith(isPrimary: true));
    }
  }
}
