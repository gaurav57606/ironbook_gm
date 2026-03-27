import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/data/local/models/invoice_sequence.dart';

abstract class IInvoiceService {
  Future<String> next();
  Future<void> reset(int year);
}

class InvoiceService implements IInvoiceService {
  final Box<InvoiceSequence> _box;

  InvoiceService(this._box);

  @override
  Future<String> next() async {
    final now = DateTime.now();
    final year = now.year;
    
    // 1. Transactional Read-Update-Write
    var seq = _box.get('active_seq');
    
    // Auto-create or Auto-reset on year change
    if (seq == null || !seq.prefix.contains('INV-$year-')) {
      seq = InvoiceSequence(prefix: 'INV-$year-', nextNumber: 1);
    }

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
  final box = Hive.box<InvoiceSequence>('invoice_seq');
  return InvoiceService(box);
});
