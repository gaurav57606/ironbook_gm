import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/data/local/models/invoice_sequence.dart';
import 'package:ironbook_gm/core/utils/clock.dart';
import 'package:ironbook_gm/providers/base_providers.dart';

abstract class IInvoiceService {
  Future<String> next();
  Future<void> reset(int year);
}

class InvoiceService implements IInvoiceService {
  final Box<InvoiceSequence> _box;
  final IClock _clock;

  InvoiceService(this._box, this._clock);

  @override
  Future<String> next() async {
    final now = _clock.now;
    final year = now.year;
    
    // 1. Transactional Read-Update-Write
    var seq = _box.get('active_seq');
    
    // Auto-create if none exists
    seq ??= InvoiceSequence(prefix: 'INV-$year-', nextNumber: 1);


    final currentNumber = seq.nextNumber;
    seq.nextNumber++;
    
    // 2. Persist BEFORE returning
    await _box.put('active_seq', seq);
    
    return '${seq.prefix}${currentNumber.toString().padLeft(4, '0')}';
  }

  @override
  Future<void> reset(int year) async {
    await _box.put('active_seq', InvoiceSequence(prefix: 'INV-$year-', nextNumber: 1));
  }
}

final invoiceServiceProvider = Provider<IInvoiceService>((ref) {
  final box = Hive.box<InvoiceSequence>('invoice_sequences');
  final clock = ref.watch(clockProvider);
  return InvoiceService(box, clock);
});
