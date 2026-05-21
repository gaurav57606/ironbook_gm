import 'package:flutter/material.dart';
import 'package:ironbook_gm/core/constants/app_colors.dart';
import 'package:ironbook_gm/shared/utils/date_utils.dart';
import 'package:ironbook_gm/core/constants/app_spacing.dart';
import 'package:ironbook_gm/core/constants/app_radius.dart';
import 'package:ironbook_gm/core/constants/app_shadows.dart';
import 'package:ironbook_gm/core/constants/app_text_styles.dart';
import 'package:ironbook_gm/shared/widgets/app_section_header.dart';
import 'package:ironbook_gm/shared/widgets/app_button.dart';
import 'package:ironbook_gm/shared/widgets/app_text_field.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/features/billing/providers/billing_provider.dart';
import 'package:ironbook_gm/core/providers/payment_provider.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;
import 'package:ironbook_gm/core/data/local/models/plan_model.dart' as model;
import 'package:ironbook_gm/features/members/presentation/controllers/member_registration_controller.dart';
import 'package:ironbook_gm/shared/utils/app_snack_bar.dart';

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
  DateTime _joiningDate = DateTime.now();
  String? _selectedBasePlanName;

  static const _paymentMethods = ['Cash', 'UPI', 'Card', 'Bank'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final ageStr = _ageController.text.trim();

    if (name.isEmpty) {
      AppSnackBar.showError(context, 'Please enter name');
      return;
    }

    if (phone.length < 10) {
      AppSnackBar.showError(context, 'Please enter a valid 10-digit phone number');
      return;
    }

    final plansAsync = ref.read(activePlansProvider);
    final plans = plansAsync.value ?? [];
    final groupedPlans = <String, List<db.Plan>>{};
    for (var p in plans) {
      groupedPlans.putIfAbsent(p.name, () => []).add(p);
    }
    
    final selectedBasePlans = _selectedBasePlanName != null ? groupedPlans[_selectedBasePlanName] ?? [] : [];
    if (selectedBasePlans.isEmpty) {
      AppSnackBar.showError(context, 'Selected plan not found');
      return;
    }

    final selectedPlan = selectedBasePlans[_selectedPlanIndex];
    final age = int.tryParse(ageStr);

    ref.read(memberRegistrationControllerProvider.notifier).registerMember(
      name: name,
      phone: phone,
      selectedPlan: selectedPlan,
      joiningDate: _joiningDate,
      gender: _selectedGender,
      paymentMethod: _paymentMethods[_selectedPayment],
      age: age,
    );
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(memberRegistrationControllerProvider);
    final isSaving = regState.isSaving;

    // Listen for state changes
    ref.listen(memberRegistrationControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        AppSnackBar.showError(context, next.error!);
      }
      if (next.successMemberId != null && next.successMemberId != prev?.successMemberId) {
        AppSnackBar.showSuccess(context, 'Member added successfully');
        context.push('/invoice?memberId=${next.successMemberId}');
        // Reset controller so it doesn't trigger again on rebuild
        ref.read(memberRegistrationControllerProvider.notifier).reset();
      }
    });

    final plansAsync = ref.watch(activePlansProvider);
    final plans = plansAsync.value ?? [];

    // Group plans by name
    final Map<String, List<db.Plan>> groupedPlans = {};
    for (var plan in plans) {
      groupedPlans.putIfAbsent(plan.name, () => []).add(plan);
    }
    final basePlanNames = groupedPlans.keys.toList();
    
    if (_selectedBasePlanName == null && basePlanNames.isNotEmpty) {
      _selectedBasePlanName = basePlanNames.first;
    }

    final selectedBasePlans = _selectedBasePlanName != null ? (groupedPlans[_selectedBasePlanName] ?? <db.Plan>[]) : <db.Plan>[];
    // Sort by duration to be consistent
    selectedBasePlans.sort((a, b) => a.durationMonths.compareTo(b.durationMonths));

    if (_selectedPlanIndex >= selectedBasePlans.length) {
      _selectedPlanIndex = 0;
    }

    final selectedPlan = selectedBasePlans.isNotEmpty ? selectedBasePlans[_selectedPlanIndex] : null;

    return Scaffold(
      key: const Key('quick-add-member-root'),
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          top: true,
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.s),
                  children: [
                    AppTextField(
                      key: const Key('input-member-name'),
                      label: 'Full Name', 
                      hint: 'Enter member name', 
                      controller: _nameController, 
                      enabled: !isSaving,
                    ),
                    AppTextField(
                      key: const Key('input-member-phone'),
                      label: 'Phone Number', 
                      hint: '10-digit mobile number', 
                      keyboardType: TextInputType.phone, 
                      controller: _phoneController, 
                      enabled: !isSaving,
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 400;
                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppSectionHeader(title: 'Gender'),
                              _buildGenderChips(isSaving),
                              AppSpacing.gapM,
                              AppTextField(
                                key: const Key('input-member-age'),
                                label: 'Age',
                                hint: 'Years',
                                keyboardType: TextInputType.number,
                                controller: _ageController,
                                enabled: !isSaving,
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const AppSectionHeader(title: 'Gender'),
                                  _buildGenderChips(isSaving),
                                ],
                              ),
                            ),
                            AppSpacing.gapM,
                            Expanded(
                              child: AppTextField(
                                key: const Key('input-member-age'),
                                label: 'Age',
                                hint: 'Years',
                                keyboardType: TextInputType.number,
                                controller: _ageController,
                                enabled: !isSaving,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    _buildDateField(),
                    const AppSectionHeader(title: 'Membership Plan'),
                    if (plans.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No plans found. Please configure plans in Settings.', 
                          style: TextStyle(color: AppColors.red, fontSize: 10)),
                      )
                    else ...[
                      _buildPlanDropdown(basePlanNames, isSaving),
                      const AppSectionHeader(title: 'Subscription Duration'),
                      _buildPlanChips(selectedBasePlans, isSaving),
                    ],
                    AppSpacing.gapM,
                    if (selectedPlan != null) _buildPlanSummary(selectedPlan),
                    const AppSectionHeader(title: 'Payment Method'),
                    _buildPaymentChips(isSaving),
                    AppSpacing.gapXL,
                    AppButton(
                      key: const Key('register_button'),
                      text: isSaving ? 'Registering...' : 'Register & Generate Invoice',
                      onPressed: (isSaving || plans.isEmpty) ? null : _handleSave,
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.elevation1.withValues(alpha: 0.5),
                borderRadius: AppRadius.radiusM,
                border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.close_rounded, size: 20, color: AppColors.text),
            ),
          ),
          Column(
            children: [
              Text(
                'NEW MEMBER',
                style: AppTextStyles.label.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Registration',
                style: AppTextStyles.h3.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildPlanChips(List<db.Plan> plans, bool isSaving) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(plans.length, (index) {
        final isSelected = _selectedPlanIndex == index;
        return GestureDetector(
          onTap: isSaving ? null : () => setState(() => _selectedPlanIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.glassGradient : null,
              color: isSelected ? null : AppColors.elevation1.withValues(alpha: 0.3),
              borderRadius: AppRadius.radiusL,
              border: Border.all(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.2),
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ] : [],
            ),
            child: Text(
              '${plans[index].durationMonths} MONTHS',
              style: AppTextStyles.label.copyWith(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGenderChips(bool isSaving) {
    final genders = ['Male', 'Female', 'Other'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(genders.length, (index) {
        final isSelected = _selectedGender == genders[index];
        return GestureDetector(
          onTap: isSaving ? null : () => setState(() => _selectedGender = genders[index]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.glassGradient : null,
              color: isSelected ? null : AppColors.elevation1.withValues(alpha: 0.3),
              borderRadius: AppRadius.radiusM,
              border: Border.all(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              genders[index].toUpperCase(),
              style: AppTextStyles.label.copyWith(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPaymentChips(bool isSaving) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_paymentMethods.length, (index) {
        final isSelected = _selectedPayment == index;
        return GestureDetector(
          onTap: isSaving ? null : () => setState(() => _selectedPayment = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.glassGradient : null,
              color: isSelected ? null : AppColors.elevation1.withValues(alpha: 0.3),
              borderRadius: AppRadius.radiusM,
              border: Border.all(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              _paymentMethods[index].toUpperCase(),
              style: AppTextStyles.label.copyWith(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPlanSummary(db.Plan plan) {
    final membershipService = ref.read(membershipServiceProvider);
    final expiryDate = membershipService.calculateExpiry(
      startDate: _joiningDate,
      durationMonths: plan.durationMonths,
    );
    final expiryStr = '${expiryDate.day} ${_getMonthName(expiryDate.month)} ${expiryDate.year}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.l),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.glassGradient,
        borderRadius: AppRadius.radiusXL,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ORDER SUMMARY',
                style: AppTextStyles.label.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.radiusS,
                ),
                child: Text(
                  plan.name.toUpperCase(),
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...plan.components.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(c.name, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                Text('₹${c.price.toInt()}', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          )),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.primary, thickness: 0.1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL AMOUNT', style: AppTextStyles.label.copyWith(fontSize: 12, fontWeight: FontWeight.w900)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('₹${plan.totalPrice.toInt()}', style: AppTextStyles.h1.copyWith(fontSize: 24, color: AppColors.primary))
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: AppRadius.radiusM,
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'VALID UNTIL $expiryStr',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    final dateStr = '${_joiningDate.day} ${_getMonthName(_joiningDate.month)} ${_joiningDate.year}';
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _joiningDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: AppColors.bg,
                  onSurface: AppColors.text,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() => _joiningDate = date);
        }
      },
      child: AbsorbPointer(
        child: AppTextField(
          label: 'Joining Date',
          hint: 'Select date',
          controller: TextEditingController(text: dateStr),
          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _buildPlanDropdown(List<String> basePlanNames, bool isSaving) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.elevation2,
        borderRadius: AppRadius.radiusL,
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedBasePlanName,
          items: basePlanNames.map((name) => DropdownMenuItem(
            value: name,
            child: Text(name, style: AppTextStyles.body.copyWith(fontSize: 14)),
          )).toList(),
          onChanged: isSaving ? null : (val) {
            setState(() {
              _selectedBasePlanName = val;
              _selectedPlanIndex = 0; // Reset duration index when plan changes
            });
          },
          dropdownColor: AppColors.elevation3,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }
}




