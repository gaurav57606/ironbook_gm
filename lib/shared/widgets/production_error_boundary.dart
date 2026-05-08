import 'package:flutter/material.dart';
import 'package:ironbook_gm/core/constants/app_spacing.dart';
import 'package:ironbook_gm/core/constants/app_radius.dart';

class ProductionErrorBoundary extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const ProductionErrorBoundary({
    super.key,
    required this.errorDetails,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Slate 900
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                 const SizedBox(height: AppSpacing.s),
                Text(
                  'A visual error occurred in this section. We\'ve logged the details and our team will look into it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: () {
                    // In a real app, we might try to trigger a rebuild or navigate back
                    // For now, we just suggest restarting if it's a major screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.m,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusM,
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
