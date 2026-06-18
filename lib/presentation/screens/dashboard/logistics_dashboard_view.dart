import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../providers/providers.dart';
import '../../../domain/models/domain_models.dart';

class LogisticsDashboardView extends ConsumerStatefulWidget {
  const LogisticsDashboardView({super.key});

  @override
  ConsumerState<LogisticsDashboardView> createState() => _LogisticsDashboardViewState();
}

class _LogisticsDashboardViewState extends ConsumerState<LogisticsDashboardView> with SingleTickerProviderStateMixin {
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
    final allOrders = ref.watch(ordersProvider);

    // Operational statistics
    final totalLogisticsOrders = allOrders.length;
    final packedCount = allOrders.where((o) => o.status == 'Packed').length;
    final shippedCount = allOrders.where((o) => o.status == 'Shipped').length;
    final deliveredCount = allOrders.where((o) => o.status == 'Delivered').length;
    final ndrExceptions = allOrders.where((o) => o.status == 'RTO' || o.status == 'Returned').toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Logistics Partner Overview Scorecard
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LOGISTICS & NDR CONTROL NODE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                      ),
                    ),
                    const Icon(Icons.hub_outlined, color: AppTheme.darkPrimaryGold, size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'QAAFIYA FREIGHT ROUTER',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Connected Couriers: BlueDart, Delhivery, Shadowfax, Xpressbees',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLogisticsStat("Awaiting Pick", "$packedCount"),
                    _buildLogisticsStat("In-Transit", "$shippedCount"),
                    _buildLogisticsStat("Delivered", "$deliveredCount"),
                    _buildLogisticsStat("Exceptions", "${ndrExceptions.length}"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab selectors
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
                Tab(text: "Freight Hub"),
                Tab(text: "NDR Exceptions Console"),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Freight Hub list
                _buildFreightHubTab(allOrders, isDark),
                
                // Tab 2: NDR Console
                _buildNdrConsoleTab(ndrExceptions, isDark),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLogisticsStat(String label, String val) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          val,
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

  Widget _buildFreightHubTab(List<Order> orders, bool isDark) {
    // Show Packed (Awaiting pick) or Shipped (In-Transit) orders
    final activeShipments = orders.where((o) => o.status == 'Packed' || o.status == 'Shipped').toList();

    if (activeShipments.isEmpty) {
      return const Center(child: Text("No active freight shipments to coordinate. All clear!"));
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: activeShipments.length,
      itemBuilder: (context, idx) {
        final order = activeShipments[idx];
        final isPacked = order.status == 'Packed';
        
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isPacked ? AppTheme.colorWarning : AppTheme.colorInfo).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: TextStyle(
                          color: isPacked ? AppTheme.colorWarning : AppTheme.colorInfo,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ship To: ${order.customerName} (${order.city}, ${order.state} - ${order.pincode})',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                Text(
                  'Courier: ${order.courierPartner} • Tracking: ${order.trackingNumber}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Value: ₹${order.totalAmount} (${order.paymentMethod})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    if (isPacked)
                      ElevatedButton(
                        onPressed: () {
                          // Change to Shipped
                          ref.read(ordersProvider.notifier).save(
                            order.copyWith(
                              status: 'Shipped',
                              shipmentTimeline: [
                                ...order.shipmentTimeline,
                                ShipmentTimelineEntry(
                                  status: 'Shipped',
                                  title: 'In Transit',
                                  description: 'Package dispatched from warehouse via ${order.courierPartner}.',
                                  timestamp: DateTime.now().toIso8601String(),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.colorInfo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: const Text('DISPATCH SHIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          // Deliver order, update COD payment status if COD
                          final isCod = order.paymentMethod == 'COD';
                          ref.read(ordersProvider.notifier).save(
                            order.copyWith(
                              status: 'Delivered',
                              paymentStatus: isCod ? 'Collected' : 'Paid',
                              shipmentTimeline: [
                                ...order.shipmentTimeline,
                                ShipmentTimelineEntry(
                                  status: 'Delivered',
                                  title: 'Delivered Successfully',
                                  description: 'Item successfully delivered to customer. Payment collected.',
                                  timestamp: DateTime.now().toIso8601String(),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.colorSuccess,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: const Text('MARK DELIVERED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildNdrConsoleTab(List<Order> exceptions, bool isDark) {
    if (exceptions.isEmpty) {
      return const Center(child: Text("No delivery exceptions. Zero RTO alerts!"));
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: exceptions.length,
      itemBuilder: (context, idx) {
        final order = exceptions[idx];
        final isRto = order.status == 'RTO';
        
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.colorError.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.colorError,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Customer: ${order.customerName} • Pincode: ${order.pincode}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isRto 
                      ? 'RTO Alert: Delivery attempted 3 times. Address locked.'
                      : 'Returned Alert: Return request initiated by customer.',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.colorError),
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ref: ${order.trackingNumber}',
                      style: TextStyle(fontSize: 10, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    ),
                    if (isRto)
                      ElevatedButton(
                        onPressed: () {
                          // Reschedule delivery attempt, changing status back to Shipped
                          ref.read(ordersProvider.notifier).save(
                            order.copyWith(
                              status: 'Shipped',
                              shipmentTimeline: [
                                ...order.shipmentTimeline,
                                ShipmentTimelineEntry(
                                  status: 'Shipped',
                                  title: 'Delivery Rescheduled',
                                  description: 'Logistics partner coordinated with customer. New attempt generated.',
                                  timestamp: DateTime.now().toIso8601String(),
                                ),
                              ],
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Delivery attempt re-scheduled for ${order.orderNumber}!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.colorWarning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        child: const Text('RE-ATTEMPT DELIVERY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkBorder : AppTheme.lightSurfaceCard,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Awaiting RTO Return Pack',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
