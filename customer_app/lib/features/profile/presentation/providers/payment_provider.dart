import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/payment_method_model.dart';

final paymentMethodsProvider =
    NotifierProvider<PaymentMethodsNotifier, List<PaymentMethodModel>>(() {
  return PaymentMethodsNotifier();
});

class PaymentMethodsNotifier extends Notifier<List<PaymentMethodModel>> {
  @override
  List<PaymentMethodModel> build() {
    return [
      const PaymentMethodModel(
        id: 'sentrapay',
        name: 'SentraPay Wallet',
        type: 'wallet',
        balance: 150000.0,
        isLinked: true,
        isDefault: true,
      ),
      const PaymentMethodModel(
        id: 'gopay',
        name: 'GoPay',
        type: 'ewallet',
        accountNumber: '081234567890',
        balance: 45000.0,
        isLinked: true,
        isDefault: false,
      ),
      const PaymentMethodModel(
        id: 'ovo',
        name: 'OVO',
        type: 'ewallet',
        isLinked: false,
        isDefault: false,
      ),
      const PaymentMethodModel(
        id: 'dana',
        name: 'DANA',
        type: 'ewallet',
        isLinked: false,
        isDefault: false,
      ),
      const PaymentMethodModel(
        id: 'shopeepay',
        name: 'ShopeePay',
        type: 'ewallet',
        isLinked: false,
        isDefault: false,
      ),
      const PaymentMethodModel(
        id: 'bca_va',
        name: 'BCA Virtual Account',
        type: 'bank',
        accountNumber: '88019283741092',
        isLinked: true,
        isDefault: false,
      ),
      const PaymentMethodModel(
        id: 'mandiri_va',
        name: 'Mandiri Virtual Account',
        type: 'bank',
        isLinked: false,
        isDefault: false,
      ),
      const PaymentMethodModel(
        id: 'cash',
        name: 'Tunai / COD',
        type: 'cash',
        isLinked: true,
        isDefault: false,
      ),
    ];
  }

  void setDefaultPayment(String id) {
    state = state.map((item) {
      if (item.id == id && item.isLinked) {
        return item.copyWith(isDefault: true);
      }
      return item.copyWith(isDefault: false);
    }).toList();
  }

  void linkPaymentMethod(String id, String accountNumber) {
    state = state.map((item) {
      if (item.id == id) {
        // Berikan saldo simulasi awal jika ewallet
        final simBalance = item.type == 'ewallet' ? 50000.0 : null;
        return item.copyWith(
          isLinked: true,
          accountNumber: accountNumber,
          balance: simBalance,
        );
      }
      return item;
    }).toList();
  }

  void unlinkPaymentMethod(String id) {
    final wasDefault = state.any((item) => item.id == id && item.isDefault);

    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(
          isLinked: false,
          isDefault: false,
          accountNumber: null,
          balance: null,
        );
      }
      return item;
    }).toList();

    // Jika yang diputuskan adalah default, jadikan SentraPay atau item pertama yang terhubung sebagai default
    if (wasDefault) {
      final linkedItems = state.where((item) => item.isLinked).toList();
      if (linkedItems.isNotEmpty) {
        final firstLinkedId = linkedItems.first.id;
        setDefaultPayment(firstLinkedId);
      }
    }
  }

  void topUpBalance(String id, double amount) {
    state = state.map((item) {
      if (item.id == id) {
        final currentBal = item.balance ?? 0.0;
        return item.copyWith(balance: currentBal + amount);
      }
      return item;
    }).toList();
  }
}
