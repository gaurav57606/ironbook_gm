import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/member_provider.dart';
import '../../../../providers/plan_provider.dart';
import '../../../../providers/payment_provider.dart';
import '../../../../data/local/models/plan_model.dart';

class QuickAddMemberScreen extends ConsumerStatefulWidget {
  const QuickAddMemberScreen({super.key});

  @override
  ConsumerState<QuickAddMemberScreen> createState() => _QuickAddMemberScreenState();
}

class _QuickAddMemberScreenState extends ConsumerState<QuickAddMemberScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  int _selectedPlanIndex = 0;
  int _selectedPayment = 1;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final plans = ref.read(planProvider);
      if (plans.isEmpty) {
        throw Exception('No gym plans configured. Please add one in settings.');
      }

      final selectedPlan = plans[_selectedPlanIndex];
      final payments = ['Cash', 'UPI', 'Card', 'Bank'];
      
      final memberId = await ref.read(membersProvider.notifier).addMember(
        name: name,
        phone: phone,
        planId: selectedPlan.id,
        joinDate: DateTime.now(),
      );

      // Record financial transaction
      await ref.read(paymentsProvider.notifier).recordMemberPayment(
        memberId: memberId,
        plan: selectedPlan,
        method: payments[_selectedPayment],
      );

      if (mounted) {
        // Navigate to invoice for the newly created member
        context.push('/invoice?memberId=$memberId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Member $name added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(planProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: StatusBarWrapper(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  children: [
                    AppTextField(label: 'Full Name', hint: 'Enter member name', controller: _nameController, enabled: !_isSaving),
                    AppTextField(label: 'Phone Number', hint: '10-digit mobile number', keyboardType: TextInputType.phone, controller: _phoneController, enabled: !_isSaving),
                    _buildSectionHeader('SELECT PLAN'),
                    if (plans.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No plans found. Please configure plans in Settings.', 
                          style: TextStyle(color: AppColors.red, fontSize: 10)),
                      )
                    else
                      _buildPlanChips(plans),
                    const SizedBox(height: 12),
                    if (plans.isNotEmpty) _buildPlanSummary(plans[_selectedPlanIndex]),
                    _buildSectionHeader('PAYMENT METHOD'),
                    _buildPaymentChips(),
                    const SizedBox(height: 32),
                    AppButton(
                      key: const Key('register_button'),
                      text: _isSaving ? 'Registering...' : 'Register & Generate Invoice',
                      onPressed: _isSaving ? null : _handleSave,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ... (keeping other helper methods as is)

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 12, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.elevation2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.text),
            ),
          ),
          Text(
            'Add Member',
            style: AppTextStyles.cardTitle.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 40), // Spacer to center the title
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      child: Text(
        title,
        style: AppTextStyles.sectionTitle.copyWith(fontSize: 9, letterSpacing: 2.0),
      ),
    );
  }

  Widget _buildPlanChips(List<Plan> plans) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(plans.length, (index) {
        final isSelected = _selectedPlanIndex == index;
        return GestureDetector(
          onTap: _isSaving ? null : () => setState(() => _selectedPlanIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected ? null : AppColors.elevation1,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? null : Border.all(color: AppColors.border),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ] : [],
            ),
            child: Text(
              plans[index].name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPaymentChips() {
    final payments = ['Cash', 'UPI', 'Card', 'Bank'];
    return Row(
      children: List.generate(payments.length, (index) {
        final isSelected = _selectedPayment == index;
        return Expanded(
          child: GestureDetector(
            onTap: _isSaving ? null : () => setState(() => _selectedPayment = index),
            child: Container(
              margin: EdgeInsets.only(right: index == payments.length - 1 ? 0 : 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.elevation1,
                borderRadius: BorderRadius.circular(10),
                border: isSelected ? null : Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                payments[index],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPlanSummary(Plan plan) {
    final expiryDate = AppDateUtils.addMonths(DateTime.now(), plan.durationMonths);
    final expiryStr = '${expiryDate.day} ${_getMonthName(expiryDate.month)} ${expiryDate.year}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.elevation2,
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
                'PLAN SUMMARY',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 9, letterSpacing: 1.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  plan.name.toUpperCase(),
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...plan.components.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(c.name, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textSecondary)),
                Text('₹${c.price.toInt()}', style: AppTextStyles.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppColors.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Payable', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
              Text('₹${plan.totalPrice.toInt()}', style: AppTextStyles.cardTitle.copyWith(fontSize: 18, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('Valid until $expiryStr', style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 11 : 9, color: isTotal ? AppColors.text : AppColors.textSecondary, fontWeight: isTotal ? FontWeight.w700 : null)),
          Text(value, style: TextStyle(fontSize: isTotal ? 11 : 9, fontWeight: isTotal ? FontWeight.w700 : null, color: isTotal ? AppColors.primary : AppColors.textPrimary)),
        ],
      ),
    );
  }
}
