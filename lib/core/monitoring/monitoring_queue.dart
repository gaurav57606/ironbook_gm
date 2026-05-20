import 'monitoring_models.dart';

class MonitoringQueue {
  final List<MonitoringEvent> _events = [];

  /// Adds an event to the queue.
  void add(MonitoringEvent event) {
    _events.add(event);
  }

  /// Fetches a batch of events from the queue.
  List<MonitoringEvent> fetchBatch(int count) {
    if (_events.isEmpty) return [];
    return _events.take(count).toList();
  }

  /// Removes events that have been successfully sent.
  void clear(List<String> eventIds) {
    _events.removeWhere((event) => eventIds.contains(event.id));
  }

  bool get isEmpty => _events.isEmpty;
  int get length => _events.length;
}
