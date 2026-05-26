import 'dart:async';
import 'dart:io';
import 'monitoring_models.dart';
import 'supabase_monitoring_client.dart';
import 'monitoring_queue.dart';
import 'monitoring_retry_manager.dart';
import 'monitoring_constants.dart';

class MonitoringSender {
  final SupabaseMonitoringClient _client;
  final MonitoringQueue _queue;
  final MonitoringRetryManager _retryManager;
  
  Timer? _timer;
  bool _isProcessing = false;

  MonitoringSender(this._client, this._queue, this._retryManager) {
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (const bool.fromEnvironment('FLUTTER_TEST')) {
      return;
    }
    _timer = Timer.periodic(
      const Duration(seconds: MonitoringConstants.senderIntervalSeconds),
      (_) => _runBatchProcess(),
    );
  }

  /// Manually trigger a process if needed, but primary is Timer.
  void trigger() {
    if (_isProcessing) return;
    _runBatchProcess();
  }

  Future<void> _runBatchProcess() async {
    if (_isProcessing || _queue.isEmpty) return;
    
    _isProcessing = true;
    try {
      // Fetch batch of up to 20 events
      final List<MonitoringEvent> batch = _queue.fetchBatch(20);
      if (batch.isEmpty) return;

      final success = await _client.batchInsert(batch);
      
      final List<String> handledIds = [];
      
      for (final event in batch) {
        if (success) {
          handledIds.add(event.id);
          _retryManager.clear(event.id);
        } else {
          if (!_retryManager.shouldRetry(event)) {
            // Drop permanently failed events silently
            handledIds.add(event.id);
          }
        }
      }

      if (handledIds.isNotEmpty) {
        _queue.clear(handledIds);
      }
    } catch (_) {
      // Ignore failures safely
    } finally {
      _isProcessing = false;
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
