import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/status_bar_wrapper.dart';
import '../../../../core/data/local/models/owner_profile_model.dart';
import '../../../../core/providers/auth_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  final bool isGymProfile;
  const ProfileEditScreen({super.key, required this.isGymProfile});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _gstinController;
  late TextEditingController _bankController;
  late TextEditingController _accountController;
  late TextEditingController _ifscController;

  @override
  void initState() {
    super.initState();
    final owner = ref.read(authProvider).owner;
    _nameController = TextEditingController(text: widget.isGymProfile ? owner?.gymName : owner?.ownerName);
    _phoneController = TextEditingController(text: owner?.phone);
    _addressController = TextEditingController(text: owner?.address);
    _gstinController = TextEditingController(text: owner?.gstin);
    _bankController = TextEditingController(text: owner?.bankName);
    _accountController = TextEditingController(text: owner?.accountNumber);
    _ifscController = TextEditingController(text: owner?.ifsc);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    super.dispose();
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
          title: Text(
            widget.isGymProfile ? 'Gym Profile' : 'Owner Profile',
            style: AppTextStyles.h3,
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
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
                AppTextField(
                  label: widget.isGymProfile ? 'Gym Name' : 'Owner Name',
                  hint: widget.isGymProfile ? 'Enter gym name' : 'Enter your name',
                  controller: _nameController,
                  prefixIcon: Icon(widget.isGymProfile ? Icons.business_rounded : Icons.person_outline_rounded),
                ),
                AppTextField(
                  label: 'Phone Number',
                  hint: '+91 98765 43210',
                  controller: _phoneController,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                ),
                AppTextField(
                  label: 'Address',
                  hint: 'Full gym address',
                  controller: _addressController,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  maxLines: 3,
                ),
                if (widget.isGymProfile) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'BILLING DETAILS',
                          style: AppTextStyles.sectionTitle.copyWith(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    label: 'GSTIN',
                    hint: '22AAAAA0000A1Z5',
                    controller: _gstinController,
                    prefixIcon: const Icon(Icons.receipt_long_outlined),
                  ),
                  AppTextField(
                    label: 'Bank Name',
                    hint: 'HDFC Bank',
                    controller: _bankController,
                    prefixIcon: const Icon(Icons.account_balance_outlined),
                  ),
                  AppTextField(
                    label: 'Account Number',
                    hint: '50100000000000',
                    controller: _accountController,
                    prefixIcon: const Icon(Icons.numbers_outlined),
                  ),
                  AppTextField(
                    label: 'IFSC Code',
                    hint: 'HDFC0000001',
                    controller: _ifscController,
                    prefixIcon: const Icon(Icons.code_rounded),
                  ),
                ],
                const SizedBox(height: 48),
                AppButton(
                  text: 'Save Changes',
                  onPressed: _saveHandler,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveHandler() async {
    final auth = ref.read(authProvider);
    final currentOwner = auth.owner;
    
    final updated = OwnerProfile(
      gymName: widget.isGymProfile ? _nameController.text : currentOwner?.gymName ?? '',
      ownerName: widget.isGymProfile ? currentOwner?.ownerName ?? '' : _nameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      gstin: _gstinController.text,
      bankName: _bankController.text,
      accountNumber: _accountController.text,
      ifsc: _ifscController.text,
    );

    await ref.read(authProvider.notifier).updateOwner(updated);
    if (mounted) Navigator.pop(context);
  }
}









