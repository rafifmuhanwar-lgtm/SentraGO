import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nomor HP yang valid')),
      );
      return;
    }

    final success = await ref.read(authStateProvider.notifier).requestOtp(phone);
    if (success && mounted) {
      context.push('/otp');
    } else if (mounted) {
      final error = ref.read(authStateProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Masuk / Daftar',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan nomor HP kamu\nuntuk melanjutkan.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 32),

              // Phone Input
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: AppColors.border)),
                      ),
                      child: Text(
                        '+62',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '812-3456-7890',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Lanjutkan Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: authState.status == AuthStatus.loading ? null : _submit,
                  child: authState.status == AuthStatus.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Lanjutkan'),
                ),
              ),
              const SizedBox(height: 28),

              // Divider "atau lanjut dengan"
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'atau lanjut dengan',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 24),

              // Social Login Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(Icons.g_mobiledata_rounded, 'Google'),
                  const SizedBox(width: 16),
                  _buildSocialButton(Icons.apple, 'Apple'),
                ],
              ),

              const Spacer(),

              // Terms & Conditions
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall,
                      children: [
                        const TextSpan(text: 'Dengan melanjutkan, kamu menyetujui\n'),
                        TextSpan(
                          text: 'Syarat & Ketentuan',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const TextSpan(text: ' dan '),
                        TextSpan(
                          text: 'Kebijakan Privasi',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
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

  Widget _buildSocialButton(IconData icon, String label) {
    return Container(
      width: 72,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 28, color: AppColors.textPrimary),
    );
  }
}
