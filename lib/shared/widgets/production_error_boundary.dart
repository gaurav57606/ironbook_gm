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
                const SizedBox(height: AppSpacing.m),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: AppRadius.radiusS,
                  ),
                  child: Text(
                    'Diagnostic Code: ${errorDetails.exception.hashCode.toRadixString(16).toUpperCase()}',
                    style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        // Navigate to home or root
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white10),
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.l,
                          vertical: AppSpacing.m,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusM,
                        ),
                      ),
                      child: const Text('Return Home'),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    ElevatedButton(
                      onPressed: () {
                        // Force a re-build of the entire widget tree
                        // In many cases, a simple rebuild can recover from a transient UI error
                        (context as Element).markNeedsBuild();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
