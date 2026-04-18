import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bootstrap_provider.dart';
import '../../data/sync_worker.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(tier2StatusProvider);
    final unsyncedCount = ref.watch(unsyncedCountProvider).asData?.value ?? 0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildIndicator(context, status, unsyncedCount),
    );
  }

  Widget _buildIndicator(BuildContext context, Tier2Status status, int unsynced) {
    if (status == Tier2Status.pending) {
      return const _Pill(
        key: ValueKey('pending'),
        label: 'Connecting...',
        icon: Icons.sync,
        color: Colors.blue,
        isAnimated: true,
      );
    }

    if (status == Tier2Status.degraded) {
      return const _Pill(
        key: ValueKey('degraded'),
        label: 'Local Mode',
        icon: Icons.cloud_off,
        color: Colors.orange,
      );
    }

    if (unsynced > 0) {
      return _Pill(
        key: const ValueKey('syncing'),
        label: 'Syncing $unsynced',
        icon: Icons.cloud_upload,
        color: Colors.blue,
        isAnimated: true,
      );
    }

    return const _Pill(
      key: ValueKey('synced'),
      label: 'Synced',
      icon: Icons.check_circle,
      color: Colors.green,
    );
  }
}

class _Pill extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isAnimated;

  const _Pill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.isAnimated = false,
  });

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isAnimated) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _Pill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimated && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isAnimated && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: widget.isAnimated ? _controller : const AlwaysStoppedAnimation(0),
            child: Icon(widget.icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
