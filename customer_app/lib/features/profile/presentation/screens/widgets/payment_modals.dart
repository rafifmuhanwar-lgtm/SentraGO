import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../domain/models/payment_method_model.dart';
import '../../providers/payment_provider.dart';

class LinkPaymentModal extends ConsumerStatefulWidget {
  final PaymentMethodModel method;

  const LinkPaymentModal({super.key, required this.method});

  static Future<void> show(BuildContext context, PaymentMethodModel method) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LinkPaymentModal(method: method),
    );
  }

  @override
  ConsumerState<LinkPaymentModal> createState() => _LinkPaymentModalState();
}

class _LinkPaymentModalState extends ConsumerState<LinkPaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  void _link() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    ref.read(paymentMethodsProvider.notifier).linkPaymentMethod(
          widget.method.id,
          _accountController.text.trim(),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Akun ${widget.method.name} berhasil dihubungkan!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isBank = widget.method.type == 'bank';

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hubungkan ${widget.method.name}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isBank
                      ? 'Masukkan nomor rekening atau Virtual Account terdaftar.'
                      : 'Masukkan nomor HP yang terdaftar pada aplikasi ${widget.method.name}.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 24),

                // ── Input Account Number ──
                Text(
                  isBank ? 'Nomor Virtual Account' : 'Nomor HP Terdaftar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _accountController,
                  keyboardType: isBank ? TextInputType.number : TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: isBank ? 'Contoh: 88019283741092' : 'Contoh: 081234567890',
                    prefixIcon: Icon(
                      isBank ? Icons.account_balance_outlined : Icons.phone_android_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nomor tidak boleh kosong';
                    }
                    if (value.trim().length < 8) {
                      return 'Nomor terlalu pendek atau tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ── Button Hubungkan ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _link,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Hubungkan Sekarang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TopUpModal extends ConsumerStatefulWidget {
  final PaymentMethodModel wallet;

  const TopUpModal({super.key, required this.wallet});

  static Future<void> show(BuildContext context, PaymentMethodModel wallet) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TopUpModal(wallet: wallet),
    );
  }

  @override
  ConsumerState<TopUpModal> createState() => _TopUpModalState();
}

class _TopUpModalState extends ConsumerState<TopUpModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '50000');
  double _selectedChipAmount = 50000;
  bool _isLoading = false;

  final List<double> _quickAmounts = [20000, 50000, 100000, 250000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _topUp() {
    if (!_formKey.currentState!.validate()) return;

    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountStr) ?? 0.0;
    if (amount <= 0) return;

    setState(() => _isLoading = true);

    ref.read(paymentMethodsProvider.notifier).topUpBalance(widget.wallet.id, amount);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Top up Rp ${amount.toStringAsFixed(0)} ke ${widget.wallet.name} berhasil!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Top Up ${widget.wallet.name}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Saldo Saat Ini: Rp ${(widget.wallet.balance ?? 0).toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 24),

                // ── Pilih Nominal Cepat ──
                Text(
                  'Pilih Nominal Cepat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _quickAmounts.map((amt) {
                    final isSelected = _selectedChipAmount == amt;
                    return ChoiceChip(
                      label: Text('Rp ${amt.toStringAsFixed(0)}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedChipAmount = amt;
                            _amountController.text = amt.toStringAsFixed(0);
                          });
                        }
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.12),
                      backgroundColor: AppColors.background,
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
                const SizedBox(height: 20),

                // ── Input Nominal Manual ──
                Text(
                  'Atau Masukkan Nominal Lain',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: 'Rp  ',
                    hintText: 'Contoh: 75000',
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val) ?? 0;
                    setState(() {
                      if (_quickAmounts.contains(parsed)) {
                        _selectedChipAmount = parsed;
                      } else {
                        _selectedChipAmount = -1;
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nominal tidak boleh kosong';
                    }
                    final amt = double.tryParse(value) ?? 0;
                    if (amt < 10000) {
                      return 'Minimal top up Rp 10.000';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ── Button Top Up ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _topUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Top Up Sekarang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
