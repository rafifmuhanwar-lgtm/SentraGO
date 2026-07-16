import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen>
    with SingleTickerProviderStateMixin {
  String _selectedArea = 'Kota Bekasi';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          // ── Main Content Area (Burgundy) ──
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Cityscape Illustration at the bottom of burgundy area
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: ShaderMask(
                          shaderCallback: (rect) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.white,
                                Colors.white,
                              ],
                              stops: [0.0, 0.15, 1.0],
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.dstIn,
                          child: Image.asset(
                            'assets/images/monas_cityscape.png',
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Text & Options on top
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mau mulai di\narea mana?',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Pilih area untuk pengalaman\nyang lebih relevan.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textLight.withValues(alpha: 0.8),
                                height: 1.5,
                              ),
                        ),
                        const SizedBox(height: 32),

                        // Area Options
                        _buildAreaOption('Kota Bekasi'),
                        const SizedBox(height: 12),
                        _buildAreaOption('Kabupaten Bekasi'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Curved White Section (Lanjutkan button only) ──
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Lanjutkan'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaOption(String name) {
    final isSelected = _selectedArea == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedArea = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: AppColors.textLight,
                    fontSize: 17,
                  ),
            ),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: AppColors.primary, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
