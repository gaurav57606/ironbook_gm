import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/models/domain_event_model.dart';

/// Lightweight Event Bus for internal domain events.
class EventBus {
  final _controller = StreamController<DomainEvent>.broadcast();

  Stream<DomainEvent> get stream => _controller.stream;

  void publish(DomainEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}

/// Riverpod provider for the EventBus.
final eventBusProvider = Provider<EventBus>((ref) {
  final bus = EventBus();
  ref.onDispose(bus.dispose);
  return bus;
});
