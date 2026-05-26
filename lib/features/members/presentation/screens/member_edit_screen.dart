import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ironbook_gm/core/constants/app_colors.dart';
import 'package:ironbook_gm/core/constants/app_radius.dart';
import 'package:ironbook_gm/core/constants/app_spacing.dart';
import 'package:ironbook_gm/core/constants/app_text_styles.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/shared/utils/app_snack_bar.dart';
import 'package:ironbook_gm/shared/widgets/app_button.dart';
import 'package:ironbook_gm/shared/widgets/app_text_field.dart';

class MemberEditScreen extends ConsumerStatefulWidget {
  final String memberId;
  const MemberEditScreen({super.key, required this.memberId});

  @override
  ConsumerState<MemberEditScreen> createState() => _MemberEditScreenState();
}

class _MemberEditScreenState extends ConsumerState<MemberEditScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      AppSnackBar.showError(context, 'Please enter name');
      return;
    }

    if (phone.length < 10) {
      AppSnackBar.showError(context, 'Please enter a valid 10-digit phone number');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(membersProvider.notifier).updateMember(
            memberId: widget.memberId,
            name: name,
            phone: phone,
          );
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Member updated successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(memberProvider(widget.memberId));

    if (member == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_outlined, size: 48, color: AppColors.text3),
              AppSpacing.gapM,
              const Text('Member not found', style: TextStyle(color: AppColors.text)),
              AppSpacing.gapL,
              AppButton(
                text: 'Go Back',
                width: 120,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      _nameController.text = member.name;
      _phoneController.text = member.phone ?? '';
      _initialized = true;
    }

    return Scaffold(
      key: const Key('member-edit-root'),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: AppSpacing.m,
                  ),
                  children: [
                    AppTextField(
                      key: const Key('input-edit-member-name'),
                      label: 'Full Name',
                      hint: 'Enter member name',
                      controller: _nameController,
                      enabled: !_isSaving,
                    ),
                    AppTextField(
                      key: const Key('input-edit-member-phone'),
                      label: 'Phone Number',
                      hint: '10-digit mobile number',
                      keyboardType: TextInputType.phone,
                      controller: _phoneController,
                      enabled: !_isSaving,
                    ),
                    AppSpacing.gapXL,
                    AppButton(
                      key: const Key('save_member_button'),
                      text: _isSaving ? 'Saving...' : 'Save Changes',
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _handleSave,
                    ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.m,
      ),
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
                'EDIT MEMBER',
                style: AppTextStyles.label.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Update Profile',
                style: AppTextStyles.h3.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}
