import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/courier_earnings_provider.dart';

class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  bool _isSubmitting = false;
  bool _isFormatting = false;
  String? _selectedBank;

  static const List<String> _bankList = [
    // ── Bank Konvensional ──
    'BCA (Bank Central Asia)',
    'Mandiri',
    'BRI (Bank Rakyat Indonesia)',
    'BNI (Bank Negara Indonesia)',
    'BSI (Bank Syariah Indonesia)',
    'BTN',
    'CIMB Niaga',
    'Danamon',
    'Permata',
    'Maybank',
    'Panin Bank',
    'OCBC NISP',
    'UOB Indonesia',
    'HSBC Indonesia',
    'Standard Chartered',
    // ── Bank Daerah ──
    'Bank Jago',
    'Bank Neo Commerce',
    'Bank BJB',
    'Bank DKI',
    'Bank Jatim',
    'Bank Jateng',
    'Bank Sumut',
    'Bank Kaltimtara',
    'Bank Sulselbar',
    'Bank NTB Syariah',
    'Bank Papua',
    'Bank Nagari',
    'Bank Aceh Syariah',
    'Bank Riau Kepri',
    // ── Bank Digital ──
    'Bank Digital BCA (Blu)',
    'Jenius (Bank BTPN)',
    'Bank Saqu',
    'Digibank (DBS)',
    'Motion Banking (Bank Danamon)',
    'Line Bank',
    'SeaBank',
    'Krom Bank',
    'SuperBank',
    // ── E-Wallet ──
    'GoPay',
    'OVO',
    'DANA',
    'LinkAja',
    'ShopeePay',
    'iSaku',
    'Paytren',
  ];

  @override
  void initState() {
    super.initState();
    // Format rupiah otomatis saat user mengetik
    _amountController.addListener(() {
      if (_isFormatting) return;
      _isFormatting = true;

      final text = _amountController.text;
      // Hapus semua karakter non-digit
      final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) {
        _amountController.text = '';
      } else {
        final number = int.parse(digits);
        // Format dengan titik
        final formatted = number.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)}.',
        );
        // Set cursor di akhir
        final pos = formatted.length;
        _amountController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: pos),
        );
      }

      _isFormatting = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose(); // masih dipake fallback
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitWithdrawal(double maxSaldo) async {
    if (!_formKey.currentState!.validate()) return;
    
    final amount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal tidak valid')),
      );
      return;
    }

    if (amount > maxSaldo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saldo tidak mencukupi')),
      );
      return;
    }

    if (amount < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal penarikan adalah Rp 10.000')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final courier = ref.read(authStateProvider).courier;
      if (courier == null) throw Exception('Kurir tidak ditemukan');

      final dbService = ref.read(databaseServiceProvider);
      await dbService.createWithdrawal({
        'courierId': courier.id,
        'amount': amount,
        'bankName': _selectedBank ?? _bankNameController.text.trim(),
        'accountNumber': _accountNumberController.text.trim(),
        'status': 'pending',
      });

      // Refresh saldo
      ref.invalidate(courierEarningsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permintaan penarikan berhasil dikirim'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal melakukan penarikan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final earningsAsync = ref.watch(courierEarningsProvider);
    final maxSaldo = earningsAsync.when(
      data: (d) => d.saldo,
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tarik Saldo',
          style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saldo Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Tersedia',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    earningsAsync.when(
                      data: (data) {
                        final formatted = data.saldo.toInt().toString().replaceAllMapped(
                          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                          (match) => '${match.group(1)}.',
                        );
                        return Text(
                          'Rp$formatted',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                      loading: () => const CircularProgressIndicator(color: Colors.white),
                      error: (e, _) => Text(
                        'Error',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'Informasi Penarikan',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nominal Penarikan',
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Masukkan nominal';
                  final number = int.tryParse(val.replaceAll('.', ''));
                  if (number == null || number <= 0) return 'Nominal tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedBank,
                decoration: InputDecoration(
                  labelText: 'Bank / E-Wallet',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                hint: const Text('Pilih bank atau e-wallet'),
                isExpanded: true,
                items: _bankList.map((bank) {
                  final isEwallet = ['GoPay', 'OVO', 'DANA', 'LinkAja', 'ShopeePay', 'iSaku', 'Paytren'].contains(bank);
                  final isDigital = ['Blu', 'Jenius', 'Saqu', 'Digibank', 'Motion', 'Line Bank', 'SeaBank', 'Krom', 'SuperBank'].any((k) => bank.contains(k));
                  String prefix;
                  if (isEwallet) prefix = '📱 ';
                  else if (isDigital) prefix = '💳 ';
                  else prefix = '🏦 ';
                  return DropdownMenuItem(
                    value: bank,
                    child: Text('$prefix$bank', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedBank = val);
                },
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Pilih bank atau e-wallet';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nomor Rekening',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Masukkan nomor rekening';
                  return null;
                },
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submitWithdrawal(maxSaldo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Tarik Saldo Sekarang',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
