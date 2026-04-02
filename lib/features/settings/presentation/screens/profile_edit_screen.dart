import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../data/local/models/owner_profile_model.dart';
import '../../../../providers/auth_provider.dart';

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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.isGymProfile ? 'Gym Profile' : 'Owner Profile', 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildField(widget.isGymProfile ? 'Gym Name' : 'Owner Name', _nameController, Icons.person),
            _buildField('Phone Number', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
            _buildField('Address', _addressController, Icons.location_on, maxLines: 2),
            if (widget.isGymProfile) ...[
              const SizedBox(height: 20),
              const Divider(color: AppColors.border),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Billing Detail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text3)),
              ),
              const SizedBox(height: 15),
              _buildField('GSTIN', _gstinController, Icons.receipt),
              _buildField('Bank Name', _bankController, Icons.account_balance),
              _buildField('Account Number', _accountController, Icons.numbers),
              _buildField('IFSC Code', _ifscController, Icons.code),
            ],
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _saveHandler,
                child: const Text('Save Changes', 
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text3)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 13, color: AppColors.text),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 16, color: AppColors.text3),
              filled: true,
              fillColor: AppColors.bg3,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.orange),
              ),
            ),
          ),
        ],
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
