import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'member_provider.dart';
import '../services/logger_service.dart';
import '../services/sync_coordinator.dart';

/// Provider that initializes and manages the application lifecycle observer.
/// It should be "watched" at the top of the widget tree (e.g. in App).
final appLifecycleProvider = Provider<AppLifecycleObserver>((ref) {
  final observer = AppLifecycleObserver(ref);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));
  return observer;
});

class AppLifecycleObserver extends WidgetsBindingObserver {
  final Ref _ref;

  AppLifecycleObserver(this._ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _ref.read(loggerProvider).info('App lifecycle state changed to: $state', category: 'LIFECYCLE');
    
    switch (state) {
      case AppLifecycleState.paused:
        _handleBackground();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Ignore these for locking to prevent screenshot/overlay issues
        break;
      case AppLifecycleState.resumed:
        _handleForeground();
        break;
      case AppLifecycleState.detached:
        _handleDetach();
        break;
    }
  }

  void _handleBackground() {
    _ref.read(loggerProvider).info('App moved to background. Locking session.', category: 'LIFECYCLE');
    _ref.read(authProvider.notifier).lock();
  }

  void _handleForeground() {
    final logger = _ref.read(loggerProvider);
    logger.info('App returned to foreground.', category: 'LIFECYCLE');

    // 1. Invalidate clock-tick provider to refresh membership status badges
    _ref.invalidate(dailyClockTickProvider);

    // 2. Trigger foreground sync
    try {
      _ref.read(syncCoordinatorProvider).triggerSync();
      logger.info(
        'Foreground sync triggered via SyncCoordinator.',
        category: 'LIFECYCLE',
      );
    } catch (e) {
      logger.warn(
        'Foreground sync trigger failed (non-fatal): $e',
        category: 'LIFECYCLE',
      );
    }
  }

  void _handleDetach() {
    _ref.read(loggerProvider).info('App detached.', category: 'LIFECYCLE');
  }
}
