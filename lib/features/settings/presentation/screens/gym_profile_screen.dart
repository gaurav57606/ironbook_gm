import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
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
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 24),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Gym Profile',
            style: AppTextStyles.h3,
          ),
          centerTitle: true,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 70, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          (_gymNameController.text.isNotEmpty ? _gymNameController.text.substring(0, 1) : 'G').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.elevation2,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border, width: 2),
                          ),
                          child: Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Gym Identity',
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This information is visible on invoices',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                AppTextField(
                  label: 'Gym Name',
                  hint: 'Enter gym name',
                  controller: _gymNameController,
                  prefixIcon: const Icon(Icons.fitness_center_rounded),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Business Address',
                  hint: 'Enter full address',
                  controller: _addressController,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  maxLines: 3,
                ),
                const SizedBox(height: 48),
                AppButton(
                  text: 'Save Changes',
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
