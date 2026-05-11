import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/bootstrap_provider.dart';
import '../../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../../shared/widgets/sync_status_indicator.dart';

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

    return Scaffold(
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            if (tier2Status == Tier2Status.degraded)
              MaterialBanner(
                backgroundColor: Colors.orange.shade900,
                content: const Text(
                  'Running in Local Mode. Cloud sync delayed.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}









