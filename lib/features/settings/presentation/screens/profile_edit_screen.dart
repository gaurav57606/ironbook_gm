import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../core/providers/owner_provider.dart';
import '../../../../core/data/local/models/owner_profile_model.dart';

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
  bool _populated = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _gstinController = TextEditingController();
    _bankController = TextEditingController();
    _accountController = TextEditingController();
    _ifscController = TextEditingController();

    final owner = ref.read(ownerProvider);
    if (owner != null) {
      _populateControllers(owner);
      _populated = true;
    }
  }

  void _populateControllers(OwnerProfile owner) {
    _nameController.text = widget.isGymProfile ? owner.gymName : owner.ownerName;
    _phoneController.text = owner.phone;
    _addressController.text = owner.address;
    _gstinController.text = owner.gstin ?? '';
    _bankController.text = owner.bankName ?? '';
    _accountController.text = owner.accountNumber ?? '';
    _ifscController.text = owner.ifsc ?? '';
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
    final owner = ref.watch(ownerProvider);
    if (!_populated && owner != null) {
      _populated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _populateControllers(owner);
        setState(() {});
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
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
              ..._buildBasicInfoFields(),
              if (widget.isGymProfile) ..._buildBillingSection(),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
    );
  }

  List<Widget> _buildBasicInfoFields() {
    return [
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
    ];
  }

  List<Widget> _buildBillingSection() {
    return [
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
    ];
  }

  Widget _buildSaveButton() {
    return Column(
      children: [
        const SizedBox(height: 48),
        AppButton(
          text: 'Save Changes',
          onPressed: _saveHandler,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _saveHandler() async {
    final owner = ref.read(ownerProvider) ?? OwnerProfile(
      gymName: '',
      ownerName: '',
      phone: '',
      address: '',
    );
    
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isGymProfile ? 'Gym name cannot be empty' : 'Owner name cannot be empty')),
      );
      return;
    }

    final updated = owner.copyWith(
      gymName: widget.isGymProfile ? name : owner.gymName,
      ownerName: widget.isGymProfile ? owner.ownerName : name,
      phone: _phoneController.text,
      address: _addressController.text,
      gstin: _gstinController.text,
      bankName: _bankController.text,
      accountNumber: _accountController.text,
      ifsc: _ifscController.text,
    );

    await ref.read(ownerProvider.notifier).updateOwner(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isGymProfile ? 'Gym profile updated' : 'Profile updated successfully')),
      );
      Navigator.pop(context);
    }
  }
}
