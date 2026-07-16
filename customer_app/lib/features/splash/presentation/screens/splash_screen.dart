import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  Offset _slideOffset = const Offset(0, 0.2);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
          _slideOffset = Offset.zero;
        });
      }
    });
    // Simulate initial loading or initialization
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        // Navigate to the next screen later (LocationSelection)
        // Navigate to Login after delay
        context.go('/location');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            
            // Sentra Logo
            Center(
              child: Column(
                children: [
                  // Custom Shopping Bag Logo
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bag Handle
                      Container(
                        width: 34,
                        height: 16,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.surface, width: 4.5),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                      ),
                      // Bag Body
                      Container(
                        width: 76,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'S',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sentra',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(flex: 1),
            
            // Illustration Area
            Expanded(
              flex: 5,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                opacity: _opacity,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 800),
                  offset: _slideOffset,
                  curve: Curves.easeOut,
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                        stops: [0.0, 0.1, 0.9, 1.0],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Transform.scale(
                      scale: 1.35,
                      child: Image.asset(
                        'assets/images/courier_scooter.png',
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Bantuin semua kebutuhanmu,\ndari jastip sampai jasa suruh.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textLight,
                      height: 1.5,
                    ),
              ),
            ),
            
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 8 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.textLight : AppColors.textLight.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}
