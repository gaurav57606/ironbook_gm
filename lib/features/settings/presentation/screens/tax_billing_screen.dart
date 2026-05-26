import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../core/providers/owner_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/data/local/models/owner_profile_model.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/subscription_duration_helper.dart';

class TaxBillingScreen extends ConsumerStatefulWidget {
  const TaxBillingScreen({super.key});

  @override
  ConsumerState<TaxBillingScreen> createState() => _TaxBillingScreenState();
}

class _TaxBillingScreenState extends ConsumerState<TaxBillingScreen> {
  late TextEditingController _gstRateController;
  late TextEditingController _gstinController;
  late TextEditingController _bankNameController;
  late TextEditingController _accNoController;
  late TextEditingController _ifscController;
  late TextEditingController _upiController;
  late SubscriptionMode _selectedMode;

  @override
  void initState() {
    super.initState();
    final owner = ref.read(ownerProvider);
    final settings = ref.read(settingsProvider);

    _gstRateController = TextEditingController(text: settings.gstRate.toString());
    _gstinController = TextEditingController(text: owner?.gstin ?? '');
    _bankNameController = TextEditingController(text: owner?.bankName ?? '');
    _accNoController = TextEditingController(text: owner?.accountNumber ?? '');
    _ifscController = TextEditingController(text: owner?.ifsc ?? '');
    _upiController = TextEditingController(text: owner?.upiId ?? '');
    _selectedMode = SubscriptionMode.fromString(settings.subscriptionMode);
  }

  @override
  void dispose() {
    _gstRateController.dispose();
    _gstinController.dispose();
    _bankNameController.dispose();
    _accNoController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final owner = ref.read(ownerProvider) ?? OwnerProfile(
      gymName: '',
      ownerName: '',
      phone: '',
      address: '',
    );
    final settings = ref.read(settingsProvider);

    final parsedGst = double.tryParse(_gstRateController.text.trim());
    if (parsedGst == null || parsedGst < 0 || parsedGst > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid GST rate between 0 and 100')),
      );
      return;
    }

    final updatedOwner = owner.copyWith(
      gstin: _gstinController.text.trim(),
      bankName: _bankNameController.text.trim(),
      accountNumber: _accNoController.text.trim(),
      ifsc: _ifscController.text.trim(),
      upiId: _upiController.text.trim(),
    );

    final updatedSettings = settings.copyWith(
      gstRate: parsedGst,
      subscriptionMode: _selectedMode.toDbString(),
    );

    await ref.read(ownerProvider.notifier).updateOwner(updatedOwner);
    await ref.read(settingsProvider.notifier).updateSettings(updatedSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tax & Billing info updated')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 24),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Tax & Billing',
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
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 70, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader('TAX CONFIGURATION'),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Default GST Rate (%)',
                hint: '18.0',
                controller: _gstRateController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.percent_rounded),
              ),
              AppTextField(
                label: 'GSTIN',
                hint: 'Enter GST Number',
                controller: _gstinController,
                prefixIcon: const Icon(Icons.receipt_long_rounded),
              ),
              const SizedBox(height: 24),
              _buildSubscriptionModeSection(),
              const SizedBox(height: 24),
              _buildHeader('BANKING DETAILS'),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Bank Name',
                hint: 'Enter Bank Name',
                controller: _bankNameController,
                prefixIcon: const Icon(Icons.account_balance_rounded),
              ),
              AppTextField(
                label: 'Account Number',
                hint: 'Enter Account Number',
                controller: _accNoController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.numbers_rounded),
              ),
              AppTextField(
                label: 'IFSC Code',
                hint: 'Enter IFSC',
                controller: _ifscController,
                prefixIcon: const Icon(Icons.code_rounded),
              ),
              AppTextField(
                label: 'UPI ID',
                hint: 'yourname@bank',
                controller: _upiController,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
              ),
              const SizedBox(height: 48),
              AppButton(
                text: 'Save Billing Info',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.sectionTitle.copyWith(
          fontSize: 10,
          letterSpacing: 1.5,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildSubscriptionModeSection() {
    final now = DateTime.now();
    final exampleEndDate = SubscriptionDurationHelper.calculateEndDate(
      startDate: now,
      durationMonths: 1,
      mode: _selectedMode,
    );
    final nowStr = '${now.day}/${now.month}/${now.year}';
    final endStr = '${exampleEndDate.day}/${exampleEndDate.month}/${exampleEndDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('SUBSCRIPTION CALCULATION MODE'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          child: SegmentedButton<SubscriptionMode>(
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: Colors.white,
              backgroundColor: AppColors.elevation2,
              side: const BorderSide(color: AppColors.border),
            ),
            segments: const [
              ButtonSegment(
                value: SubscriptionMode.fixed28,
                label: Text('28 Days'),
                icon: Icon(Icons.calendar_today, size: 14),
              ),
              ButtonSegment(
                value: SubscriptionMode.fixed30,
                label: Text('30 Days'),
                icon: Icon(Icons.calendar_month, size: 14),
              ),
              ButtonSegment(
                value: SubscriptionMode.calendarMonth,
                label: Text('Same Date'),
                icon: Icon(Icons.date_range, size: 14),
              ),
            ],
            selected: {_selectedMode},
            onSelectionChanged: (newSelection) {
              setState(() {
                _selectedMode = newSelection.first;
              });
            },
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Preview: Paid on $nowStr  →  Expires on $endStr',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}









