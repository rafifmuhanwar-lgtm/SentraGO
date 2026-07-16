import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<String> _otp = ['', '', '', ''];
  int _currentIndex = 0;

  void _onKeyTap(String value) {
    if (_currentIndex < 4) {
      setState(() {
        _otp[_currentIndex] = value;
        _currentIndex++;
      });

      // Auto-verify when 4 digits entered
      if (_currentIndex == 4) {
        _verify();
      }
    }
  }

  void _onBackspace() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _otp[_currentIndex] = '';
      });
    }
  }

  void _verify() async {
    final otpCode = _otp.join();
    final success = await ref.read(authStateProvider.notifier).verifyOtp(otpCode);
    if (success && mounted) {
      context.go('/main');
    } else if (mounted) {
      final error = ref.read(authStateProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'OTP Salah')));
      setState(() {
        _otp.fillRange(0, 4, '');
        _currentIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final phone = authState.phoneNumber ?? '';

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
                'Masukkan Kode OTP',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Kode telah dikirim ke\n+62 $phone',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 32),

              // OTP Display Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = _otp[index].isNotEmpty;
                  final isActive = index == _currentIndex;
                  return Container(
                    width: 56,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isFilled
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary
                            : isFilled
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : AppColors.border,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _otp[index],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Resend Timer
              if (authState.status == AuthStatus.loading)
                const Center(child: CircularProgressIndicator())
              else
                Center(
                  child: Text(
                    'Kirim ulang dalam 00:30',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ),

              const Spacer(),

              // Custom Number Pad
              _buildNumberPad(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('1', ''),
            _buildKeypadButton('2', 'ABC'),
            _buildKeypadButton('3', 'DEF'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('4', 'GHI'),
            _buildKeypadButton('5', 'JKL'),
            _buildKeypadButton('6', 'MNO'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('7', 'PQRS'),
            _buildKeypadButton('8', 'TUV'),
            _buildKeypadButton('9', 'WXYZ'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80, height: 64),
            _buildKeypadButton('0', ''),
            SizedBox(
              width: 80,
              height: 64,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onBackspace,
                  borderRadius: BorderRadius.circular(12),
                  child: const Center(
                    child: Icon(Icons.backspace_outlined, size: 24, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String number, String letters) {
    return SizedBox(
      width: 80,
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _onKeyTap(number);
          },
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (letters.isNotEmpty)
                  Text(
                    letters,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                      letterSpacing: 2,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
