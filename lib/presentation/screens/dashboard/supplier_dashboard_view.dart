import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../providers/providers.dart';
import '../../../domain/models/domain_models.dart';

class SupplierDashboardView extends ConsumerStatefulWidget {
  const SupplierDashboardView({super.key});

  @override
  ConsumerState<SupplierDashboardView> createState() => _SupplierDashboardViewState();
}

class _SupplierDashboardViewState extends ConsumerState<SupplierDashboardView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final allProducts = ref.watch(productsProvider);
    final allOrders = ref.watch(ordersProvider);
    final suppliers = ref.watch(suppliersProvider);

    if (suppliers.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.darkPrimaryGold));
    }

    // Pick a mock supplier for active node (e.g. S200 - Jaipur Blockprints Ltd)
    final activeSupplier = suppliers[0];

    // Filter products supplied by this supplier
    final supplierProducts = allProducts.where((p) => p.supplierId == activeSupplier.id).toList();

    // Filter order items that correspond to this supplier's products
    final supplierProductIds = supplierProducts.map((p) => p.id).toSet();
    final supplierOrders = allOrders.where((o) {
      return o.items.any((item) => supplierProductIds.contains(item.productId));
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Supplier Scorecard Card
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SUPPLIER CONSOLE NODE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.colorSuccess.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        activeSupplier.status.toUpperCase(),
                        style: const TextStyle(color: AppTheme.colorSuccess, fontWeight: FontWeight.bold, fontSize: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  activeSupplier.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Category: ${activeSupplier.category} • Contact: ${activeSupplier.contactPerson}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetric("Rating", "${activeSupplier.rating} ⭐"),
                    _buildMetric("Lead Time", "${activeSupplier.leadTime} Days"),
                    _buildMetric("Reliability", "${activeSupplier.reliabilityScore}%"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Bar selector
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard,
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
              labelColor: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
              unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: "Order Pipeline"),
                Tab(text: "Stock Manager"),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Orders Pipeline
                _buildOrdersTab(supplierOrders, isDark),
                
                // Tab 2: Stock Manager
                _buildStockTab(supplierProducts, isDark),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab(List<Order> orders, bool isDark) {
    // Filter pending/processing supplier orders
    final pendingFulfillment = orders.where((o) => o.status == 'Pending' || o.status == 'Processing').toList();

    if (pendingFulfillment.isEmpty) {
      return const Center(child: Text("No pending supplier fulfillments. All clear!"));
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: pendingFulfillment.length,
      itemBuilder: (context, idx) {
        final order = pendingFulfillment[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      order.status.toUpperCase(),
                      style: const TextStyle(color: AppTheme.colorWarning, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Destination: ${order.city}, ${order.state}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const Divider(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: order.items.length,
                  itemBuilder: (c, i) {
                    final item = order.items[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        '• ${item.productName} (x${item.quantity})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Change order status to Packed / Dispatched
                        ref.read(ordersProvider.notifier).save(
                          order.copyWith(
                            status: 'Packed',
                            shipmentTimeline: [
                              ...order.shipmentTimeline,
                              ShipmentTimelineEntry(
                                status: 'Packed',
                                title: 'Packed by Supplier',
                                description: 'Supplier completed quality check and packed items.',
                                timestamp: DateTime.now().toIso8601String(),
                              ),
                            ],
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Order ${order.orderNumber} marked as Packed & ready!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkPrimaryGold,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('DISPATCH PACK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockTab(List<Product> products, bool isDark) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, idx) {
        final prod = products[idx];
        final lowStock = prod.inventoryCount < 50;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prod.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SKU: ${prod.sku} • Cost: ₹${prod.costPrice}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Stock Count: ${prod.inventoryCount}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: lowStock ? AppTheme.colorError : AppTheme.colorSuccess,
                            ),
                          ),
                          if (lowStock) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.colorError.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LOW STOCK',
                                style: TextStyle(color: AppTheme.colorError, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _showRestockDialog(context, prod);
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.darkPrimaryGold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRestockDialog(BuildContext context, Product prod) {
    final controller = TextEditingController(text: '${prod.inventoryCount}');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Restock: ${prod.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter new inventory stock count:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  hintText: 'e.g. 250',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(controller.text) ?? prod.inventoryCount;
                ref.read(productsProvider.notifier).save(
                  prod.copyWith(inventoryCount: qty),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Stock count updated to $qty for ${prod.name}!')),
                );
              },
              child: const Text('UPDATE'),
            ),
          ],
        );
      },
    );
  }
}
