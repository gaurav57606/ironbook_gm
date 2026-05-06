import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/status_bar_wrapper.dart';
import '../../../../core/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    final owner = auth.owner;
    final settings = auth.settings;

    _gstRateController = TextEditingController(text: settings.gstRate.toString());
    _gstinController = TextEditingController(text: owner?.gstin ?? '');
    _bankNameController = TextEditingController(text: owner?.bankName ?? '');
    _accNoController = TextEditingController(text: owner?.accountNumber ?? '');
    _ifscController = TextEditingController(text: owner?.ifsc ?? '');
    _upiController = TextEditingController(text: owner?.upiId ?? '');
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
    final auth = ref.read(authProvider);
    if (auth.owner == null) return;

    final updatedOwner = auth.owner!;
    updatedOwner.gstin = _gstinController.text;
    updatedOwner.bankName = _bankNameController.text;
    updatedOwner.accountNumber = _accNoController.text;
    updatedOwner.ifsc = _ifscController.text;
    updatedOwner.upiId = _upiController.text;

    final updatedSettings = auth.settings.copyWith(
      gstRate: double.tryParse(_gstRateController.text) ?? 18.0,
    );

    await ref.read(authProvider.notifier).updateOwner(updatedOwner);
    await ref.read(authProvider.notifier).updateSettings(updatedSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tax & Billing info updated')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      child: Scaffold(
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
                const SizedBox(height: 16),
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
}









