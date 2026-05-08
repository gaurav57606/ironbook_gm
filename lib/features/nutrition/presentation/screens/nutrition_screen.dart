import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:ironbook_gm/features/nutrition/data/models/nutrition_plan_model.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/core/constants/app_colors.dart';
import 'package:ironbook_gm/shared/widgets/status_bar_wrapper.dart';
import 'package:ironbook_gm/features/nutrition/presentation/screens/meal_logging_screen.dart';
import 'package:ironbook_gm/features/nutrition/presentation/screens/water_tracking_screen.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(nutritionPlansProvider);

    return StatusBarWrapper(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Colors.green.withValues(alpha: 0.05),
                AppColors.bg,
                AppColors.bg,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: plansAsync.when(
                    data: (plans) => _buildContent(context, ref, plans),
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.orange)),
                    error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Nutrition Plans',
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
            child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.orange, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<NutritionPlan> plans) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        GestureDetector(
          onTap: () => _showAssignPlanDialog(context, ref),
          child: _buildQuickAction('Assign New Plan', Icons.add_task_rounded, Colors.blue),
        ),
        const SizedBox(height: 24),
        const Text('Active Clients', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        if (plans.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No active nutrition plans.', style: TextStyle(color: AppColors.text3, fontSize: 14)),
          )
        else
          ...plans.map((plan) {
            final member = ref.watch(memberProvider(plan.memberId));
            return _buildClientCard(context, member?.name ?? 'Unknown', plan.memberId, plan.planName, plan.dailyCalories, plan.adherence);
          }),
        const SizedBox(height: 24),
        const Text('Diet Distribution', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildDietStats(plans),
      ],
    );
  }

  void _showAssignPlanDialog(BuildContext context, WidgetRef ref) async {
    final members = ref.read(membersProvider);
    if (members.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No members found. Please add members first.')));
      }
      return;
    }

    String? selectedMemberId;
    String? selectedPlan = 'High Protein';
    final calorieController = TextEditingController(text: '2000 kcal');

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.bg2,
          title: const Text('Assign Nutrition Plan', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedMemberId,
                hint: const Text('Select Member', style: TextStyle(color: AppColors.text3)),
                dropdownColor: AppColors.bg2,
                isExpanded: true,
                items: members.map((m) => DropdownMenuItem(value: m.memberId, child: Text(m.name, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => setState(() => selectedMemberId = v),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedPlan,
                dropdownColor: AppColors.bg2,
                isExpanded: true,
                items: ['High Protein', 'Keto Diet', 'Vegan Plan', 'Maintenance'].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => setState(() => selectedPlan = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: calorieController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Target Calories', labelStyle: TextStyle(color: AppColors.text3)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedMemberId == null ? null : () async {
                await ref.read(nutritionRepositoryProvider).assignPlan(
                  memberId: selectedMemberId!,
                  planName: selectedPlan!,
                  dailyCalories: int.tryParse(calorieController.text) ?? 2000,
                );
                ref.invalidate(nutritionPlansProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, color: AppColors.text3),
        ],
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, String name, String memberId, String plan, int kcal, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.orange.withValues(alpha: 0.1),
                  child: Text(name[0], style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(plan, style: const TextStyle(color: AppColors.text3, fontSize: 10)),
                    ],
                  ),
                ),
                Text('$kcal kcal', style: const TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildCardAction(
                  context, 
                  'LOG MEAL', 
                  Icons.restaurant_rounded, 
                  Colors.orange,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (c) => MealLoggingScreen(memberId: memberId)
                  ))
                ),
                const SizedBox(width: 8),
                _buildCardAction(
                  context, 
                  'WATER', 
                  Icons.local_drink_rounded, 
                  Colors.blue,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (c) => WaterTrackingScreen(memberId: memberId)
                  ))
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDietStats(List<NutritionPlan> plans) {
    if (plans.isEmpty) return const SizedBox.shrink();

    final counts = <String, int>{};
    for (var p in plans) {
      counts[p.planName] = (counts[p.planName] ?? 0) + 1;
    }

    final total = plans.length;
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: sorted.take(3).map((e) {
        final colors = [Colors.blue, Colors.green, Colors.purple];
        final index = sorted.indexOf(e) % colors.length;
        return _buildDietCircle(e.key, e.value / total, colors[index]);
      }).toList(),
    );
  }

  Widget _buildDietCircle(String name, double percent, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            value: percent,
            strokeWidth: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(color: AppColors.text3, fontSize: 10)),
      ],
    );
  }
}
