import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';

class InvoiceScreen extends ConsumerWidget {
  final String id;
  const InvoiceScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(LucideIcons.share2)),
          IconButton(onPressed: () {}, icon: const Icon(LucideIcons.download)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4), // Paper-like feel
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Divider(height: 48, thickness: 1),
              _buildCustomerInfo(),
              const SizedBox(height: 32),
              _buildItemsTable(),
              const SizedBox(height: 32),
              _buildTotals(),
              const SizedBox(height: 64),
              Center(
                child: Text('THANK YOU!',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IRONBOOK GM', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Raj\'s Fitness Center', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('INVOICE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24)),
            Text('INV-2026-0421', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BILL TO', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Rajesh Kumar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            Text('+91 98765 43210', style: TextStyle(color: Colors.black, fontSize: 12)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('DATE', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            Text('12 Mar 2026', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsTable() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
          child: const Row(
            children: [
              Expanded(child: Text('DESCRIPTION', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
              Text('AMOUNT', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Standard Plan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                Text('1 Month membership access', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            )),
            Text('₹2,118.64', style: TextStyle(color: Colors.black)),
          ],
        ),
      ],
    );
  }

  Widget _buildTotals() {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 150,
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('₹2,118.64', style: TextStyle(color: Colors.black, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('GST (18%)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('₹381.36', style: TextStyle(color: Colors.black, fontSize: 12)),
              ],
            ),
            const Divider(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                Text('₹2,500.00', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
