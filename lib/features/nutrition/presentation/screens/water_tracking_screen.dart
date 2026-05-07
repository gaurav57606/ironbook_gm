import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/constants/app_colors.dart';
import 'package:ironbook_gm/core/constants/app_text_styles.dart';
import 'package:ironbook_gm/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:ironbook_gm/shared/widgets/status_bar_wrapper.dart';

class WaterTrackingScreen extends ConsumerWidget {
  final String memberId;
  const WaterTrackingScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nutritionProvider(memberId));
    final goal = state.plan?.waterGoalMl ?? 2000;
    final consumed = state.todaysWaterMl;
    final percent = consumed / goal;

    return StatusBarWrapper(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('WATER TRACKER', style: AppTextStyles.heroNumber.copyWith(fontSize: 18)),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildWaterCup(percent),
              const SizedBox(height: 48),
              Text(
                '$consumed / $goal ML',
                style: AppTextStyles.heroNumber.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                'DAILY PROGRESS',
                style: AppTextStyles.sectionTitle.copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 64),
              _buildQuickAddRow(ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterCup(double percent) {
    return Container(
      width: 120,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutSine,
            width: double.infinity,
            height: 200 * percent.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blueAccent.withValues(alpha: 0.6),
                  Colors.blue.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
          ),
          // Bubbles effect
          Positioned.fill(
            child: Icon(Icons.water_drop, color: Colors.white.withValues(alpha: 0.1), size: 48),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddRow(WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAddButton(ref, 250, '250ml', Icons.local_drink_rounded),
        const SizedBox(width: 24),
        _buildAddButton(ref, 500, '500ml', Icons.wine_bar_rounded),
      ],
    );
  }

  Widget _buildAddButton(WidgetRef ref, int ml, String label, IconData icon) {
    return GestureDetector(
      onTap: () => ref.read(nutritionProvider(memberId).notifier).logWater(ml),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.elevation1,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 28),
          ),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
