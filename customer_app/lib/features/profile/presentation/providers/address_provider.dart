import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/address_model.dart';
import 'package:uuid/uuid.dart';

final savedAddressesProvider =
    NotifierProvider<SavedAddressesNotifier, List<AddressModel>>(() {
  return SavedAddressesNotifier();
});

class SavedAddressesNotifier extends Notifier<List<AddressModel>> {
  @override
  List<AddressModel> build() {
    Future.microtask(() => loadAddresses());
    return [];
  }

  Future<void> loadAddresses() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    final db = ref.read(databaseServiceProvider);
    final docs = await db.getUserAddresses(userId);
    if (docs.isEmpty) {
      // Mock data if empty
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
    } else {
      state = docs.map((d) => AddressModel.fromJson(d)).toList();
    }
  }

  Future<void> addAddress(AddressModel address) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    final isFirst = state.isEmpty;
    final newAddress = address.copyWith(
      id: const Uuid().v4(),
      isPrimary: isFirst ? true : address.isPrimary,
    );

    final db = ref.read(databaseServiceProvider);
    final dataToSave = newAddress.toJson();
    dataToSave['userId'] = userId;
    dataToSave.remove('id'); // let appwrite handle it or we pass it as method param

    await db.saveAddress(newAddress.id, dataToSave);

    if (newAddress.isPrimary) {
      // Need to demote others
      for (var a in state) {
        if (a.isPrimary) {
          final updated = a.copyWith(isPrimary: false);
          final oldData = updated.toJson();
          oldData['userId'] = userId;
          oldData.remove('\$id');
          await db.saveAddress(a.id, oldData);
        }
      }
    }

    await loadAddresses();
  }

  Future<void> updateAddress(AddressModel address) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    final db = ref.read(databaseServiceProvider);
    
    if (address.isPrimary) {
      for (var a in state) {
        if (a.isPrimary && a.id != address.id) {
          final updated = a.copyWith(isPrimary: false);
          final oldData = updated.toJson();
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
    
    await loadAddresses();
  }

  Future<void> deleteAddress(String id) async {
    final db = ref.read(databaseServiceProvider);
    await db.deleteAddress(id);
    
    // Check if we need to promote another to primary
    final deletedWasPrimary = state.any((a) => a.id == id && a.isPrimary);
    await loadAddresses(); // reload first
    
    if (deletedWasPrimary && state.isNotEmpty) {
      final newPrimary = state.first.copyWith(isPrimary: true);
      await updateAddress(newPrimary);
    }
  }

  Future<void> setPrimaryAddress(String id) async {
    final target = state.firstWhere((a) => a.id == id);
    if (!target.isPrimary) {
      await updateAddress(target.copyWith(isPrimary: true));
    }
  }
}
