import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../core/providers/owner_provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class GymProfileScreen extends ConsumerStatefulWidget {
  const GymProfileScreen({super.key});

  @override
  ConsumerState<GymProfileScreen> createState() => _GymProfileScreenState();
}

class _GymProfileScreenState extends ConsumerState<GymProfileScreen> {
  late TextEditingController _gymNameController;
  late TextEditingController _addressController;
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    final owner = ref.read(ownerProvider);
    _gymNameController = TextEditingController(text: owner?.gymName ?? '');
    _addressController = TextEditingController(text: owner?.address ?? '');
    _gymNameController.addListener(() => setState(() {}));
    _logoPath = ref.read(ownerProvider)?.logoPath;
  }

  @override
  void dispose() {
    _gymNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    final sourcePath = result.files.single.path;
    if (sourcePath == null) return;

    // Copy to permanent app documents directory so path stays valid
    final docsDir = await getApplicationDocumentsDirectory();
    final fileName = 'gym_logo_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    final destPath = p.join(docsDir.path, fileName);
    await File(sourcePath).copy(destPath);

    // Persist immediately so _save() picks it up
    final owner = ref.read(ownerProvider);
    if (owner != null) {
      await ref.read(ownerProvider.notifier).updateOwner(
        owner.copyWith(logoPath: destPath),
      );
    }

    if (mounted) {
      setState(() {
        _logoPath = destPath;
      });
    }
  }

  Future<void> _save() async {
    final owner = ref.read(ownerProvider);
    if (owner == null) return;

    if (_gymNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gym name cannot be empty')),
      );
      return;
    }

    final updated = owner.copyWith(
      gymName: _gymNameController.text.trim(),
      address: _addressController.text.trim(),
    );

    await ref.read(ownerProvider.notifier).updateOwner(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gym profile updated')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, MediaQuery.of(context).padding.top + 70, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 40),
              _buildFormFields(),
              const SizedBox(height: 48),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded,
            color: AppColors.textPrimary, size: 24),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Gym Profile',
        style: AppTextStyles.h3,
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: _logoPath == null ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: _logoPath != null
                    ? Image.file(
                        File(_logoPath!),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          (_gymNameController.text.isNotEmpty
                                  ? _gymNameController.text.substring(0, 1)
                                  : 'G')
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        (_gymNameController.text.isNotEmpty
                                ? _gymNameController.text.substring(0, 1)
                                : 'G')
                            .toUpperCase(),
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
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.elevation2,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 18, color: AppColors.primary),
                  ),
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
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
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
          keyboardType: TextInputType.streetAddress,
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return AppButton(
      text: 'Save Changes',
      onPressed: _save,
    );
  }
}
