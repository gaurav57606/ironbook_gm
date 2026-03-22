import 'package:hive/hive.dart';

class InvoiceNumberGenerator {
  static String next(int year) {
    final box = Hive.box<int>('invoice_sequences');
    final key = 'seq_$year';
    final current = box.get(key, defaultValue: 0)!;
    final nextValue = current + 1;
    
    // Write incremented value FIRST, use it after — prevents reuse on crash.
    box.put(key, nextValue); 
    
    return 'INV-$year-${nextValue.toString().padLeft(4, '0')}';
  }
}
