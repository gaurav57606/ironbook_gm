import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/core/providers/payment_provider.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;
import 'package:ironbook_gm/core/data/local/models/plan_model.dart' as model;

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

  MemberRegistrationController(this._memberNotifier, this._paymentNotifier)
      : super(RegistrationState());

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
      debugPrint('[CONTROLLER] MemberRegistration: Orchestrating registration for $name');
      
      // 1. Create Member
      final memberId = await _memberNotifier.addMember(
        name: name,
        phone: phone,
        planId: selectedPlan.id,
        joinDate: joiningDate,
        gender: gender,
        age: age,
      );

      // 2. Record Initial Payment
      await _paymentNotifier.recordMemberPayment(
        memberId: memberId,
        plan: model.Plan.fromDrift(selectedPlan),
        method: paymentMethod,
        date: joiningDate,
      );

      state = state.copyWith(isSaving: false, successMemberId: memberId);
    } catch (e) {
      debugPrint('[CONTROLLER] MemberRegistration: Failed: $e');
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
  return MemberRegistrationController(memberNotifier, paymentNotifier);
});
