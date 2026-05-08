import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../services/logger_service.dart';

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
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden: 
        _handleBackground();
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
    _ref.read(loggerProvider).info('App moved to background/inactive. Locking session.', category: 'LIFECYCLE');
    _ref.read(authProvider.notifier).lock();
  }

  void _handleForeground() {
    _ref.read(loggerProvider).info('App returned to foreground.', category: 'LIFECYCLE');
  }

  void _handleDetach() {
    _ref.read(loggerProvider).info('App detached.', category: 'LIFECYCLE');
  }
}
