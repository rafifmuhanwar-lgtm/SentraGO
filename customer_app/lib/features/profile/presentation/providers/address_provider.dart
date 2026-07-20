import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/address_model.dart';

final savedAddressesProvider =
    NotifierProvider<SavedAddressesNotifier, List<AddressModel>>(() {
  return SavedAddressesNotifier();
});

class SavedAddressesNotifier extends Notifier<List<AddressModel>> {
  @override
  List<AddressModel> build() {
    return [
      const AddressModel(
        id: 'addr_1',
        label: 'Rumah',
        recipientName: 'Budi Santoso',
        phone: '081234567890',
        fullAddress: 'Jl. Ahmad Yani No. 12, Bekasi Barat, Kota Bekasi, Jawa Barat 17144',
        details: 'Pagar hitam di sebelah minimarket, ketuk pintu depan.',
        isPrimary: true,
      ),
      const AddressModel(
        id: 'addr_2',
        label: 'Kantor',
        recipientName: 'Budi Santoso',
        phone: '081234567890',
        fullAddress: 'Gedung Sentra Niaga Lt. 4, Jl. KH. Noer Ali, Pekayon Jaya, Bekasi Selatan',
        details: 'Titipkan di resepsionis lobi utama.',
        isPrimary: false,
      ),
    ];
  }

  void addAddress(AddressModel address) {
    if (address.isPrimary || state.isEmpty) {
      // Jika alamat baru dijadikan utama, jadikan yang lain false
      final updatedList = state
          .map((a) => a.copyWith(isPrimary: false))
          .toList();
      state = [
        ...updatedList,
        address.copyWith(isPrimary: true, id: DateTime.now().millisecondsSinceEpoch.toString()),
      ];
    } else {
      state = [
        ...state,
        address.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString()),
      ];
    }
  }

  void updateAddress(AddressModel address) {
    if (address.isPrimary) {
      state = state.map((a) {
        if (a.id == address.id) {
          return address.copyWith(isPrimary: true);
        }
        return a.copyWith(isPrimary: false);
      }).toList();
    } else {
      state = state.map((a) {
        if (a.id == address.id) {
          return address;
        }
        return a;
      }).toList();
    }
  }

  void deleteAddress(String id) {
    final deletedWasPrimary = state.any((a) => a.id == id && a.isPrimary);
    final remaining = state.where((a) => a.id != id).toList();

    if (deletedWasPrimary && remaining.isNotEmpty) {
      // Jadikan item pertama sebagai utama jika yang utama dihapus
      state = [
        remaining.first.copyWith(isPrimary: true),
        ...remaining.skip(1),
      ];
    } else {
      state = remaining;
    }
  }

  void setPrimaryAddress(String id) {
    state = state.map((a) {
      return a.copyWith(isPrimary: a.id == id);
    }).toList();
  }
}
