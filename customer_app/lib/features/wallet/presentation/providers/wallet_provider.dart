import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/wallet_model.dart';
import '../../domain/models/escrow_model.dart';
import '../../domain/models/topup_transaction_model.dart';
import '../../data/repositories/wallet_repository.dart';

// ─── Wallet Balance Provider ───

final walletBalanceProvider =
    NotifierProvider<WalletBalanceNotifier, WalletModel>(() {
  return WalletBalanceNotifier();
});

class WalletBalanceNotifier extends Notifier<WalletModel> {
  @override
  WalletModel build() {
    Future.microtask(() => loadWallet());
    return WalletModel(
      userId: '',
      balance: 0,
      totalTopUp: 0,
      totalSpent: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> loadWallet() async {
    try {
      final repo = ref.read(walletRepositoryProvider);
      final wallet = await repo.getWallet();
      state = wallet;
    } catch (e) {
      // Keep current state on error
    }
  }

  Future<void> refresh() => loadWallet();
}

// ─── Escrow History Provider ───

final escrowHistoryProvider =
    FutureProvider<List<EscrowModel>>((ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getEscrowHistory();
});

// ─── Top-Up History Provider ───

final topUpHistoryProvider =
    FutureProvider<List<TopUpTransactionModel>>((ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getTopUpHistory();
});
