import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LogLevel { debug, info, warning, error, critical }

class LoggerService {
  void log(String message, {LogLevel level = LogLevel.info, Object? error, StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    final prefix = level.name.toUpperCase();
    
    final formattedMessage = '[$timestamp] [$prefix] $message';
    
    if (kDebugMode) {
      debugPrint(formattedMessage);
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
    
    // In a production app, you would send this to Sentry, Firebase Crashlytics, etc.
    if (level == LogLevel.critical || level == LogLevel.error) {
      _reportToCrashlytics(message, error, stackTrace);
    }
  }

  void debug(String message) => log(message, level: LogLevel.debug);
  void info(String message) => log(message, level: LogLevel.info);
  void warn(String message) => log(message, level: LogLevel.warning);
  void error(String message, [Object? error, StackTrace? stackTrace]) => 
      log(message, level: LogLevel.error, error: error, stackTrace: stackTrace);

  void _reportToCrashlytics(String message, Object? error, StackTrace? stackTrace) {
    // Stub for Firebase Crashlytics
    // if (!kIsWeb) FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
  }
}

final loggerProvider = Provider<LoggerService>((ref) => LoggerService());
