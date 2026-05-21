import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/core/providers/payment_provider.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;
import 'package:ironbook_gm/core/data/local/models/plan_model.dart' as model;
import 'package:ironbook_gm/core/services/logger_service.dart';
import 'package:ironbook_gm/core/monitoring/monitoring_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ironbook_gm/features/billing/providers/billing_provider.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';

class RegistrationState {
  final bool isSaving;
  final String? error;
  final String? successMemberId;

  RegistrationState({
    this.isSaving = false,
    this.error,
    this.successMemberId,
  });

  RegistrationState copyWith({
    bool? isSaving,
    String? error,
    String? successMemberId,
  }) {
    return RegistrationState(
      isSaving: isSaving ?? this.isSaving,
      error: error,
      successMemberId: successMemberId ?? this.successMemberId,
    );
  }
}

class MemberRegistrationController extends StateNotifier<RegistrationState> {
  final MemberNotifier _memberNotifier;
  final PaymentNotifier _paymentNotifier;
  final LoggerService _logger;
  final FirebaseAuth? _auth;

  MemberRegistrationController(
    this._memberNotifier,
    this._paymentNotifier,
    this._logger, [
    this._auth,
  ]) : super(RegistrationState());

  Future<void> registerMember({
    required String name,
    required String phone,
    required db.Plan selectedPlan,
    required DateTime joiningDate,
    required String gender,
    required String paymentMethod,
    int? age,
  }) async {
    if (state.isSaving) return;

    state = state.copyWith(isSaving: true, error: null);

    try {
      _logger.info(
        'Orchestrating registration for $name', 
        category: 'REGISTRATION'
      );
      
      // 1. Create Member
      final memberId = await _memberNotifier.addMember(
        name: name,
        phone: phone,
        planId: selectedPlan.id,
        joinDate: joiningDate,
        gender: gender,
        age: age,
      );
      
      // Monitoring Sidecar: Passive Archival
      final ownerUid = _auth?.currentUser?.uid;
      MonitoringService.logMembershipCreated(
        memberId, 
        selectedPlan.name, 
        selectedPlan.totalPrice,
        ownerUid: ownerUid,
        name: name,
        phone: phone,
        gender: gender,
        age: age,
        joinDate: joiningDate,
      );

      // 2. Record Initial Payment
      await _paymentNotifier.recordMemberPayment(
        memberId: memberId,
        plan: model.Plan.fromDrift(selectedPlan),
        method: paymentMethod,
        date: joiningDate,
      );
      
      // Monitoring Sidecar: Passive Archival
      MonitoringService.logPaymentSuccess(
        'reg_$memberId', 
        selectedPlan.totalPrice.toDouble(), 
        paymentMethod,
        ownerUid: ownerUid,
        memberId: memberId,
        memberName: name,
        planName: selectedPlan.name,
        joinDate: joiningDate,
      );
      
      // Production Observability: Structured Log
      _logger.info(
        'New member registered successfully: $memberId', 
        category: 'REGISTRATION'
      );

      // Business Analytics: Success
      _logger.logAnalyticsEvent('member_registered', {
        'member_id': memberId,
        'mode': 'offline_first', // Default mode for this app
      });

      state = state.copyWith(isSaving: false, successMemberId: memberId);
    } catch (e, stack) {
      debugPrint('REGISTRATION FAILED WITH ERROR: $e');
      _logger.error(
        'Member registration failed', 
        category: 'REGISTRATION', 
        error: e, 
        stackTrace: stack
      );

      // Business Analytics: Failure
      _logger.logAnalyticsEvent('member_registration_failed', {
        'error': e.toString(),
      });
      
      // Monitoring Sidecar: Passive Archival
      MonitoringService.logPaymentFailure('reg_fail_${DateTime.now().millisecondsSinceEpoch}', selectedPlan.totalPrice.toDouble(), e.toString());

      state = state.copyWith(
        isSaving: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = RegistrationState();
  }
}

final memberRegistrationControllerProvider =
    StateNotifierProvider<MemberRegistrationController, RegistrationState>((ref) {
  final memberNotifier = ref.watch(membersProvider.notifier);
  final paymentNotifier = ref.watch(paymentsProvider.notifier);
  final logger = ref.watch(loggerProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return MemberRegistrationController(memberNotifier, paymentNotifier, logger, auth);
});
