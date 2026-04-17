import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../data/local/models/owner_profile_model.dart';
import '../../../../data/local/models/domain_event_model.dart';
import '../../../../data/repositories/event_repository.dart';

class OwnershipTransferScreen extends ConsumerStatefulWidget {
  const OwnershipTransferScreen({super.key});

  @override
  ConsumerState<OwnershipTransferScreen> createState() => _OwnershipTransferScreenState();
}

class _OwnershipTransferScreenState extends ConsumerState<OwnershipTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _gymNameController;
  late TextEditingController _newEmailController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final owner = ref.read(authProvider).owner;
    _nameController = TextEditingController(text: owner?.ownerName);
    _phoneController = TextEditingController(text: owner?.phone);
    _gymNameController = TextEditingController(text: owner?.gymName);
    _newEmailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _gymNameController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevation1,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Confirm Transfer', style: AppTextStyles.h3),
        content: Text(
          'This will update the registered business owner details and record an official handover event. '
          'Proceed with transferring this gym profile?',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Transfer', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final updated = OwnerProfile(
        gymName: _gymNameController.text.trim(),
        ownerName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: ref.read(authProvider).owner?.address ?? '',
      );

      // 1. Update local state
      await ref.read(authProvider.notifier).updateOwner(updated);

      // 2. record Handover Event
      final event = DomainEvent(
        entityId: 'owner',
        eventType: EventType.ownershipTransferred,
        deviceId: 'manual-handover',
        deviceTimestamp: DateTime.now(),
        payload: {
          'previousOwner': ref.read(authProvider).owner?.ownerName ?? 'Unknown',
          'newOwner': updated.ownerName,
          'gymName': updated.gymName,
          'newEmail': _newEmailController.text.trim(),
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
      await ref.read(eventRepositoryProvider).persist(event);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ownership transferred successfully.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
            'Transfer Ownership',
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWarningCard(),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 16),
                    child: Text(
                      'NEW OWNER DETAILS',
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  AppTextField(
                    label: 'Full Name',
                    hint: 'Enter New Owner Name',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  AppTextField(
                    label: 'Phone Number',
                    hint: 'Enter Phone Number',
                    controller: _phoneController,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  AppTextField(
                    label: 'New Owner Email',
                    hint: 'For record keeping',
                    controller: _newEmailController,
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v?.contains('@') != true ? 'Valid email required' : null,
                  ),
                  const SizedBox(height: 48),
                  AppButton(
                    text: 'Complete Handover',
                    isLoading: _isProcessing,
                    onPressed: _handleTransfer,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Handover is permanent and logged in history.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Transferring ownership will update the legal profile and business entity details. This action is irreversible.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
