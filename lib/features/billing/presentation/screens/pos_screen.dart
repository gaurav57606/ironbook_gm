import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../providers/billing_provider.dart';
import '../../../../core/data/local/models/product_model.dart';
import '../../../../core/data/local/models/sale_model.dart';
import '../../../../core/providers/sale_provider.dart';
import '../../../../core/data/repositories/product_repository.dart';
import '../../../../shared/widgets/sync_status_indicator.dart';
import '../../../../core/providers/notification_provider.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final Map<String, int> _cart = {};
  int get _cartItemCount =>
      _cart.values.fold(0, (sum, qty) => sum + qty);

  String _fmt(double v) =>
      v == v.truncateToDouble() ? '₹${v.toInt()}' : '₹${v.toStringAsFixed(2)}';

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
          body: SafeArea(
            top: true,
            child: Column(
              children: [
                _buildAppBar(),
                _buildCategoryFilter(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600;
                      if (isWide) {
                        final sidebarWidth = (constraints.maxWidth * 0.22)
                            .clamp(160.0, 280.0);
                        return Row(
                          children: [
                            Expanded(
                              child: _buildProductGrid(
                                products,
                                crossAxisCount: 3,
                              ),
                            ),
                            _buildCartSidebar(
                              products,
                              total,
                              overrideWidth: sidebarWidth,
                            ),
                          ],
                        );
                      }
                      // Mobile: full-width grid + floating cart button
                      return Stack(
                        children: [
                          _buildProductGrid(products),
                          if (_cartItemCount > 0)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: GestureDetector(
                                onTap: () => _showCartSheet(products),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.orange,
                                    borderRadius: AppRadius.radiusL,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.orange.withValues(alpha: 0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.shopping_cart_outlined,
                                        size: 16, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$_cartItemCount items · ₹${total.toInt()}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
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
      padding: const EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.xl,
        bottom: AppSpacing.s,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Supplements & Merch',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
          ),
          IconButton(
            onPressed: _showAddProductSheet,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.elevation2,
              padding: const EdgeInsets.all(8),
            ),
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => context.push('/notifications'),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.elevation2,
              padding: const EdgeInsets.all(8),
            ),
            icon: Consumer(
              builder: (context, ref, _) {
                final unread = ref.watch(unreadNotificationsCountProvider);
                return Stack(
                  children: [
                    const Icon(Icons.notifications_none_rounded, color: AppColors.text3, size: 20),
                    if (unread > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.bg, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          const SyncStatusIndicator(),
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

  Widget _buildProductGrid(List<Product> products, {int crossAxisCount = 2}) {
    final filtered = _selectedCategory == 'All' 
      ? products 
      : products.where((p) => p.category == _selectedCategory).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppColors.text3,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory == 'All'
                  ? 'No products yet'
                  : 'No $_selectedCategory products',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add products from Settings → Products',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.text3,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppSpacing.s,
        crossAxisSpacing: AppSpacing.s,
        childAspectRatio: crossAxisCount >= 3 ? 0.78 : 0.85,
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
                _fmt(product.price),
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

  Widget _buildCartSidebar(
    List<Product> products,
    double total, {
    double? overrideWidth,
  }) {
    return Container(
      width: overrideWidth ?? 140,
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
                    Text('₹${total.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.orange)),
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

  void _showCartSheet(List<Product> products) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          final total = _calculateTotal(products);
          return DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: AppColors.elevation1,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: AppRadius.radiusS,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Cart',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      )),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      children: _cart.entries.map((entry) {
                        final product = products
                            .firstWhereOrNull((p) => p.id == entry.key);
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
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.text2,
                                  )),
                              ),
                              Text('x${entry.value}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.text3,
                                )),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.text3,
                              )),
                            Text('₹${total.toInt()}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.orange,
                              )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          text: 'Charge',
                          isLoading: _isCharging,
                          onPressed: (_cart.isEmpty || _isCharging)
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _handleCheckout(products, total);
                                },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).viewPadding.bottom,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddProductSheet() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String selectedCategory = 'Supplements';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            decoration: const BoxDecoration(
              color: AppColors.elevation1,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
              border:
                  Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Add Product',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 16),
                // Category chips
                Row(
                  children:
                      ['Supplements', 'Merch'].map((cat) {
                    final active = selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setModalState(
                          () => selectedCategory = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.orange
                              : AppColors.elevation2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? AppColors.orange
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? Colors.white
                                : AppColors.text2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                // Name field
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(
                      color: AppColors.text, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    labelStyle: const TextStyle(
                        color: AppColors.text3, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.elevation2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.orange),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Price field
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: AppColors.text, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Price (₹)',
                    labelStyle: const TextStyle(
                        color: AppColors.text3, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.elevation2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.orange),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final price =
                          double.tryParse(priceCtrl.text.trim());
                      if (name.isEmpty || price == null || price <= 0) {
                        return;
                      }
                      final repo =
                          ref.read(productRepositoryProvider);
                      await repo.upsertProduct(
                        Product(
                          id: const Uuid().v4(),
                          name: name,
                          price: price,
                          category: selectedCategory,
                          iconCodePoint: selectedCategory == 'Supplements'
                              ? Icons.fitness_center.codePoint
                              : Icons.checkroom.codePoint,
                        ),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Save Product',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(ctx).viewPadding.bottom +
                      16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}









