import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

enum LogLevel { debug, info, warning, error, critical }

class LoggerService {
  FirebaseAnalytics? _analytics;
  bool _firebaseInitialized = false;
  
  // Buffer for logs generated before Firebase/Crashlytics is ready
  final List<({String message, LogLevel level, String category, Object? error, StackTrace? stackTrace})> _logBuffer = [];

  void setFirebaseInitialized(bool initialized) {
    _firebaseInitialized = initialized;
    if (initialized) {
      _analytics = FirebaseAnalytics.instance;
      _flushBuffer();
    }
  }

  void _flushBuffer() {
    if (_logBuffer.isEmpty) return;
    debugPrint('LoggerService: Flushing ${_logBuffer.length} buffered logs to Firebase...');
    for (final entry in _logBuffer) {
      _processLog(entry.message, entry.level, entry.category, entry.error, entry.stackTrace);
    }
    _logBuffer.clear();
  }

  void log(
    String message, {
    LogLevel level = LogLevel.info,
    String category = 'APP',
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final levelPrefix = level.name.toUpperCase();
    final categoryPrefix = category.toUpperCase();
    
    final formattedMessage = '[$timestamp] [$categoryPrefix] [$levelPrefix] $message';
    
    if (kDebugMode) {
      debugPrint(formattedMessage);
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
    
    if (!_firebaseInitialized) {
      // Buffer the log if it's important (info and above)
      if (level.index >= LogLevel.info.index) {
        _logBuffer.add((
          message: message,
          level: level,
          category: category,
          error: error,
          stackTrace: stackTrace,
        ));
        // Keep buffer size reasonable
        if (_logBuffer.length > 100) _logBuffer.removeAt(0);
      }
      return;
    }

    _processLog(message, level, category, error, stackTrace);
  }

  void _processLog(String message, LogLevel level, String category, Object? error, StackTrace? stackTrace) {
    try {
      // 1. Add breadcrumb to Crashlytics for context
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.log('[$category] $message');
      }

      // 2. Track significant events in Analytics
      if (level == LogLevel.info || level == LogLevel.warning) {
        _analytics?.logEvent(
          name: 'app_log',
          parameters: {
            'level': level.name,
            'category': category,
            'message': message.length > 100 ? message.substring(0, 100) : message,
          },
        );
      }

      // 3. Report errors to Crashlytics
      if (level == LogLevel.critical || level == LogLevel.error) {
        _reportToCrashlytics(message, error, stackTrace, isFatal: level == LogLevel.critical);
      }
    } catch (e) {
      debugPrint('LoggerService: Failed to report to Firebase: $e');
    }
  }

  void debug(String message, {String category = 'APP'}) => 
      log(message, level: LogLevel.debug, category: category);
  
  void info(String message, {String category = 'APP', Object? error, StackTrace? stackTrace}) => 
      log(message, level: LogLevel.info, category: category, error: error, stackTrace: stackTrace);
  
  void warn(String message, {String category = 'APP', Object? error, StackTrace? stackTrace}) => 
      log(message, level: LogLevel.warning, category: category, error: error, stackTrace: stackTrace);
  
  void error(String message, {String category = 'APP', Object? error, StackTrace? stackTrace}) => 
      log(message, level: LogLevel.error, category: category, error: error, stackTrace: stackTrace);
  
  void critical(String message, {String category = 'APP', Object? error, StackTrace? stackTrace}) => 
      log(message, level: LogLevel.critical, category: category, error: error, stackTrace: stackTrace);

  void _reportToCrashlytics(String message, Object? error, StackTrace? stackTrace, {bool isFatal = false}) {
    if (kIsWeb) return;
    
    try {
      if (error != null) {
        FirebaseCrashlytics.instance.recordError(
          error, 
          stackTrace, 
          reason: message,
          fatal: isFatal,
        );
      } else {
        // Report as non-fatal exception with the message as the "error"
        FirebaseCrashlytics.instance.recordError(
          message,
          stackTrace,
          reason: 'Manual Log Report',
          fatal: isFatal,
        );
      }
    } catch (e) {
      debugPrint('LoggerService: Crashlytics reporting failed: $e');
    }
  }

  Future<void> setUserId(String userId) async {
    if (!_firebaseInitialized || kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      await _analytics?.setUserId(id: userId);
    } catch (e) {
      debugPrint('LoggerService: Failed to set user ID in Firebase: $e');
    }
  }
}

final loggerProvider = Provider<LoggerService>((ref) => LoggerService());
