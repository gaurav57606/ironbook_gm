import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/colors.dart';
import '../../../../data/local/models/plan_model.dart';
import '../../../../data/local/models/plan_component_model.dart';
import '../../../../providers/plan_provider.dart';

class PlanManagementScreen extends ConsumerWidget {
  const PlanManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(planProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Subscription Plans', 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return _buildPlanCard(context, ref, plan);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orange,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showPlanDialog(context, ref),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, WidgetRef ref, Plan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan.name, 
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
              Text('₹${plan.totalPrice.toInt()}', 
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.orange)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${plan.durationMonths} Month${plan.durationMonths > 1 ? 's' : ''}', 
            style: const TextStyle(fontSize: 10, color: AppColors.text3)),
          const Divider(color: AppColors.border, height: 24),
          Wrap(
            spacing: 8,
            children: plan.components.map((c) => _buildComponentChip(c)).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _showPlanDialog(context, ref, plan: plan),
                child: const Text('Edit', style: TextStyle(fontSize: 11, color: AppColors.text2)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComponentChip(PlanComponent component) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg4,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text('${component.name} (₹${component.price.toInt()})', 
        style: const TextStyle(fontSize: 9, color: AppColors.text2)),
    );
  }

  void _showPlanDialog(BuildContext context, WidgetRef ref, {Plan? plan}) {
    final nameController = TextEditingController(text: plan?.name ?? '');
    final durationController = TextEditingController(text: plan?.durationMonths.toString() ?? '1');
    List<PlanComponent> components = plan != null 
        ? List.from(plan.components.map((c) => PlanComponent(id: c.id, name: c.name, price: c.price))) 
        : [PlanComponent(id: const Uuid().v4(), name: 'Base Access', price: 500)];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bg2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(plan == null ? 'New Plan' : 'Edit Plan', 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(labelText: 'Plan Name', labelStyle: TextStyle(color: AppColors.text3)),
                ),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(labelText: 'Duration (Months)', labelStyle: TextStyle(color: AppColors.text3)),
                ),
                const SizedBox(height: 20),
                const Text('Components', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text3)),
                ...components.map((c) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Expanded(child: Text(c.name, style: const TextStyle(fontSize: 11, color: AppColors.text))),
                      Text('₹${c.price.toInt()}', style: const TextStyle(fontSize: 11, color: AppColors.text2)),
                    ],
                  ),
                )),
                TextButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      components.add(PlanComponent(id: const Uuid().v4(), name: 'Extra Item', price: 100));
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 14),
                  label: const Text('Add Component', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
              onPressed: () {
                final newPlan = Plan(
                  id: plan?.id ?? const Uuid().v4(),
                  name: nameController.text,
                  durationMonths: int.tryParse(durationController.text) ?? 1,
                  components: components,
                );
                if (plan == null) {
                  ref.read(planProvider.notifier).addPlan(newPlan);
                } else {
                  ref.read(planProvider.notifier).updatePlan(newPlan);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
