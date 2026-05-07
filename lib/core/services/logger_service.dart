import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

enum LogLevel { debug, info, warning, error, critical }

class LoggerService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  void log(String message, {LogLevel level = LogLevel.info, Object? error, StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    final prefix = level.name.toUpperCase();
    
    final formattedMessage = '[$timestamp] [$prefix] $message';
    
    if (kDebugMode) {
      debugPrint(formattedMessage);
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
    
    // Track significant events in Analytics
    if (level == LogLevel.info || level == LogLevel.warning) {
      _analytics.logEvent(
        name: 'app_log',
        parameters: {
          'level': level.name,
          'message': message.length > 100 ? message.substring(0, 100) : message,
        },
      );
    }

    if (level == LogLevel.critical || level == LogLevel.error) {
      _reportToCrashlytics(message, error, stackTrace, isFatal: level == LogLevel.critical);
    }
  }

  void debug(String message) => log(message, level: LogLevel.debug);
  void info(String message) => log(message, level: LogLevel.info);
  void warn(String message) => log(message, level: LogLevel.warning);
  void error(String message, [Object? error, StackTrace? stackTrace]) => 
      log(message, level: LogLevel.error, error: error, stackTrace: stackTrace);
  void critical(String message, [Object? error, StackTrace? stackTrace]) => 
      log(message, level: LogLevel.critical, error: error, stackTrace: stackTrace);

  void _reportToCrashlytics(String message, Object? error, StackTrace? stackTrace, {bool isFatal = false}) {
    if (kIsWeb) return;
    
    FirebaseCrashlytics.instance.log(message);
    if (error != null) {
      FirebaseCrashlytics.instance.recordError(
        error, 
        stackTrace, 
        reason: message,
        fatal: isFatal,
      );
    }
  }

  Future<void> setUserId(String userId) async {
    if (kIsWeb) return;
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    await _analytics.setUserId(id: userId);
  }
}

final loggerProvider = Provider<LoggerService>((ref) => LoggerService());
