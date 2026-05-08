import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/status_bar_wrapper.dart';
import '../../providers/billing_provider.dart';
import '../../../../core/data/local/models/product_model.dart';
import '../../../../core/data/local/models/sale_model.dart';
import '../../../../core/providers/sale_provider.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final Map<String, int> _cart = {};
  String _selectedCategory = 'All';

  double _calculateTotal(List<Product> products) {
    double total = 0;
    _cart.forEach((productId, qty) {
      final product = products.firstWhereOrNull((p) => p.id == productId);
      if (product != null) {
        total += product.price * qty;
      }
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (products) {
        final total = _calculateTotal(products);
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: StatusBarWrapper(
            child: Column(
              children: [
                _buildAppBar(),
                _buildCategoryFilter(),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildProductGrid(products)),
                      _buildCartSidebar(products, total),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.s),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text, size: 20),
          ),
          AppSpacing.gapS,
          const Text(
            'Supplements & Merch',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Supplements', 'Merch'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.s),
      child: Row(
        children: categories.map((cat) {
          bool active = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.s),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
              decoration: BoxDecoration(
                color: active ? AppColors.orange : AppColors.elevation2,
                borderRadius: AppRadius.radiusL,
                border: Border.all(color: active ? AppColors.orange : AppColors.border),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? Colors.white : AppColors.text2,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    final filtered = _selectedCategory == 'All' 
      ? products 
      : products.where((p) => p.category == _selectedCategory).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.s,
        crossAxisSpacing: AppSpacing.s,
        childAspectRatio: 0.85,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final product = filtered[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.elevation2,
            borderRadius: AppRadius.radiusXL,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                product.category == 'Supplements' ? Icons.fitness_center : 
                product.category == 'Merch' ? Icons.checkroom : 
                Icons.shopping_bag, 
                color: AppColors.orange, size: 32),
              AppSpacing.gapM,
              Text(
                product.name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text),
              ),
              AppSpacing.gapXS,
              Text(
                '₹${product.price}',
                style: const TextStyle(fontSize: 10, color: AppColors.text3),
              ),
              AppSpacing.gapM,
              InkWell(
                onTap: () => setState(() => _cart[product.id] = (_cart[product.id] ?? 0) + 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.orange),
                    borderRadius: AppRadius.radiusS,
                  ),
                  child: const Text('Add', style: TextStyle(color: AppColors.orange, fontSize: 9, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isCharging = false;

  Widget _buildCartSidebar(List<Product> products, double total) {
    return Container(
      width: 140,
      decoration: const BoxDecoration(
        color: AppColors.elevation1,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(AppSpacing.m),
            child: Text('Cart', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
          ),
          const Divider(color: AppColors.border, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.s),
              children: _cart.entries.map((entry) {
                final product = products.firstWhereOrNull((p) => p.id == entry.key);
                if (product == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(product.name, 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9, color: AppColors.text2),
                        ),
                      ),
                      Text('x${entry.value}', style: const TextStyle(fontSize: 9, color: AppColors.text3)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 10, color: AppColors.text3)),
                    Text('₹$total', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.orange)),
                  ],
                ),
                AppSpacing.gapM,
                AppButton(
                  text: 'Charge',
                  isLoading: _isCharging,
                  onPressed: (_cart.isEmpty || _isCharging) ? null : () => _handleCheckout(products, total),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckout(List<Product> products, double total) async {
    setState(() => _isCharging = true);
    
    try {
      final List<SaleItem> items = [];
      _cart.forEach((productId, qty) {
        final product = products.firstWhereOrNull((p) => p.id == productId);
        if (product != null) {
          items.add(SaleItem(
            productId: productId,
            memberId: 'walk-in',
            productName: product.name,
            price: product.price,
            quantity: qty,
          ));
        }
      });

      await ref.read(billingNotifierProvider).recordProductSale(
        items: items,
        method: 'Cash',
        total: total,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale Recorded Successfully')),
        );
        setState(() {
          _cart.clear();
          _isCharging = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCharging = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}









