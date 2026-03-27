import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class GymProfileScreen extends ConsumerStatefulWidget {
  const GymProfileScreen({super.key});

  @override
  ConsumerState<GymProfileScreen> createState() => _GymProfileScreenState();
}

class _GymProfileScreenState extends ConsumerState<GymProfileScreen> {
  late TextEditingController _gymNameController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final owner = ref.read(authProvider).owner;
    _gymNameController = TextEditingController(text: owner?.gymName ?? '');
    _addressController = TextEditingController(text: owner?.address ?? '');
  }

  @override
  void dispose() {
    _gymNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = ref.read(authProvider);
    if (auth.owner == null) return;

    final updated = auth.owner!;
    updated.gymName = _gymNameController.text;
    updated.address = _addressController.text;

    await ref.read(authProvider.notifier).updateOwner(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gym profile updated')),
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
            'Gym Profile',
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
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (_gymNameController.text.isNotEmpty 
                            ? _gymNameController.text.substring(0, 1) 
                            : 'G').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.bg3,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: AppColors.text2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              AppTextField(
                label: 'Gym Name',
                hint: 'Enter gym name',
                controller: _gymNameController,
              ),
              AppTextField(
                label: 'Business Address',
                hint: 'Enter full address',
                controller: _addressController,
              ),
              const SizedBox(height: 40),
              AppButton(
                text: 'Save Changes',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
