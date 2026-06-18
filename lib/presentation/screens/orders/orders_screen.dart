import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/localization/translations.dart';
import '../../../core/widgets/premium_dialog.dart';
import '../../providers/providers.dart';
import '../../../domain/models/domain_models.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _searchQuery = "";
  String _statusFilter = "All";

  final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final activeEntre = ref.watch(currentEntrepreneurProvider);
    final allOrders = ref.watch(ordersProvider);
    final products = ref.watch(productsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    if (activeEntre == null) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.darkPrimaryGold)),
      );
    }

    // Filter by active entrepreneur
    final entreOrders = allOrders.where((o) => o.entrepreneurId == activeEntre.id).toList();

    // Filter by query and status
    final filteredOrders = entreOrders.where((order) {
      final matchesSearch = order.orderNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.customerName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == "All" || order.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    final statusOptions = ['All', 'Pending', 'Processing', 'Packed', 'Shipped', 'Delivered', 'Returned', 'RTO'];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('ORDER REGISTRY'),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filters panel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.darkPrimaryGold),
                      hintText: "Search order ID or customer name...",
                      fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Horizontal Status Filters
                  SizedBox(
                    height: 32,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: statusOptions.length,
                      itemBuilder: (context, index) {
                        final opt = statusOptions[index];
                        final active = _statusFilter == opt;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _statusFilter = opt;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: active
                                  ? (isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold)
                                  : (isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                                width: 0.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                opt,
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
                        );
                      },
                    ),
                  )
                ],
              ),
            ),

            // Orders List
            Expanded(
              child: filteredOrders.isEmpty
                  ? const Center(child: Text("No matching orders found."))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _showOrderDetailsSheet(context, order, isDark),
                            borderRadius: BorderRadius.circular(16),
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
                                            order.orderNumber,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(order.createdAt)),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      _buildStatusBadge(order.status),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order.customerName,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                          Text(
                                            '${order.city}, ${order.state}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        formatter.format(order.totalAmount),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkPrimaryGold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOrderDialog(context, activeEntre.id, activeEntre.businessName, products, isDark),
        backgroundColor: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
        foregroundColor: isDark ? AppTheme.darkBackground : Colors.white,
        child: const Icon(Icons.add_rounded),
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

  void _showOrderDetailsSheet(BuildContext context, Order order, bool isDark) {
    final total = order.totalAmount;
    final subtotal = (total / 1.18).round();
    final totalGst = total - subtotal;
    final cgst = (totalGst / 2).round();
    final sgst = totalGst - cgst;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.9,
          initialChildSize: 0.85,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      _buildStatusBadge(order.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Customer details
                  Text(
                    'CUSTOMER INFRASTRUCTURE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold),
                  ),
                  const SizedBox(height: 8),
                  Text('Name: ${order.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Phone: ${order.customerPhone}'),
                  Text('Email: ${order.customerEmail}'),
                  Text('Address: ${order.shippingAddress}, ${order.city}, ${order.state} - ${order.pincode}'),
                  
                  const Divider(height: 32),
                  
                  // Shipment Details
                  Text(
                    'SHIPMENT ROUTING',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold),
                  ),
                  const SizedBox(height: 8),
                  Text('Courier Node: ${order.courierPartner}'),
                  Text('Waybill: ${order.trackingNumber}'),
                  Text('Payment Method: ${order.paymentMethod} • Status: ${order.paymentStatus}'),

                  const Divider(height: 32),

                   // Order items list
                  Text(
                    'LINE ITEMS CONSOLE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    itemBuilder: (c, idx) {
                      final item = order.items[idx];
                      final basePrice = (item.price / 1.18).round();
                      final baseLineTotal = basePrice * item.quantity;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 36,
                                height: 36,
                                color: isDark ? Colors.black26 : Colors.black12,
                                child: Image.asset(
                                  'assets/images/product_placeholder.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag_outlined, size: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${formatter.format(basePrice)} × ${item.quantity}',
                                    style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatter.format(baseLineTotal),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 16),
                  
                  // Tax Summary Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translations.translate('invoice_tax_summary', ref.watch(languageProvider)).toUpperCase(),
                          style: TextStyle(
                            fontSize: 9, 
                            fontWeight: FontWeight.bold, 
                            letterSpacing: 1, 
                            color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Translations.translate('subtotal', ref.watch(languageProvider)),
                              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            ),
                            Text(
                              formatter.format(subtotal),
                              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Translations.translate('cgst', ref.watch(languageProvider)),
                              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            ),
                            Text(
                              formatter.format(cgst),
                              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Translations.translate('sgst', ref.watch(languageProvider)),
                              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            ),
                            Text(
                              formatter.format(sgst),
                              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Translations.translate('grand_total', ref.watch(languageProvider)),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              formatter.format(total),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkPrimaryGold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _simulateInvoiceDownload(context, order, ref),
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: Text(
                            Translations.translate('download_invoice', ref.watch(languageProvider)),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                            side: BorderSide(
                              color: (isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold).withOpacity(0.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _simulateInvoiceShare(context, order, ref),
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: Text(
                            Translations.translate('share_invoice', ref.watch(languageProvider)),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                            side: BorderSide(
                              color: (isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold).withOpacity(0.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Timeline tracking
                  Text(
                    'SHIPMENT TIMELINE JOURNAL',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.darkPrimaryGold,
                                ),
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

                  const Divider(height: 32),
                  
                  // Actions: Edit status or Delete
                  Row(
                    children: [
                      // Delete
                      TextButton.icon(
                        onPressed: () {
                          PremiumDialog.show(
                            context: context,
                            title: "Delete Order?",
                            icon: Icons.delete_forever_rounded,
                            iconColor: AppTheme.colorError,
                            content: Text(
                              "Are you sure you want to permanently delete order QF-${order.orderNumber} from the database?",
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('CANCEL'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colorError),
                                onPressed: () {
                                  Navigator.pop(context); // Close dialog
                                  Navigator.pop(context); // Close details sheet
                                  ref.read(ordersProvider.notifier).delete(order.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Order successfully deleted.')),
                                  );
                                },
                                child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ],
                          );
                        },
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        label: const Text('DELETE ORDER', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      // Edit status dropdown selector
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditStatusDialog(context, order, isDark);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkPrimaryGold),
                        child: const Text('MODIFY STATUS'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditStatusDialog(BuildContext context, Order order, bool isDark) {
    String selectedStatus = order.status;
    final statuses = ['Pending', 'Processing', 'Packed', 'Shipped', 'Delivered', 'Returned', 'RTO'];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Modify Order Status'),
              content: DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                items: statuses.map((String s) {
                  return DropdownMenuItem<String>(
                    value: s,
                    child: Text(s),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedStatus = val;
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update order status in Isar
                    final nowStr = DateTime.now().toIso8601String();
                    ref.read(ordersProvider.notifier).save(
                      order.copyWith(
                        status: selectedStatus,
                        shipmentTimeline: [
                          ...order.shipmentTimeline,
                          ShipmentTimelineEntry(
                            status: selectedStatus,
                            title: 'Status changed to $selectedStatus',
                            description: 'Console administrator updated shipment status.',
                            timestamp: nowStr,
                          ),
                        ],
                      ),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Order status updated to $selectedStatus.')),
                    );
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateOrderDialog(
    BuildContext context, 
    String entrepreneurId, 
    String businessName, 
    List<Product> products,
    bool isDark,
  ) {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add products first before creating an order.')),
      );
      return;
    }

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addrController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final pinController = TextEditingController();
    
    Product selectedProduct = products[0];
    int quantity = 1;
    String paymentMethod = "COD";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Enterprise Order'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Customer Name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Customer Phone'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Customer Email'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: addrController,
                      decoration: const InputDecoration(labelText: 'Shipping Address'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cityController,
                            decoration: const InputDecoration(labelText: 'City'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: stateController,
                            decoration: const InputDecoration(labelText: 'State'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: pinController,
                      decoration: const InputDecoration(labelText: 'Pincode'),
                    ),
                    const Divider(height: 24),
                    
                    // Product picker
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Select Line Product:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(height: 6),
                    DropdownButton<Product>(
                      value: selectedProduct,
                      isExpanded: true,
                      items: products.map((Product p) {
                        return DropdownMenuItem<Product>(
                          value: p,
                          child: Text('${p.name} (₹${p.sellingPrice})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedProduct = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Quantity:'),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (quantity > 1) setState(() => quantity--);
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              onPressed: () => setState(() => quantity++),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        )
                      ],
                    ),
                    const Divider(height: 20),
                    
                    // Payment Method
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment:'),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('COD'),
                              selected: paymentMethod == "COD",
                              onSelected: (val) {
                                if (val) setState(() => paymentMethod = "COD");
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Pre-paid'),
                              selected: paymentMethod == "Pre-paid",
                              onSelected: (val) {
                                if (val) setState(() => paymentMethod = "Pre-paid");
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isEmpty || addrController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill out customer name and shipping address.')),
                      );
                      return;
                    }

                    final totalVal = selectedProduct.sellingPrice * quantity;
                    final orderNum = 'QA-2026-${10000 + DateTime.now().millisecond}';
                    final nowStr = DateTime.now().toIso8601String();
                    
                    final newOrder = Order(
                      id: 'O${DateTime.now().microsecondsSinceEpoch.toString().substring(10)}',
                      orderNumber: orderNum,
                      entrepreneurId: entrepreneurId,
                      businessName: businessName,
                      customerName: nameController.text,
                      customerEmail: emailController.text.isEmpty ? 'guest@qaafiya.one' : emailController.text,
                      customerPhone: phoneController.text.isEmpty ? '+91 90000 00000' : phoneController.text,
                      shippingAddress: addrController.text,
                      city: cityController.text.isEmpty ? 'Delhi' : cityController.text,
                      state: stateController.text.isEmpty ? 'Delhi' : stateController.text,
                      pincode: pinController.text.isEmpty ? '110001' : pinController.text,
                      totalAmount: totalVal,
                      status: 'Pending',
                      paymentMethod: paymentMethod,
                      paymentStatus: paymentMethod == 'COD' ? 'Pending' : 'Paid',
                      createdAt: nowStr,
                      items: [
                        OrderItem(
                          productId: selectedProduct.id,
                          productName: selectedProduct.name,
                          quantity: quantity,
                          price: selectedProduct.sellingPrice,
                        )
                      ],
                      courierPartner: 'Delhivery Premium',
                      trackingNumber: 'QFY${1000000 + DateTime.now().millisecond}IN',
                      shipmentTimeline: [
                        ShipmentTimelineEntry(
                          status: 'Pending',
                          title: 'Order Confirmed',
                          description: 'Order placed via $businessName administrative console.',
                          timestamp: nowStr,
                        )
                      ],
                    );

                    // Save to Isar
                    ref.read(ordersProvider.notifier).save(newOrder);
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Order ${newOrder.orderNumber} successfully registered!')),
                    );
                  },
                  child: const Text('SUBMIT'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _simulateInvoiceDownload(BuildContext context, Order order, WidgetRef ref) {
    final lang = ref.read(languageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = order.totalAmount;
    final subtotal = (total / 1.18).round();
    final totalGst = total - subtotal;
    final cgst = (totalGst / 2).round();
    final sgst = totalGst - cgst;
    
    PremiumDialog.show(
      context: context,
      title: lang == AppLanguage.hindi ? "इनवॉइस डाउनलोड करें" : "Download Invoice PDF",
      icon: Icons.receipt_long_rounded,
      content: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.black38 : Colors.black12,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.darkPrimaryGold.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'QAAFIYA ENTERPRISE BILL',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.darkPrimaryGold),
                ),
                Text(
                  'GSTIN: 09AAFQC2026M1Z2',
                  style: TextStyle(fontSize: 8, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
              ],
            ),
            const Divider(height: 16),
            Text('Invoice No: QF-${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            Text('Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(order.createdAt))}', style: const TextStyle(fontSize: 10)),
            Text('Customer: ${order.customerName}', style: const TextStyle(fontSize: 10)),
            Text('Fulfillment Center: WH-DELHI-01', style: const TextStyle(fontSize: 10)),
            const Divider(height: 16),
            ...order.items.map((it) {
              final basePrice = (it.price / 1.18).round();
              final baseTotal = basePrice * it.quantity;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${it.productName} x${it.quantity}', style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(formatter.format(baseTotal), style: const TextStyle(fontSize: 10)),
                  ],
                ),
              );
            }).toList(),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal (Taxable Value)', style: TextStyle(fontSize: 10)),
                Text(formatter.format(subtotal), style: const TextStyle(fontSize: 10)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CGST (9%)', style: TextStyle(fontSize: 10)),
                Text(formatter.format(cgst), style: const TextStyle(fontSize: 10)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SGST (9%)', style: TextStyle(fontSize: 10)),
                Text(formatter.format(sgst), style: const TextStyle(fontSize: 10)),
              ],
            ),
            const Divider(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total (Inclusive of Taxes)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                Text(formatter.format(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.darkPrimaryGold)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(lang == AppLanguage.hindi ? "रद्द करें" : "Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  lang == AppLanguage.hindi 
                      ? "इनवॉइस PDF सफलतापूर्वक डाउनलोड हो गई!" 
                      : "Invoice PDF successfully downloaded to local Storage!",
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppTheme.darkPrimaryGold,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkPrimaryGold),
          child: Text(
            lang == AppLanguage.hindi ? "डाउनलोड" : "Download PDF",
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _simulateInvoiceShare(BuildContext context, Order order, WidgetRef ref) {
    final lang = ref.read(languageProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang == AppLanguage.hindi 
              ? "इनवॉइस लिंक क्लिपबोर्ड पर कॉपी हो गया और WhatsApp/Email पर साझा करने के लिए तैयार है!" 
              : "Invoice link copied to clipboard and shared successfully!",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.darkPrimaryGold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
