import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/payment_method_model.dart';

final paymentMethodsProvider =
    NotifierProvider<PaymentMethodsNotifier, List<PaymentMethodModel>>(() {
  return PaymentMethodsNotifier();
});

class PaymentMethodsNotifier extends Notifier<List<PaymentMethodModel>> {
  final List<PaymentMethodModel> _availableMethods = [
    const PaymentMethodModel(
      id: 'sentrapay',
      name: 'SentraPay Wallet',
      type: 'wallet',
      balance: 150000.0,
      isLinked: true,
      isDefault: true,
    ),
    const PaymentMethodModel(id: 'gopay', name: 'GoPay', type: 'ewallet', isLinked: false, isDefault: false),
    const PaymentMethodModel(id: 'ovo', name: 'OVO', type: 'ewallet', isLinked: false, isDefault: false),
    const PaymentMethodModel(id: 'dana', name: 'DANA', type: 'ewallet', isLinked: false, isDefault: false),
    const PaymentMethodModel(id: 'shopeepay', name: 'ShopeePay', type: 'ewallet', isLinked: false, isDefault: false),
    const PaymentMethodModel(id: 'bca_va', name: 'BCA Virtual Account', type: 'bank', isLinked: false, isDefault: false),
    const PaymentMethodModel(id: 'mandiri_va', name: 'Mandiri Virtual Account', type: 'bank', isLinked: false, isDefault: false),
    const PaymentMethodModel(id: 'cash', name: 'Tunai / COD', type: 'cash', isLinked: true, isDefault: false),
  ];

  @override
  List<PaymentMethodModel> build() {
    Future.microtask(() => loadPaymentMethods());
    return _availableMethods; // return initial list while loading
  }

  Future<void> loadPaymentMethods() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    final db = ref.read(databaseServiceProvider);
    final docs = await db.getUserPaymentMethods(userId);
    
    if (docs.isEmpty) {
      // First time, save SentraPay and Cash as defaults for this user
      for (var pm in _availableMethods.where((p) => p.isLinked)) {
        final data = pm.toJson();
        data['userId'] = userId;
        await db.savePaymentMethod(pm.id, data);
      }
      state = _availableMethods;
    } else {
      // Merge saved methods with available methods
      final savedMethods = docs.map((d) => PaymentMethodModel.fromJson(d)).toList();
      state = _availableMethods.map((avail) {
        try {
          return savedMethods.firstWhere((s) => s.id == avail.id);
        } catch (_) {
          return avail;
        }
      }).toList();
    }
  }

  Future<void> setDefaultPayment(String id) async {
    final target = state.firstWhere((a) => a.id == id);
    if (!target.isLinked) return;
    
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;
    final db = ref.read(databaseServiceProvider);

    for (var pm in state) {
      if (pm.isDefault && pm.id != id) {
        final updated = pm.copyWith(isDefault: false);
        final data = updated.toJson();
        data['userId'] = userId;
        await db.savePaymentMethod(pm.id, data);
      }
    }

    final newDefault = target.copyWith(isDefault: true);
    final data = newDefault.toJson();
    data['userId'] = userId;
    await db.savePaymentMethod(newDefault.id, data);

    await loadPaymentMethods();
  }

  Future<void> linkPaymentMethod(String id, String accountNumber) async {
    final target = state.firstWhere((a) => a.id == id);
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;
    
    final db = ref.read(databaseServiceProvider);
    final simBalance = target.type == 'ewallet' ? 50000.0 : null;
    
    final linked = target.copyWith(
      isLinked: true,
      accountNumber: accountNumber,
      balance: simBalance,
    );
    
    final data = linked.toJson();
    data['userId'] = userId;
    await db.savePaymentMethod(linked.id, data);
    
    await loadPaymentMethods();
  }

  Future<void> unlinkPaymentMethod(String id) async {
    final target = state.firstWhere((a) => a.id == id);
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;
    
    final db = ref.read(databaseServiceProvider);
    
    final unlinked = target.copyWith(
      isLinked: false,
      isDefault: false,
      accountNumber: null,
      balance: null,
    );
    
    // We could delete from DB or just update it
    await db.savePaymentMethod(unlinked.id, unlinked.toJson()..['userId'] = userId);
    
    if (target.isDefault) {
      final otherLinked = state.where((p) => p.isLinked && p.id != id).toList();
      if (otherLinked.isNotEmpty) {
        await setDefaultPayment(otherLinked.first.id);
      }
    } else {
      await loadPaymentMethods();
    }
  }

  Future<void> topUpBalance(String id, double amount) async {
    final target = state.firstWhere((a) => a.id == id);
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;
    
    final db = ref.read(databaseServiceProvider);
    
    final currentBal = target.balance ?? 0.0;
    final updated = target.copyWith(balance: currentBal + amount);
    
    final data = updated.toJson();
    data['userId'] = userId;
    await db.savePaymentMethod(updated.id, data);
    
    await loadPaymentMethods();
  }
}
