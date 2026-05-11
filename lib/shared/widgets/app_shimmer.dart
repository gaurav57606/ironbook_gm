import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

class AppShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.elevation2,
        borderRadius: borderRadius ?? AppRadius.radiusM,
      ),
    ).animate(
      autoPlay: !const bool.fromEnvironment('FLUTTER_TEST'),
      onPlay: (controller) => !const bool.fromEnvironment('FLUTTER_TEST') ? controller.repeat() : null,
    )
     .shimmer(
       duration: 1200.ms,
       color: AppColors.elevation3,
       angle: 45,
     );
  }

  static Widget circular({required double size}) {
    return AppShimmer(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }

  static Widget list({int count = 5}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            AppShimmer.circular(size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmer(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  AppShimmer(width: 150, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget card() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevation2,
        borderRadius: AppRadius.radiusXL,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppShimmer(width: 100, height: 14),
              AppShimmer(width: 60, height: 14),
            ],
          ),
          const SizedBox(height: 20),
          AppShimmer(width: 200, height: 24),
          const SizedBox(height: 12),
          AppShimmer(width: double.infinity, height: 12),
        ],
      ),
    ).animate(
      autoPlay: !const bool.fromEnvironment('FLUTTER_TEST'),
      onPlay: (controller) => !const bool.fromEnvironment('FLUTTER_TEST') ? controller.repeat() : null,
    )
     .shimmer(duration: 1200.ms, color: AppColors.elevation3);
  }
}
