import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/bootstrap_provider.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier2Status = ref.watch(tier2StatusProvider);

    return StatusBarWrapper(
      child: Scaffold(
        body: Column(
          children: [
            if (tier2Status == Tier2Status.degraded)
              MaterialBanner(
                backgroundColor: Colors.orange.shade900,
                content: const Text(
                  'Running in Degraded Mode (Offline). Cloud sync is unavailable.',
                  style: TextStyle(color: Colors.white),
                ),
                leading: const Icon(Icons.cloud_off, color: Colors.white),
                actions: [
                  TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                    child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            Expanded(child: navigationShell),
          ],
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _onTap,
        ),
      ),
    );
  }
}
