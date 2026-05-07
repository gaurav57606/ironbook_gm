import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/core/services/invoice_service.dart';
import 'package:ironbook_gm/core/data/repositories/sequence_repository.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';

class MockSequenceRepository extends Mock implements ISequenceRepository {}
class MockClock extends Mock implements IClock {}

void main() {
  late InvoiceService invoiceService;
  late MockSequenceRepository mockSequenceRepo;
  late MockClock mockClock;

  setUp(() {
    mockSequenceRepo = MockSequenceRepository();
    mockClock = MockClock();
    invoiceService = InvoiceService(mockSequenceRepo, mockClock);
  });

  test('next() should call getNextInvoiceNumber with correct prefix', () async {
    final now = DateTime(2024, 1, 1);
    when(() => mockClock.now).thenReturn(now);
    when(() => mockSequenceRepo.getNextInvoiceNumber(any()))
        .thenAnswer((_) async => 'INV-2024-001');

    final result = await invoiceService.next();

    expect(result, 'INV-2024-001');
    verify(() => mockSequenceRepo.getNextInvoiceNumber('INV-2024-')).called(1);
  });

  test('reset() should call reset with correct prefix', () async {
    when(() => mockSequenceRepo.reset(any())).thenAnswer((_) async => {});

    await invoiceService.reset(2024);

    verify(() => mockSequenceRepo.reset('INV-2024-')).called(1);
  });
}
