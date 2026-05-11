import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/services/notification_service.dart';
import 'package:ironbook_gm/core/services/notification_gateway.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/services/logger_service.dart';

class MockNotificationGateway extends Mock implements NotificationGateway {}
class MockLogger extends Mock implements LoggerService {}

void main() {
  late MockNotificationGateway mockGateway;
  late MockLogger mockLogger;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  setUp(() async {
    mockGateway = MockNotificationGateway();
    mockLogger = MockLogger();
    
    container = ProviderContainer(
      overrides: [
        notificationGatewayProvider.overrideWithValue(mockGateway),
        loggerProvider.overrideWithValue(mockLogger),
      ],
    );

    when(() => mockGateway.init(any())).thenAnswer((_) async {});
    when(() => mockGateway.cancel(any())).thenAnswer((_) async {});
    when(() => mockGateway.show(
          any(),
          any(),
          any(),
          payload: any(named: 'payload'),
          androidDetails: any(named: 'androidDetails'),
          iosDetails: any(named: 'iosDetails'),
        )).thenAnswer((_) async {});
        
    await NotificationService.init(container);
  });

  group('NotificationService', () {
    test('init calls initialize on gateway', () async {
      // Re-init to verify
      await NotificationService.init(container);
      verify(() => mockGateway.init(any())).called(1);
    });

    test('sendMemberAlert sends correct notification for expired member', () async {
      final now = DateTime(2024, 1, 10);
      final snapshot = MemberSnapshot(
        memberId: 'm1',
        name: 'John Doe',
        joinDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2024, 1, 9), // Expired
      );

      await NotificationService.sendMemberAlert(
        snapshot: snapshot,
        dedupKey: 'm1_key',
        now: now,
      );

      final expectedId = 'm1_key'.hashCode.abs();
      verify(() => mockGateway.cancel(expectedId)).called(1);
      verify(() => mockGateway.show(
            expectedId,
            'John Doe — Membership Expired',
            'Tap to view member details',
            payload: any(named: 'payload'),
          )).called(1);
    });

    test('sendMemberAlert sends correct notification for expiring member', () async {
      final now = DateTime(2024, 1, 10);
      final snapshot = MemberSnapshot(
        memberId: 'm1',
        name: 'Jane Doe',
        joinDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2024, 1, 15), // Expiring in 5 days
      );

      await NotificationService.sendMemberAlert(
        snapshot: snapshot,
        dedupKey: 'm1_key',
        now: now,
      );

      final expectedId = 'm1_key'.hashCode.abs();
      verify(() => mockGateway.show(
            expectedId,
            'Jane Doe — Expiring in 5 days',
            'Tap to view member details',
            payload: any(named: 'payload'),
          )).called(1);
    });
  });
}
