import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/core/data/repositories/member_repository.dart';
import 'package:ironbook_gm/core/data/repositories/payment_repository.dart';
import 'package:ironbook_gm/core/data/repositories/plan_repository.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/repositories/owner_repository.dart';
import 'package:ironbook_gm/core/data/repositories/settings_repository.dart';
import 'package:ironbook_gm/core/data/repositories/preferences_repository.dart';
import 'package:ironbook_gm/core/data/repositories/product_repository.dart';
import 'package:ironbook_gm/core/data/repositories/sequence_repository.dart';
import 'package:ironbook_gm/core/data/repositories/sale_repository.dart';
import 'package:ironbook_gm/features/billing/data/billing_repository.dart';

class MockMemberRepository extends Mock implements IMemberRepository {}
class MockPaymentRepository extends Mock implements IPaymentRepository {}
class MockPlanRepository extends Mock implements IPlanRepository {}
class MockEventRepository extends Mock implements IEventRepository {}
class MockOwnerRepository extends Mock implements IOwnerRepository {}
class MockSettingsRepository extends Mock implements ISettingsRepository {}
class MockPreferencesRepository extends Mock implements IPreferencesRepository {}
class MockProductRepository extends Mock implements IProductRepository {}
class MockSequenceRepository extends Mock implements ISequenceRepository {}
class MockSaleRepository extends Mock implements ISaleRepository {}
class MockBillingRepository extends Mock implements IBillingRepository {}

MockMemberRepository createMockMemberRepository() {
  final repo = MockMemberRepository();
  when(() => repo.getAllMembers()).thenAnswer((_) async => []);
  return repo;
}

MockPaymentRepository createMockPaymentRepository() {
  final repo = MockPaymentRepository();
  when(() => repo.getAllPayments()).thenAnswer((_) async => []);
  return repo;
}

MockBillingRepository createMockBillingRepository() {
  final repo = MockBillingRepository();
  // Add default behaviors if needed
  return repo;
}
