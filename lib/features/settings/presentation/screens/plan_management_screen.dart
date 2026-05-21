import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/data/local/models/plan_model.dart';
import '../../../../core/data/local/models/plan_component_model.dart';
import '../../../../core/providers/plan_provider.dart';

class PlanManagementScreen extends ConsumerWidget {
  const PlanManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(planProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Membership Plans',
          style: AppTextStyles.h3,
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 70, 20, 100),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            return _buildPlanCard(context, ref, plan);
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
          onPressed: () => _showPlanDialog(context, ref),
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, WidgetRef ref, Plan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.elevation1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _buildPlanCardHeader(plan),
            _buildPlanCardContent(context, ref, plan),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCardHeader(Plan plan) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.elevation2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: AppTextStyles.h3.copyWith(fontSize: 18),
              ),
              _buildPlanPrice(plan.totalPrice),
            ],
          ),
          const SizedBox(height: 8),
          _buildPlanDuration(plan.durationMonths),
        ],
      ),
    );
  }

  Widget _buildPlanPrice(double price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "₹${price.toInt()}",
        style: AppTextStyles.h3.copyWith(
          fontSize: 18,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPlanDuration(int months) {
    return Row(
      children: [
        const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          "$months Month${months > 1 ? "s" : ""}",
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildPlanCardContent(BuildContext context, WidgetRef ref, Plan plan) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "INCLUDED COMPONENTS",
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                plan.components.map((c) => _buildComponentChip(c)).toList(),
          ),
          const SizedBox(height: 24),
          _buildEditPlanAction(context, ref, plan),
        ],
      ),
    );
  }

  Widget _buildEditPlanAction(BuildContext context, WidgetRef ref, Plan plan) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: () => _showPlanDialog(context, ref, plan: plan),
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: Text("Edit Plan", style: AppTextStyles.buttonSmall),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        const SizedBox(width: 4),
        TextButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.elevation2,
                title: Text('Delete Plan?', style: AppTextStyles.cardTitle),
                content: Text(
                  'Delete "${plan.name}"? Members already on this plan are unaffected.',
                  style: AppTextStyles.bodySmall,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              ref.read(planProvider.notifier).deletePlan(plan.id);
            }
          },
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: Text("Delete", style: AppTextStyles.buttonSmall),
          style: TextButton.styleFrom(
            foregroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildComponentChip(PlanComponent component) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.elevation2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
          const SizedBox(width: 8),
          Text(
            "${component.name} (₹${component.price.toInt()})",
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showPlanDialog(BuildContext context, WidgetRef ref, {Plan? plan}) {
    final nameController = TextEditingController(text: plan?.name ?? "");
    final durationController =
        TextEditingController(text: plan?.durationMonths.toString() ?? "1");
    final priceController =
        TextEditingController(text: plan?.price.toInt().toString() ?? "500");
    List<PlanComponent> components = plan != null
        ? List.from(plan.components
            .map((c) => PlanComponent(id: c.id, name: c.name, price: c.price)))
        : [
            PlanComponent(
                id: const Uuid().v4(), name: "Base Access", price: 500)
          ];

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.elevation1,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            plan == null ? "Create New Plan" : "Edit Membership Plan",
            style: AppTextStyles.h3,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogField("Plan Name", nameController),
                const SizedBox(height: 16),
                _buildDialogField("Duration (Months)", durationController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildDialogField("Price (₹)", priceController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 32),
                Text(
                  "COMPONENTS",
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 10),
                ),
                const SizedBox(height: 12),
                ...components.asMap().entries.map(
                  (e) => _buildDialogComponentItem(
                      e.value, e.key, components, setDialogState),
                ).toList(),
                const SizedBox(height: 12),
                _buildAddComponentButton(() {
                  setDialogState(() {
                    components.add(PlanComponent(
                        id: const Uuid().v4(),
                        name: "New Service",
                        price: 100));
                  });
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
            ),
            _buildSavePlanButton(context, ref, plan, nameController,
                durationController, priceController, components),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogComponentItem(
    PlanComponent component,
    int index,
    List<PlanComponent> components,
    StateSetter setDialogState,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.elevation2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: component.name,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                decoration: const InputDecoration.collapsed(hintText: 'Component name'),
                onChanged: (val) => setDialogState(() {
                  components[index] = PlanComponent(
                      id: component.id, name: val, price: component.price);
                }),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 72,
              child: TextFormField(
                initialValue: component.price.toInt().toString(),
                keyboardType: TextInputType.number,
                style: AppTextStyles.body.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w800),
                decoration: const InputDecoration.collapsed(hintText: '₹0'),
                textAlign: TextAlign.right,
                onChanged: (val) => setDialogState(() {
                  components[index] = PlanComponent(
                      id: component.id,
                      name: component.name,
                      price: double.tryParse(val) ?? 0);
                }),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => setDialogState(() => components.removeAt(index)),
              child: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddComponentButton(VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
      label: const Text("Add Component"),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSavePlanButton(
    BuildContext context,
    WidgetRef ref,
    Plan? plan,
    TextEditingController nameController,
    TextEditingController durationController,
    TextEditingController priceController,
    List<PlanComponent> components,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () {
        final newPlan = Plan(
          id: plan?.id ?? const Uuid().v4(),
          name: nameController.text,
          durationMonths: int.tryParse(durationController.text) ?? 1,
          price: double.tryParse(priceController.text) ?? 0,
          components: components,
        );
        if (plan == null) {
          ref.read(planProvider.notifier).addPlan(newPlan);
        } else {
          ref.read(planProvider.notifier).updatePlan(newPlan);
        }
        Navigator.pop(context);
      },
      child: const Text("Save Plan",
          style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.elevation2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}









