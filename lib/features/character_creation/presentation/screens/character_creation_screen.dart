import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';

class CharacterCreationScreen extends StatelessWidget {
  const CharacterCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.orange.withValues(alpha: 0.15),
                AppColors.bg,
                AppColors.bg,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Character Creation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.bg2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.person_add_rounded, color: AppColors.orange, size: 20),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildCharacterSlot(
                        context,
                        'Iron Warrior',
                        'Level 42 Powerlifter',
                        Icons.shield_rounded,
                        true,
                      ),
                      const SizedBox(height: 16),
                      _buildCharacterSlot(
                        context,
                        'Agility Master',
                        'Empty Slot',
                        Icons.bolt_rounded,
                        false,
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Development Metrics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMetricRow('Strength', 0.85, AppColors.orange),
                      _buildMetricRow('Endurance', 0.65, Colors.blue),
                      _buildMetricRow('Dexterity', 0.45, Colors.green),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterSlot(BuildContext context, String title, String subtitle, IconData icon, bool active) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? AppColors.orange.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: active ? AppColors.orange.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: active ? AppColors.orange : AppColors.text3, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.text3,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.text3,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (active)
            const Icon(Icons.check_circle_rounded, color: AppColors.orange, size: 20)
          else
            const Icon(Icons.lock_outline_rounded, color: AppColors.text3, size: 20),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
              Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
