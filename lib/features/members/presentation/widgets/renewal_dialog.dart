import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../core/data/local/models/member_snapshot_model.dart';
import '../../../../core/providers/payment_provider.dart';
import '../../../billing/providers/billing_provider.dart';
import '../../../../core/data/local/drift/outbox_database.dart' as db;
import '../../../../core/data/local/models/plan_model.dart' as model;
import '../../../../core/providers/base_providers.dart';
import '../../../../core/monitoring/monitoring_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RenewalDialog extends ConsumerStatefulWidget {
  final MemberSnapshot member;

  const RenewalDialog({super.key, required this.member});

  @override
  ConsumerState<RenewalDialog> createState() => _RenewalDialogState();
}

class _RenewalDialogState extends ConsumerState<RenewalDialog> {
  String? _selectedBasePlanName;
  int _selectedPlanIndex = 0;
  int _selectedPayment = 1;
  bool _isSaving = false;
  bool _isSuccess = false;

  static const _paymentMethods = ['Cash', 'UPI', 'Card', 'Bank'];

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(activePlansProvider);
    final membershipService = ref.watch(membershipServiceProvider);

    return Dialog(
      backgroundColor: AppColors.bg,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusXL,
          border: Border.all(color: AppColors.border),
        ),
        child: plansAsync.when(
          loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
          error: (e, s) => Text('Error: $e'),
          data: (plans) {
            if (plans.isEmpty) {
              return const Text('No active plans found.');
            }

            // Group plans by name
            final Map<String, List<db.Plan>> groupedPlans = {};
            for (var plan in plans) {
              groupedPlans.putIfAbsent(plan.name, () => []).add(plan);
            }
            final basePlanNames = groupedPlans.keys.toList();
            
            if (_selectedBasePlanName == null) {
              _selectedBasePlanName = basePlanNames.first;
            }

            final selectedBasePlans = groupedPlans[_selectedBasePlanName] ?? [];
            selectedBasePlans.sort((a, b) => a.durationMonths.compareTo(b.durationMonths));
            
            if (_selectedPlanIndex >= selectedBasePlans.length) {
              _selectedPlanIndex = 0;
            }

            final selectedPlan = selectedBasePlans[_selectedPlanIndex];
            final now = DateTime.now();
            final newExpiry = membershipService.calculateRenewal(
              currentExpiry: widget.member.expiryDate,
              durationMonths: selectedPlan.durationMonths,
              now: now,
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Renew Membership', style: AppTextStyles.cardTitle),
                AppSpacing.gapM,
                Text(
                  'Extending membership for ${widget.member.name}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                AppSpacing.gapL,
                
                const AppSectionHeader(title: 'Select Plan'),
                _buildPlanDropdown(basePlanNames),
                
                const AppSectionHeader(title: 'Duration'),
                _buildPlanChips(selectedBasePlans),
                
                AppSpacing.gapL,
                _buildSummary(selectedPlan, newExpiry),
                
                const AppSectionHeader(title: 'Payment Method'),
                _buildPaymentChips(),
                
                AppSpacing.gapXL,
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isSuccess
                      ? Container(
                          key: const ValueKey('success'),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: AppRadius.radiusL,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Renewed!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : AppButton(
                          key: const ValueKey('renew'),
                          text: _isSaving ? 'Processing...' : 'Confirm Renewal',
                          isLoading: _isSaving,
                          onPressed:
                              _isSaving ? null : () => _handleRenewal(selectedPlan),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlanDropdown(List<String> basePlanNames) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.elevation1,
        borderRadius: AppRadius.radiusL,
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBasePlanName,
          isExpanded: true,
          items: basePlanNames.map((name) => DropdownMenuItem(
            value: name,
            child: Text(name, style: AppTextStyles.body.copyWith(fontSize: 14)),
          )).toList(),
          onChanged: (val) => setState(() {
            _selectedBasePlanName = val;
            _selectedPlanIndex = 0;
          }),
          dropdownColor: AppColors.elevation3,
        ),
      ),
    );
  }

  Widget _buildPlanChips(List<db.Plan> plans) {
    return Wrap(
      spacing: 8,
      children: List.generate(plans.length, (index) {
        final isSelected = _selectedPlanIndex == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedPlanIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.elevation1,
              borderRadius: AppRadius.radiusM,
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
            ),
            child: Text(
              '${plans[index].durationMonths}M',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.text2,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPaymentChips() {
    return Row(
      children: List.generate(_paymentMethods.length, (index) {
        final isSelected = _selectedPayment == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPayment = index),
            child: Container(
              margin: EdgeInsets.only(right: index == _paymentMethods.length - 1 ? 0 : 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.elevation1,
                borderRadius: AppRadius.radiusS,
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                _paymentMethods[index],
                style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : AppColors.text2),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSummary(db.Plan plan, DateTime newExpiry) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.l),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.elevation2,
        borderRadius: AppRadius.radiusL,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontSize: 12, color: AppColors.text3)),
              Text('₹${plan.totalPrice.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          AppSpacing.gapS,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('New Expiry', style: TextStyle(fontSize: 12, color: AppColors.text3)),
              Text(
                '${newExpiry.day}/${newExpiry.month}/${newExpiry.year}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleRenewal(db.Plan plan) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(paymentsProvider.notifier).recordMemberPayment(
        memberId: widget.member.memberId,
        plan: model.Plan.fromDrift(plan),
        method: _paymentMethods[_selectedPayment],
      );

      // Monitoring Sidecar: Passive Archival
      final ownerUid = ref.read(firebaseAuthProvider)?.currentUser?.uid;
      final membershipService = ref.read(membershipServiceProvider);
      final newExpiry = membershipService.calculateRenewal(
        currentExpiry: widget.member.expiryDate,
        durationMonths: plan.durationMonths,
        now: DateTime.now(),
      );

      MonitoringService.logMembershipRenewed(
        widget.member.memberId,
        plan.name,
        plan.totalPrice,
        ownerUid: ownerUid,
        name: widget.member.name,
        phone: widget.member.phone,
        gender: widget.member.gender,
        age: widget.member.age,
        joinDate: widget.member.joinDate,
        expiryDate: newExpiry,
      );
      MonitoringService.logPaymentSuccess(
        'renew_${widget.member.memberId}',
        plan.totalPrice.toDouble(),
        _paymentMethods[_selectedPayment],
        ownerUid: ownerUid,
        memberId: widget.member.memberId,
        memberName: widget.member.name,
        planName: plan.name,
      );

      // Show success state briefly before closing
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSuccess = true;
        });
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text('${widget.member.name}\'s membership renewed!'),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Monitoring Sidecar: Passive Archival
      MonitoringService.logPaymentFailure(
          'renew_fail_${widget.member.memberId}',
          plan.totalPrice.toDouble(),
          e.toString());

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
