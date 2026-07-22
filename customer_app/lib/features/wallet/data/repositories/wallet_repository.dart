import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/wallet_model.dart';
import '../../domain/models/escrow_model.dart';
import '../../domain/models/topup_transaction_model.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final authState = ref.watch(authStateProvider);
  return WalletRepository(db, authState.user?.id);
});

class WalletRepository {
  final DatabaseService _db;
  final String? _userId;

  WalletRepository(this._db, this._userId);

  // ─── Wallet ───

  Future<WalletModel> getWallet() async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _db.getWallet(_userId);
    if (doc != null) {
      return WalletModel.fromJson(doc);
    }

    // First time — create wallet with zero balance
    final now = DateTime.now();
    final newWallet = WalletModel(
      userId: _userId,
      balance: 0,
      totalTopUp: 0,
      totalSpent: 0,
      createdAt: now,
      updatedAt: now,
    );

    await _db.createWallet(userId: _userId, data: newWallet.toJson());
    return newWallet;
  }

  Future<double> getBalance() async {
    final wallet = await getWallet();
    return wallet.balance;
  }

  // ─── Top Up ───

  /// Record a successful top-up: update wallet balance + save transaction.
  Future<void> confirmTopUp({
    required String transactionId,
    required double amount,
    required String paymentMethod,
    required String pakasirOrderId,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    // Get current wallet to compute new values
    final wallet = await getWallet();
    final now = DateTime.now();
    final newBalance = wallet.balance + amount;
    final newTotalTopUp = wallet.totalTopUp + amount;

    // Update wallet
    await _db.updateWallet(
      userId: _userId,
      data: {
        'balance': newBalance,
        'totalTopUp': newTotalTopUp,
        'updatedAt': now.toIso8601String(),
      },
    );

    // Update topup transaction status to success
    await _db.updateTopUpTransaction(
      transactionId: transactionId,
      data: {
        'status': 'success',
        'completedAt': now.toIso8601String(),
      },
    );
  }

  /// Create a pending top-up transaction (called before going to Pakasir).
  Future<TopUpTransactionModel> createPendingTopUp({
    required double amount,
    required String paymentMethod,
    required String pakasirOrderId,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final id = 'tp_${const Uuid().v4().substring(0, 24)}';
    final txn = TopUpTransactionModel(
      id: id,
      userId: _userId,
      amount: amount,
      paymentMethod: paymentMethod,
      pakasirOrderId: pakasirOrderId,
      status: TopUpStatus.pending,
      createdAt: DateTime.now(),
    );

    final data = txn.toJson();
    data.remove('\$id');
    await _db.createTopUpTransaction(transactionId: id, data: data);
    return txn;
  }

  /// Mark a top-up as failed.
  Future<void> failTopUp(String transactionId) async {
    await _db.updateTopUpTransaction(
      transactionId: transactionId,
      data: {'status': 'failed'},
    );
  }

  // ─── Deduct + Escrow ───

  /// Deduct from wallet and hold in escrow.
  /// [amount] = total (danaBelanja + ongkir + biayaLayanan)
  /// Returns the escrow id.
  Future<String> deductAndEscrow({
    required String orderId,
    required double amount,
    required String serviceType,
    double danaBelanja = 0,
    double ongkir = 0,
    double biayaLayanan = 0,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final wallet = await getWallet();
    if (wallet.balance < amount) {
      throw InsufficientBalanceException(
          wallet.balance, amount);
    }

    // Deduct from wallet
    final now = DateTime.now();
    final newBalance = wallet.balance - amount;
    final newTotalSpent = wallet.totalSpent + amount;

    await _db.updateWallet(
      userId: _userId,
      data: {
        'balance': newBalance,
        'totalSpent': newTotalSpent,
        'updatedAt': now.toIso8601String(),
      },
    );

    // Create escrow with breakdown
    final escrowId = 'es_${const Uuid().v4().substring(0, 24)}';
    final escrow = EscrowModel(
      id: escrowId,
      orderId: orderId,
      userId: _userId,
      amount: amount,
      status: EscrowStatus.held,
      serviceType: serviceType,
      createdAt: now,
      danaBelanja: danaBelanja,
      ongkir: ongkir,
      biayaLayanan: biayaLayanan,
    );

    final escrowData = escrow.toJson();
    escrowData.remove('\$id');
    await _db.createEscrow(escrowId: escrowId, data: escrowData);

    return escrowId;
  }

  // ─── Escrow Release / Refund ───

  /// Release escrow to merchant/courier when order completed.
  /// In the full system, this would credit the courier's wallet.
  Future<void> releaseEscrow(String escrowId) async {
    final now = DateTime.now();
    await _db.updateEscrow(
      escrowId: escrowId,
      data: {
        'status': 'released',
        'releasedAt': now.toIso8601String(),
      },
    );
  }

  /// Refund escrow back to user wallet when order cancelled.
  Future<void> refundEscrow(String escrowId) async {
    if (_userId == null) throw Exception('User not authenticated');

    // Get current escrow
    final escrows = await _db.getUserEscrows(_userId);
    final escrowDoc = escrows.firstWhere(
      (e) => e['\$id'] == escrowId,
      orElse: () => throw Exception('Escrow not found'),
    );
    final escrow = EscrowModel.fromJson(escrowDoc);

    if (escrow.status != EscrowStatus.held) {
      throw Exception('Can only refund held escrow');
    }

    // Return money to wallet
    final wallet = await getWallet();
    final now = DateTime.now();
    await _db.updateWallet(
      userId: _userId,
      data: {
        'balance': wallet.balance + escrow.amount,
        'totalSpent': (wallet.totalSpent - escrow.amount).clamp(0, double.infinity),
        'updatedAt': now.toIso8601String(),
      },
    );

    // Update escrow status
    await _db.updateEscrow(
      escrowId: escrowId,
      data: {
        'status': 'refunded',
        'releasedAt': now.toIso8601String(),
      },
    );
  }

  /// Partial refund: refund sebagian dari escrow ke customer (misal selisih belanja).
  /// Ini dipakai setelah settlement — refund sisa dana, sisanya release.
  Future<void> partialRefund({
    required String escrowId,
    required double refundAmount,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final escrows = await _db.getUserEscrows(_userId);
    final escrowDoc = escrows.firstWhere(
      (e) => e['\$id'] == escrowId,
      orElse: () => throw Exception('Escrow not found'),
    );
    final escrow = EscrowModel.fromJson(escrowDoc);

    if (escrow.status != EscrowStatus.held) {
      throw Exception('Can only refund held escrow');
    }

    final wallet = await getWallet();
    final now = DateTime.now();

    // Refund ke customer
    await _db.updateWallet(
      userId: _userId,
      data: {
        'balance': wallet.balance + refundAmount,
        'totalSpent': (wallet.totalSpent - refundAmount).clamp(0, double.infinity),
        'updatedAt': now.toIso8601String(),
      },
    );

    // Release escrow
    await _db.updateEscrow(
      escrowId: escrowId,
      data: {
        'status': 'released',
        'releasedAt': now.toIso8601String(),
      },
    );
  }

  // ─── History ───

  Future<List<EscrowModel>> getEscrowHistory() async {
    if (_userId == null) return [];
    final docs = await _db.getUserEscrows(_userId);
    return docs.map((d) => EscrowModel.fromJson(d)).toList();
  }

  Future<List<TopUpTransactionModel>> getTopUpHistory() async {
    if (_userId == null) return [];
    final docs = await _db.getUserTopUpTransactions(_userId);
    return docs.map((d) => TopUpTransactionModel.fromJson(d)).toList();
  }
}

class InsufficientBalanceException implements Exception {
  final double currentBalance;
  final double requiredAmount;

  const InsufficientBalanceException(this.currentBalance, this.requiredAmount);

  @override
  String toString() =>
      'Saldo tidak cukup. Saldo Anda: Rp ${currentBalance.toStringAsFixed(0)}, '
      'Dibutuhkan: Rp ${requiredAmount.toStringAsFixed(0)}';
}
