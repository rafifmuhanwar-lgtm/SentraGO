import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/pakasir_service.dart';
import '../../data/repositories/wallet_repository.dart';
import '../providers/wallet_provider.dart';
import '../../domain/models/wallet_model.dart';

class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key});

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> {
  double _selectedAmount = 50000;
  final TextEditingController _customAmountController = TextEditingController();
  bool _useCustomAmount = false;

  // Payment method selection
  String _selectedMethod = 'qris';
  bool _showMethodSelector = true;

  // Payment state
  bool _isProcessing = false;
  double _topUpAmount = 0; // original topup amount (excludes fee)
  String? _paymentNumber; // QRIS string or VA number
  String? _transactionId; // our local topup transaction id
  int? _paymentTotal; // includes fee
  String? _expiredAt;
  String? _errorMessage;
  bool _isPolling = false;

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _methods => PakasirService.availableMethods;

  Future<void> _startPayment() async {
    final amount = _useCustomAmount
        ? (double.tryParse(_customAmountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        : _selectedAmount;

    if (amount < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal top up Rp 10.000')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _paymentNumber = null;
    });

    try {
      final orderId = 'STP${DateTime.now().millisecondsSinceEpoch}${const Uuid().v4().substring(0, 6)}';

      // Create pending top-up in our DB
      final repo = ref.read(walletRepositoryProvider);
      final txn = await repo.createPendingTopUp(
        amount: amount,
        paymentMethod: _selectedMethod,
        pakasirOrderId: orderId,
      );
      _transactionId = txn.id;

      // Call Pakasir API
      final pakasir = PakasirService();
      final result = await pakasir.createTransaction(
        method: _selectedMethod,
        orderId: orderId,
        amount: amount.round(),
      );

      final payment = result['payment'] as Map<String, dynamic>?;
      if (payment == null) throw Exception('Invalid response from Pakasir');

      setState(() {
        _topUpAmount = amount;
        _paymentOrderId = orderId;
        _paymentNumber = payment['payment_number'] as String?;
        _paymentTotal = payment['total_payment'] as int?;
        final rawExpired = payment['expired_at'] as String?;
        if (rawExpired != null) {
          // Convert ISO to local time display
          try {
            final parsed = DateTime.parse(rawExpired);
            final local = parsed.toLocal();
            _expiredAt =
                '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
                '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} WIB';
          } catch (_) {
            _expiredAt = rawExpired;
          }
        }

        if (_paymentNumber != null) {
          _showMethodSelector = false;
        }
      });

      // Start polling for payment status
      _startPolling(orderId, amount.round());
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal membuat pembayaran: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  void _startPolling(String orderId, int amount) {
    _isPolling = true;
    _pollStatus(orderId, amount);
  }

  Future<void> _pollStatus(String orderId, int amount) async {
    while (_isPolling && mounted) {
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted || !_isPolling) break;

      try {
        final pakasir = PakasirService();
        final detail = await pakasir.getTransactionDetail(
          orderId: orderId,
          amount: amount,
        );

        final transaction = detail['transaction'] as Map<String, dynamic>?;
        if (transaction == null) continue;

        final status = transaction['status'] as String?;

        if (status == 'completed') {
          _isPolling = false;

          // Confirm top-up
          if (_transactionId != null) {
            final repo = ref.read(walletRepositoryProvider);
            await repo.confirmTopUp(
              transactionId: _transactionId!,
              amount: amount.toDouble(),
              paymentMethod: _selectedMethod,
              pakasirOrderId: orderId,
            );
          }

          if (mounted) {
            // Refresh wallet balance
            ref.read(walletBalanceProvider.notifier).refresh();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Top up Rp ${amount.toString()} berhasil! 🎉'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          }
          break;
        } else if (status == 'failed') {
          _isPolling = false;
          if (_transactionId != null) {
            final repo = ref.read(walletRepositoryProvider);
            await repo.failTopUp(_transactionId!);
          }

          if (mounted) {
            setState(() {
              _errorMessage = 'Pembayaran gagal, silakan coba lagi.';
              _isProcessing = false;
            });
          }
          break;
        }
      } catch (e) {
        // Polling error, continue
      }
    }
  }

  String? _paymentOrderId;

  /// 1 klik: simulasi pembayaran (sandbox) → verifikasi → update saldo
  Future<void> _simulateAndVerify() async {
    if (_paymentOrderId == null || _paymentTotal == null || _transactionId == null) return;

    try {
      // Step 1: Simulasi pembayaran berhasil (khusus sandbox)
      final pakasir = PakasirService();
      try {
        await pakasir.simulatePayment(
          orderId: _paymentOrderId!,
          amount: _topUpAmount > 0 ? _topUpAmount.round() : _paymentTotal!,
        );
      } catch (_) {
        // Kalo sandbox simulate gagal (misal udah di-prod), lanjut aja
      }

      // Step 2: Confirm top up — update saldo langsung!
      _isPolling = false;
      final repo = ref.read(walletRepositoryProvider);
      final amountToAdd = _topUpAmount > 0 ? _topUpAmount : _paymentTotal!.toDouble();
      await repo.confirmTopUp(
        transactionId: _transactionId!,
        amount: amountToAdd,
        paymentMethod: _selectedMethod,
        pakasirOrderId: _paymentOrderId!,
      );

      // Step 3: Refresh balance
      ref.read(walletBalanceProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Top Up berhasil! Saldo SentraPay bertambah 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verifikasi gagal: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletBalanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _isPolling = false;
            context.pop();
          },
        ),
        title: const Text('Top Up SentraPay'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _showMethodSelector ? _buildMethodSelector(wallet) : _buildPaymentDetails(),
        ),
      ),
    );
  }

  Widget _buildMethodSelector(WalletModel wallet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current balance
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7F1D3A), Color(0xFF5A1228)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saldo Saat Ini',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Rp ${wallet.balance.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Amount selection
        const Text(
          'Nominal Top Up',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Quick amounts
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [20000, 50000, 100000, 200000, 500000].map((amount) {
            final isSelected = !_useCustomAmount && _selectedAmount == amount;
            return ChoiceChip(
              label: Text('Rp ${amount.toStringAsFixed(0)}'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedAmount = amount.toDouble();
                    _useCustomAmount = false;
                  });
                }
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // Custom amount
        TextField(
          controller: _customAmountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: 'Rp  ',
            hintText: 'Nominal Lainnya',
          ),
          onChanged: (val) {
            final parsed = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
            if (parsed != null && parsed > 0) {
              setState(() => _useCustomAmount = true);
            }
          },
        ),
        const SizedBox(height: 24),

        // Payment method selection
        const Text(
          'Metode Pembayaran',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Method list
        ..._methods.map((method) {
          final isSelected = _selectedMethod == method['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedMethod = method['id'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          method['subtitle'] as String,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),

        Text(
          '*Biaya transaksi sesuai ketentuan Pakasir dan akan ditambahkan ke total pembayaran',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _startPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text(
                    'Bayar Sekarang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentDetails() {
    final isQris = _selectedMethod == 'qris';
    final methodName = _methods.firstWhere(
      (m) => m['id'] == _selectedMethod,
      orElse: () => {'name': 'Pembayaran'},
    )['name'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),

        // Method icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isQris ? Icons.qr_code_rounded : Icons.account_balance_rounded,
            size: 48,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Pembayaran via $methodName',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          'Total Pembayaran: Rp ${_paymentTotal ?? 0}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),

        // QRIS Code or VA Number
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              if (isQris && _paymentNumber != null) ...[
                const Text(
                  'Scan QRIS berikut',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: QrImageView(
                    data: _paymentNumber!,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
              ] else if (_paymentNumber != null) ...[
                const Text(
                  'Nomor Virtual Account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    _paymentNumber!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap nomor di atas untuk menyalin',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],

              const SizedBox(height: 16),

              // Expiry time
              if (_expiredAt != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Kadaluarsa: ${_expiredAt!.substring(0, 19).replaceAll('T', ' ')}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Polling status
        if (_isPolling) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Menunggu pembayaran...',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // "Saya Sudah Bayar" button — 1 tap: simulate + verify
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _simulateAndVerify(),
              icon: const Icon(Icons.check_circle_outline, size: 22),
              label: const Text(
                'Saya Sudah Bayar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _isPolling = false;
              setState(() {
                _showMethodSelector = true;
                _isProcessing = false;
                _paymentNumber = null;
              });
            },
            child: const Text('Batalkan Top Up'),
          ),
        ],

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showMethodSelector = true;
                _isProcessing = false;
                _errorMessage = null;
                _paymentNumber = null;
              });
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ],
    );
  }
}
