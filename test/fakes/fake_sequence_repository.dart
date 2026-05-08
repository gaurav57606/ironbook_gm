import 'package:hive/hive.dart';
import 'package:ironbook_gm/core/data/repositories/sequence_repository.dart';
import 'package:ironbook_gm/core/data/local/models/invoice_sequence.dart';

/// Legacy-compatible fake repository that wraps a Hive box.
/// Used to transition tests from direct Box usage to ISequenceRepository.
class FakeSequenceRepository implements ISequenceRepository {
  final Box<InvoiceSequence> _box;

  FakeSequenceRepository(this._box);

  @override
  Future<String> getNextInvoiceNumber(String prefix) async {
    final sequence = _box.get('active_seq') ?? InvoiceSequence(prefix: prefix, nextNumber: 1);
    final currentNumber = sequence.nextNumber;
    
    // Increment and save
    sequence.nextNumber = currentNumber + 1;
    await _box.put('active_seq', sequence);
    
    return '$prefix${currentNumber.toString().padLeft(4, '0')}';
  }

  @override
  Future<void> reset(String prefix) async {
    await _box.put('active_seq', InvoiceSequence(prefix: prefix, nextNumber: 1));
  }
}
