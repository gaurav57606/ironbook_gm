import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
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
      await ref.read(paymentProvider.notifier).recordMemberPayment(
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

    return StatusBarWrapper(
      child: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                AppTextField(label: 'Full Name', hint: 'Ravi Kumar', controller: _nameController, enabled: !_isSaving),
                AppTextField(label: 'Phone Number', hint: '+91 99887 76655', keyboardType: TextInputType.phone, controller: _phoneController, enabled: !_isSaving),
                _buildSectionHeader('Select Plan'),
                if (plans.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No plans found. Please configure plans in Settings.', 
                      style: TextStyle(color: Colors.red, fontSize: 10)),
                  )
                else
                  _buildPlanChips(plans),
                if (plans.isNotEmpty) _buildPlanSummary(plans[_selectedPlanIndex]),
                _buildSectionHeader('Payment Method'),
                _buildPaymentChips(),
                const SizedBox(height: 20),
                AppButton(
                  text: _isSaving ? 'Processing...' : 'Register Member & Generate Invoice',
                  onPressed: _isSaving ? null : _handleSave,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // ... (keeping other helper methods as is)

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.chevron_left, size: 18, color: AppColors.text),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Add Member',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.text2,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPlanChips(List<Plan> plans) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: List.generate(plans.length, (index) {
        final isSelected = _selectedPlanIndex == index;
        return GestureDetector(
          onTap: _isSaving ? null : () => setState(() => _selectedPlanIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.orange.withValues(alpha: 0.1) : AppColors.bg3,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? AppColors.orange : AppColors.border),
            ),
            child: Text(
              '${plans[index].name} ₹${plans[index].totalPrice.toInt()}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.orange : AppColors.text2,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPaymentChips() {
    final payments = ['Cash', 'UPI', 'Card', 'Bank'];
    return Wrap(
      spacing: 5,
      children: List.generate(payments.length, (index) {
        final isSelected = _selectedPayment == index;
        return GestureDetector(
          onTap: _isSaving ? null : () => setState(() => _selectedPayment = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.orange.withValues(alpha: 0.1) : AppColors.bg3,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? AppColors.orange : AppColors.border),
            ),
            child: Text(
              payments[index],
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.orange : AppColors.text2,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPlanSummary(Plan plan) {
    // Calculate expiry based on duration
    final expiryDate = DateTime.now().add(Duration(days: plan.durationMonths * 30));
    final expiryStr = '${expiryDate.day} ${_getMonthName(expiryDate.month)} ${expiryDate.year}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${plan.name.toUpperCase()} SUMMARY',
            style: const TextStyle(fontSize: 9, color: AppColors.orange, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
          const SizedBox(height: 5),
          ...plan.components.map((c) => _buildSummaryRow(c.name, '₹${c.price.toInt()}')),
          const Divider(height: 10, color: Color(0x33FF6B2B)),
          _buildSummaryRow('Total', '₹${plan.totalPrice.toInt()}', isTotal: true),
          const SizedBox(height: 3),
          Text('Expires: $expiryStr', style: const TextStyle(fontSize: 9, color: AppColors.text2)),
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
          Text(label, style: TextStyle(fontSize: isTotal ? 11 : 9, color: isTotal ? AppColors.text : AppColors.text2, fontWeight: isTotal ? FontWeight.w700 : null)),
          Text(value, style: TextStyle(fontSize: isTotal ? 11 : 9, fontWeight: isTotal ? FontWeight.w700 : null, color: isTotal ? AppColors.orange : AppColors.text)),
        ],
      ),
    );
  }
}
