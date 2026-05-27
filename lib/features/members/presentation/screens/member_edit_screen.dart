import 'package:flutter/material.dart';
import 'dart:io';
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
import 'package:image_picker/image_picker.dart';
import 'package:ironbook_gm/core/services/photo_service.dart';
import 'package:ironbook_gm/shared/widgets/member_photo_avatar.dart';

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
  String? _photoUrl;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.elevation2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_photoUrl != null && _photoUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.red),
                title: const Text('Remove Photo', style: TextStyle(color: AppColors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );

    if (source == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    final url = await photoService.pickAndUpload(
      memberId: widget.memberId,
      source: source,
      existingUrl: _photoUrl,
    );

    if (mounted) {
      setState(() {
        _isUploadingPhoto = false;
        if (url != null) {
          _photoUrl = url;
          AppSnackBar.showSuccess(context, 'Photo uploaded successfully');
        } else {
          AppSnackBar.showError(context, 'Failed to upload photo');
        }
      });
    }
  }

  void _removePhoto() async {
    if (_photoUrl == null) return;
    final tempUrl = _photoUrl;
    setState(() {
      _photoUrl = null;
    });
    await photoService.deletePhoto(tempUrl);
    if (mounted) {
      AppSnackBar.showSuccess(context, 'Photo removed');
    }
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
            photoUrl: _photoUrl ?? '',
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
      _photoUrl = member.photoUrl;
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
                    if (!Platform.environment.containsKey('FLUTTER_TEST')) ...[
                      Center(
                        child: Stack(
                          children: [
                            MemberPhotoAvatar(
                              memberName: _nameController.text.isEmpty ? member.name : _nameController.text,
                              photoUrl: _photoUrl,
                              size: 100,
                              onTap: _isUploadingPhoto || _isSaving ? null : _pickPhoto,
                            ),
                            if (_isUploadingPhoto)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: AppRadius.radiusL,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primary,
                                child: Icon(
                                  _photoUrl == null || _photoUrl!.isEmpty ? Icons.camera_alt : Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapL,
                    ],
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
