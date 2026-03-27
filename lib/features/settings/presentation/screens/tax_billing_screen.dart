import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../providers/auth_provider.dart';
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
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text, size: 20),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Tax & Billing',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TAX CONFIGURATION',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.text3),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Default GST Rate (%)',
                hint: '18.0',
                controller: _gstRateController,
                keyboardType: TextInputType.number,
              ),
              AppTextField(
                label: 'GSTIN',
                hint: 'Enter GST Number',
                controller: _gstinController,
              ),
              const SizedBox(height: 20),
              const Text(
                'BANKING DETAILS',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.text3),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Bank Name',
                hint: 'Enter Bank Name',
                controller: _bankNameController,
              ),
              AppTextField(
                label: 'Account Number',
                hint: 'Enter Account Number',
                controller: _accNoController,
                keyboardType: TextInputType.number,
              ),
              AppTextField(
                label: 'IFSC Code',
                hint: 'Enter IFSC',
                controller: _ifscController,
              ),
              AppTextField(
                label: 'UPI ID',
                hint: 'yourname@bank',
                controller: _upiController,
              ),
              const SizedBox(height: 40),
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
}
