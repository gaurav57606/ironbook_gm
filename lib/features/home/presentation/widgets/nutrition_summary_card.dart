import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../nutrition/presentation/providers/nutrition_provider.dart';

class NutritionSummaryCard extends ConsumerWidget {
  const NutritionSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(nutritionPlansProvider);

    return plansAsync.when(
      data: (plans) {
        if (plans.isEmpty) return const SizedBox.shrink();

        final totalAdherence = plans.fold(0.0, (sum, p) => sum + p.adherence);
        final avgAdherence = (totalAdherence / plans.length) * 100;
        final activeTrackers = plans.length;

        return Container(
          margin: const EdgeInsets.only(top: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.elevation1,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NUTRITION OVERVIEW'.toUpperCase(),
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 8, color: AppColors.textMuted),
                  ),
                  const Icon(Icons.analytics_outlined, color: AppColors.orange, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatItem('ACTIVE CLIENTS', activeTrackers.toString(), Icons.people_outline),
                  const SizedBox(width: 32),
                  _buildStatItem('AVG ADHERENCE', '${avgAdherence.toInt()}%', Icons.check_circle_outline),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: avgAdherence / 100,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.sectionTitle.copyWith(fontSize: 7, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.cardTitle.copyWith(fontSize: 18, color: Colors.white)),
      ],
    );
  }
}
