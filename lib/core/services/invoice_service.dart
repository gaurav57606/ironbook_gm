import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/data/repositories/sequence_repository.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';

abstract class IInvoiceService {
  Future<String> next();
  Future<void> reset(int year);
}

class InvoiceService implements IInvoiceService {
  final ISequenceRepository _sequenceRepo;
  final IClock _clock;

  InvoiceService(this._sequenceRepo, this._clock);

  @override
  Future<String> next() async {
    final now = _clock.now;
    final prefix = 'INV-${now.year}-';
    return await _sequenceRepo.getNextInvoiceNumber(prefix);
  }

  @override
  Future<void> reset(int year) async {
    final prefix = 'INV-$year-';
    await _sequenceRepo.reset(prefix);
  }

  static Future<void> generateAndShare({
    required dynamic member,
    required dynamic plan,
    required dynamic payment,
    required dynamic owner,
  }) async {
    // Stub implementation to fix build. 
    // Actual implementation would involve PDF generation and sharing.
    debugPrint('InvoiceService: generateAndShare called for ${member.name}');
  }
}

final invoiceServiceProvider = Provider<IInvoiceService>((ref) {
  final sequenceRepo = ref.watch(sequenceRepositoryProvider);
  final clock = ref.watch(clockProvider);
  return InvoiceService(sequenceRepo, clock);
});











