import 'package:flutter/material.dart';
import '../../../../shared/utils/date_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/status_bar_wrapper.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import '../../../billing/providers/billing_provider.dart';
import '../../../../core/data/local/drift/outbox_database.dart' as db;

class QuickAddMemberScreen extends ConsumerStatefulWidget {
  const QuickAddMemberScreen({super.key});

  @override
  ConsumerState<QuickAddMemberScreen> createState() => _QuickAddMemberScreenState();
}

class _QuickAddMemberScreenState extends ConsumerState<QuickAddMemberScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedGender = 'Male';
  int _selectedPlanIndex = 0;
  int _selectedPayment = 1;
  bool _isSaving = false;

  static const _paymentMethods = ['Cash', 'UPI', 'Card', 'Bank'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final ageStr = _ageController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name')),
      );
      return;
    }

    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final plansAsync = ref.read(activePlansProvider);
      final plans = plansAsync.value ?? [];
      if (plans.isEmpty) {
        throw Exception('No gym plans configured. Please add one in settings.');
      }

      final selectedPlan = plans[_selectedPlanIndex];
      final age = int.tryParse(ageStr);
      
      final memberId = await ref.read(membersProvider.notifier).addMember(
        name: name,
        phone: phone,
        planId: selectedPlan.id,
        joinDate: DateTime.now(),
        gender: _selectedGender,
        age: age,
      );

      // Record financial transaction
      await ref.read(billingNotifierProvider).recordMemberPayment(
        memberId: memberId,
        plan: selectedPlan,
        method: _paymentMethods[_selectedPayment],
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
    final plansAsync = ref.watch(activePlansProvider);
    final plans = plansAsync.value ?? [];

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
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader('GENDER'),
                              _buildGenderChips(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: AppTextField(label: 'Age', hint: 'Years', keyboardType: TextInputType.number, controller: _ageController, enabled: !_isSaving),
                        ),
                      ],
                    ),
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
                      onPressed: (_isSaving || plans.isEmpty) ? null : _handleSave,
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

  Widget _buildPlanChips(List<db.Plan> plans) {
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

  Widget _buildGenderChips() {
    final genders = ['Male', 'Female', 'Other'];
    return Row(
      children: List.generate(genders.length, (index) {
        final isSelected = _selectedGender == genders[index];
        return Expanded(
          child: GestureDetector(
            onTap: _isSaving ? null : () => setState(() => _selectedGender = genders[index]),
            child: Container(
              margin: EdgeInsets.only(right: index == genders.length - 1 ? 0 : 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.elevation1,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                genders[index],
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

  Widget _buildPaymentChips() {
    return Row(
      children: List.generate(_paymentMethods.length, (index) {
        final isSelected = _selectedPayment == index;
        return Expanded(
          child: GestureDetector(
            onTap: _isSaving ? null : () => setState(() => _selectedPayment = index),
            child: Container(
              margin: EdgeInsets.only(right: index == _paymentMethods.length - 1 ? 0 : 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.elevation1,
                borderRadius: BorderRadius.circular(10),
                border: isSelected ? null : Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                _paymentMethods[index],
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

  Widget _buildPlanSummary(db.Plan plan) {
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
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.primary),
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
              const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textMuted),
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
}




