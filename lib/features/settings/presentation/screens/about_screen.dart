import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import 'package:go_router/go_router.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text, size: 20),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'About IronBook GM',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.orange, AppColors.orangeD],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.fitness_center, size: 45, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'IronBook GM',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
              ),
              const Text(
                'v2.4.0',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text3),
              ),
              const SizedBox(height: 48),
              const Text(
                'The ultimate gym management suite.',
                style: TextStyle(fontSize: 13, color: AppColors.text2),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Professionally designed for gym owners who value stability, security, and performance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.text3, height: 1.5),
                ),
              ),
              const Spacer(),
              const Text(
                'Made by Antigravity',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.orange),
              ),
              const SizedBox(height: 8),
              const Text(
                '© 2026 IronBook GM. All rights reserved.',
                style: TextStyle(fontSize: 9, color: AppColors.text3),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
