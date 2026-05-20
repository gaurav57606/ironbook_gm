import 'monitoring_constants.dart';
import 'monitoring_models.dart';

class MonitoringRetryManager {
  final Map<String, int> _retryCounts = {};

  /// Returns true if the event should be retried.
  bool shouldRetry(MonitoringEvent event) {
    final count = _retryCounts[event.id] ?? 0;
    
    if (count < MonitoringConstants.maxRetries) {
      _retryCounts[event.id] = count + 1;
      return true;
    }
    
    // Capped reached, drop silently
    _retryCounts.remove(event.id);
    return false;
  }
  
  void clear(String eventId) {
    _retryCounts.remove(eventId);
  }
}
