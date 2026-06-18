import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../providers/providers.dart';
import '../../../domain/models/domain_models.dart';

class ShipmentsScreen extends ConsumerStatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  ConsumerState<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends ConsumerState<ShipmentsScreen> {
  String _searchQuery = "";
  String _statusFilter = "All";

  @override
  Widget build(BuildContext context) {
    final activeEntre = ref.watch(currentEntrepreneurProvider);
    final allOrders = ref.watch(ordersProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    if (activeEntre == null) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.darkPrimaryGold)),
      );
    }

    // Filter shipments belonging to active founder orders
    final entreOrders = allOrders.where((o) => o.entrepreneurId == activeEntre.id).toList();

    final filteredShipments = entreOrders.where((order) {
      final matchesSearch = order.trackingNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.customerName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _statusFilter == "All" ||
          (_statusFilter == "Active" && (order.status == 'Shipped' || order.status == 'Packed')) ||
          (_statusFilter == "Exceptions" && (order.status == 'RTO' || order.status == 'Returned')) ||
          (_statusFilter == "Delivered" && order.status == 'Delivered');

      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('SHIPMENT & FREIGHT TIMELINES'),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filters row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.location_searching_rounded, color: AppTheme.darkPrimaryGold),
                      hintText: "Enter tracking waybill or recipient name...",
                      fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Filter segments
                  Row(
                    children: [
                      _buildFilterChip("All", isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip("Active", isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip("Delivered", isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip("Exceptions", isDark),
                    ],
                  )
                ],
              ),
            ),

            // Shipments timeline list
            Expanded(
              child: filteredShipments.isEmpty
                  ? const Center(child: Text("No shipments found matching filters."))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredShipments.length,
                      itemBuilder: (context, index) {
                        final order = filteredShipments[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'AWB: ${order.trackingNumber}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Courier'),
                                        ),
                                        Text(
                                          'Courier: ${order.courierPartner}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    _buildStatusBadge(order.status),
                                  ],
                                ),
                                const Divider(height: 20),
                                Text(
                                  'Recipient: ${order.customerName} (${order.city}, ${order.state})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                
                                // Mini Timeline view: Last 2 events
                                _buildMiniTimeline(order.shipmentTimeline, isDark),
                                
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => _showCourierAssignmentDialog(context, order),
                                      child: const Text('RE-ASSIGN COURIER', style: TextStyle(color: AppTheme.darkPrimaryGold, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _showFullTimelineModal(context, order, isDark),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard,
                                        foregroundColor: isDark ? Colors.white : Colors.black,
                                      ),
                                      child: const Text('FULL TIMELINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final active = _statusFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _statusFilter = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold)
                : (isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 0.5),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: active
                    ? (isDark ? AppTheme.darkBackground : Colors.white)
                    : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.transparent;
    Color fg = Colors.white;
    switch (status) {
      case 'Pending':
        bg = AppTheme.colorWarning.withOpacity(0.15);
        fg = AppTheme.colorWarning;
        break;
      case 'Processing':
        bg = AppTheme.colorInfo.withOpacity(0.15);
        fg = AppTheme.colorInfo;
        break;
      case 'Packed':
        bg = Colors.amber.withOpacity(0.15);
        fg = Colors.amber;
        break;
      case 'Shipped':
        bg = Colors.blue.withOpacity(0.15);
        fg = Colors.blue;
        break;
      case 'Delivered':
        bg = AppTheme.colorSuccess.withOpacity(0.15);
        fg = AppTheme.colorSuccess;
        break;
      case 'Returned':
      case 'RTO':
        bg = AppTheme.colorError.withOpacity(0.15);
        fg = AppTheme.colorError;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 9),
      ),
    );
  }

  Widget _buildMiniTimeline(List<ShipmentTimelineEntry> timeline, bool isDark) {
    if (timeline.isEmpty) return const SizedBox();
    
    // Show only the last (most recent) event
    final lastEntry = timeline.last;
    return Row(
      children: [
        const Icon(Icons.circle_notifications_rounded, color: AppTheme.darkPrimaryGold, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LATEST UPDATE: ${lastEntry.title}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.darkPrimaryGold),
              ),
              Text(
                lastEntry.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  void _showCourierAssignmentDialog(BuildContext context, Order order) {
    String selectedCourier = order.courierPartner;
    final couriers = ['Delhivery Premium', 'BlueDart Apex', 'Shadowfax Priority', 'Xpressbees Express'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Re-route Waybill Courier Node'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Courier Partner Node:', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: selectedCourier,
                    isExpanded: true,
                    items: couriers.map((String c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedCourier = val;
                        });
                      }
                    },
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
                    // Update courier partner in Isar database
                    ref.read(ordersProvider.notifier).save(
                      order.copyWith(
                        courierPartner: selectedCourier,
                        shipmentTimeline: [
                          ...order.shipmentTimeline,
                          ShipmentTimelineEntry(
                            status: order.status,
                            title: 'Courier Node Re-route',
                            description: 'Freight system assigned shipment route to $selectedCourier.',
                            timestamp: DateTime.now().toIso8601String(),
                          ),
                        ],
                      ),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Shipment waybill re-routed to $selectedCourier.')),
                    );
                  },
                  child: const Text('RE-ASSIGN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFullTimelineModal(BuildContext context, Order order, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WAYBILL LOGS: ${order.trackingNumber}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.darkPrimaryGold),
              ),
              const SizedBox(height: 6),
              Text(
                'Courier Node: ${order.courierPartner}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(height: 24),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: order.shipmentTimeline.length,
                  itemBuilder: (c, idx) {
                    final entry = order.shipmentTimeline[idx];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.darkPrimaryGold),
                            ),
                            if (idx != order.shipmentTimeline.length - 1)
                              Container(
                                width: 2,
                                height: 40,
                                color: AppTheme.darkBorder,
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(entry.description, style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                              Text(
                                DateFormat('dd MMM, hh:mm a').format(DateTime.parse(entry.timestamp)),
                                style: TextStyle(fontSize: 9, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
