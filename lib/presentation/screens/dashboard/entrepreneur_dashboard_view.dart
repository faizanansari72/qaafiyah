import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/localization/translations.dart';
import '../../../core/widgets/premium_dialog.dart';
import '../../../domain/models/domain_models.dart';
import '../../providers/providers.dart';

// Chat message structure for advisor tab
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class EntrepreneurDashboardView extends ConsumerStatefulWidget {
  const EntrepreneurDashboardView({super.key});

  @override
  ConsumerState<EntrepreneurDashboardView> createState() => _EntrepreneurDashboardViewState();
}

class _EntrepreneurDashboardViewState extends ConsumerState<EntrepreneurDashboardView> {
  int _currentTab = 0; // 0: Home, 1: Orders, 2: Advisor, 3: Insights, 4: Profile
  int _lastNonAdvisorTab = 0; // Tracks last selected tab among Home, Orders, Insights, Profile
  int _activeChartIndex = 0; // 0: Revenue, 1: Profit, 2: Orders
  late DateTime _currentTime;
  Timer? _clockTimer;
  String _currentLocation = 'Gurugram, HR';

  // Orders registry state
  String _orderSearchQuery = "";
  String _orderStatusFilter = "All";

  // AI Advisor state
  final List<ChatMessage> _aiMessages = [];
  final TextEditingController _aiController = TextEditingController();
  final ScrollController _aiScrollController = ScrollController();
  bool _aiIsTyping = false;

  final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
    _initLocation();
    _initDefaultApiSettings();
    
    // Welcome message for AI Advisor
    _aiMessages.add(
      ChatMessage(
        text: "Pranam, Founder. I am Qaafiya AI, your secure business logistics advisor. I have mapped your local business node. Ask me about margin optimizations, warehouse stock warnings, delivery logistics diagnostics, or how to scale your sales.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _aiController.dispose();
    _aiScrollController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = 'Gurugram, HR';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = 'Gurugram, HR';
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'Gurugram, HR';
        });
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );

      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? 'Gurugram';
        final state = place.administrativeArea ?? 'HR';
        
        String stateCode = state;
        if (state.toLowerCase().contains('haryana')) {
          stateCode = 'HR';
        } else if (state.toLowerCase().contains('delhi')) {
          stateCode = 'DL';
        } else if (state.toLowerCase().contains('maharashtra')) {
          stateCode = 'MH';
        } else if (state.toLowerCase().contains('karnataka')) {
          stateCode = 'KA';
        } else if (state.toLowerCase().contains('rajasthan')) {
          stateCode = 'RJ';
        } else if (state.toLowerCase().contains('uttar pradesh')) {
          stateCode = 'UP';
        } else if (stateCode.length > 15) {
          stateCode = stateCode.substring(0, 3).toUpperCase();
        }

        setState(() {
          _currentLocation = '$city, $stateCode';
        });
      }
    } catch (e) {
      setState(() {
        _currentLocation = 'Gurugram, HR';
      });
    }
  }

  Future<void> _initDefaultApiSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('ai_provider') == null || prefs.getString('ai_provider') == 'grok') {
        await prefs.setString('ai_provider', 'gemini');
      }
      if (prefs.getString('ai_api_key') == null || prefs.getString('ai_api_key')!.isEmpty || prefs.getString('ai_api_key')!.startsWith('xai-')) {
        await prefs.setString('ai_api_key', 'AQ.Ab8RN6LwnVlrFq-RGVc6qZvLF-VoS5C4b7l_D9CoAeuEs5RwhQ');
      }
    } catch (e) {
      print("Error setting default Gemini API settings: $e");
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "Q";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _getOrderEmoji(Order o) {
    if (o.items.isEmpty) return '📦';
    final name = o.items.first.productName.toLowerCase();
    if (name.contains('honey')) return '🍯';
    if (name.contains('diya') || name.contains('brass')) return '🪔';
    if (name.contains('oil') || name.contains('serum') || name.contains('lotion')) return '🧴';
    if (name.contains('thread') || name.contains('cotton') || name.contains('stole')) return '🧵';
    if (name.contains('tea')) return '🍵';
    if (name.contains('jar') || name.contains('glass')) return '🫙';
    return '📦';
  }

  // AI Local Advisor RAG query logic
  String _runLocalRAGQuery(String query) {
    final products = ref.read(productsProvider);
    final orders = ref.read(ordersProvider);
    final suppliers = ref.read(suppliersProvider);
    final warehouses = ref.read(warehousesProvider);
    final activeEntre = ref.read(currentEntrepreneurProvider);

    final cleanQuery = query.toLowerCase();

    if (cleanQuery.contains("order") || cleanQuery.contains("sale") || cleanQuery.contains("revenue") || cleanQuery.contains("profit") || cleanQuery.contains("earning") || cleanQuery.contains("margin")) {
      final entreOrders = orders.where((o) => o.entrepreneurId == activeEntre?.id).toList();
      final totalSales = entreOrders.fold(0, (sum, o) => sum + o.totalAmount);
      final pendingCount = entreOrders.where((o) => o.status == 'Pending').length;
      final deliveredCount = entreOrders.where((o) => o.status == 'Delivered').length;
      final returnedCount = entreOrders.where((o) => o.status == 'Returned' || o.status == 'RTO').length;
      final rtoRate = entreOrders.isNotEmpty ? (returnedCount / entreOrders.length * 100).toStringAsFixed(1) : "0";

      return "📊 **Financial & Sales Diagnostics (${activeEntre?.businessName ?? 'Your Business'}):**\n\n"
          "Here is the real-time sales overview from your local console:\n"
          "• **Gross Sales (Total):** ₹$totalSales\n"
          "• **Total Orders Registered:** ${entreOrders.length} orders\n"
          "• **Active Pending Dispatch:** $pendingCount orders\n"
          "• **Successful Deliveries:** $deliveredCount packages\n"
          "• **Returns / RTO Rate:** $returnedCount orders ($rtoRate% rate)\n"
          "• **Estimated Profit (based on ~45% markup):** ₹${(totalSales * 0.45).round()}\n\n"
          "💡 **Advisor Tip:** Your return rate is $rtoRate%. If this grows past 5%, we recommend running WhatsApp order confirmation before dispatch, and routing Tier-2 shipments via premium carriers like BlueDart to avoid transit cancellations.";
    }

    if (cleanQuery.contains("product") || cleanQuery.contains("stock") || cleanQuery.contains("inventory") || cleanQuery.contains("item")) {
      final lowStock = products.where((p) => p.inventoryCount < 50).toList();
      final avgMargin = products.isNotEmpty ? (products.fold(0, (sum, p) => sum + p.profitMargin) / products.length).toStringAsFixed(1) : "45";
      final topMarginProduct = products.isNotEmpty ? products.reduce((curr, next) => curr.profitMargin > next.profitMargin ? curr : next) : null;

      String lowStockText = lowStock.isEmpty
          ? "• All products have optimal stock levels (above 50 units)."
          : "• **Low Stock Warnings (${lowStock.length} items):**\n" +
              lowStock.take(3).map((p) => "   - ${p.name}: ${p.inventoryCount} units remaining (SKU: ${p.sku})").join("\n");

      return "📦 **Inventory Stock & Margin Analysis:**\n\n"
          "Scanning your current catalog:\n"
          "• **Total Active SKUs:** ${products.length} registered products\n"
          "• **Average Catalog Profit Margin:** $avgMargin%\n"
          "• **Top Profit Contributor:** ${topMarginProduct?.name ?? 'N/A'} (${topMarginProduct?.profitMargin ?? 0}% Margin)\n"
          "$lowStockText\n\n"
          "💡 **Advisor Tip:** Securing inventory replenishment for low-stock SKUs takes 5-8 business days from suppliers. Order soon to prevent stock-outs.";
    }

    if (cleanQuery.contains("supplier") || cleanQuery.contains("rating") || cleanQuery.contains("vendor")) {
      final avgReliability = suppliers.isNotEmpty ? (suppliers.fold(0, (sum, s) => sum + s.reliabilityScore) / suppliers.length).toStringAsFixed(1) : "90";
      final activeSuppliers = suppliers.where((s) => s.status == 'Active').length;

      return "🏭 **Supply Chain Diagnostics:**\n\n"
          "Here is the status of your raw supply networks:\n"
          "• **Registered Suppliers:** ${suppliers.length} vendors ($activeSuppliers active)\n"
          "• **Average Supplier Reliability:** $avgReliability%\n"
          "• **Category Segments Covered:** ${suppliers.map((s) => s.category).toSet().join(', ')}\n\n"
          "💡 **Advisor Tip:** If a supplier's reliability falls below 85%, audit their lead time schedules to maintain standard dispatch SLA compliance.";
    }

    if (cleanQuery.contains("warehouse") || cleanQuery.contains("capacity") || cleanQuery.contains("location")) {
      final totalCapacity = warehouses.fold(0, (sum, w) => sum + w.capacity);
      final totalUsed = warehouses.fold(0, (sum, w) => sum + w.usedCapacity);
      final usageRate = totalCapacity > 0 ? (totalUsed / totalCapacity * 100).toStringAsFixed(1) : "0";

      return "🏢 **Fulfillment Nodes & Logistics Capacity:**\n\n"
          "Your storage network status:\n"
          "• **Active Warehouses:** ${warehouses.length} locations\n"
          "• **Net Capacity Utilization:** $totalUsed / $totalCapacity cubic units ($usageRate% capacity used)\n"
          "• **Fulfillment Hub Locations:** ${warehouses.map((w) => w.location).toSet().join(', ')}\n\n"
          "💡 **Advisor Tip:** The Bangalore Node is running close to capacity. We suggest routing newer shipments to regional warehouses to balance operations.";
    }

    if (cleanQuery.contains("grow") || cleanQuery.contains("marketing") || cleanQuery.contains("scale") || cleanQuery.contains("reduce") || cleanQuery.contains("business") || cleanQuery.contains("festive")) {
      return "📈 **Qaafiya Growth & RTO Strategy Guide:**\n\n"
          "To optimize conversions and scale your enterprise effectively, execute these key plays:\n"
          "• **Minimize COD Risk:** Offer a small incentive (e.g. ₹50 cashback or free shipping) for digital prepayments. Prepaid orders experience 85% fewer RTOs compared to COD.\n"
          "• **Automated Notifications:** Send dispatch tracking details via SMS/WhatsApp automatically. Customers notified within 1 hour are 40% less likely to reject packages.\n"
          "• **Fulfillment Operations:** Keep dispatch processing time under 24 hours. A fast dispatch score significantly boosts your Qaafiya Elite Score and overall rank.";
    }

    final totalSales = orders.where((o) => o.entrepreneurId == activeEntre?.id).fold(0, (sum, o) => sum + o.totalAmount);
    return "🤖 **Hello Founder, I am Qaafiya AI.**\n\n"
        "I have scanned your local database registries. Here is a summary of your entity:\n"
        "• **Entrepreneur Profile:** ${activeEntre?.name ?? 'Guest'} (Elite Rank #${activeEntre?.rank ?? 'N/A'})\n"
        "• **Business Brand:** ${activeEntre?.businessName ?? 'N/A'}\n"
        "• **Local Databases:** ${products.length} Products, ${orders.length} Orders, ${suppliers.length} Suppliers, ${warehouses.length} Warehouses.\n"
        "• **Overall Gross Revenue:** ₹$totalSales\n"
        "• **Low Stock Alerts:** ${products.where((p) => p.inventoryCount < 50).length} SKUs triggering alert.\n\n"
        "💬 **You can ask me specific questions like:**\n"
        "- *'Show my sales and revenue breakdown'*\n"
        "- *'How is my inventory stock level?'*\n"
        "- *'Give me advice on reducing RTO and scaling'*";
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _aiMessages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _aiIsTyping = true;
    });
    _aiController.clear();
    _scrollToBottom();

    final localDataSummary = _runLocalRAGQuery(text);

    // Call central AI Service Layer
    final aiService = ref.read(aiServiceProvider);
    final finalResponse = await aiService.getCompletion(
      prompt: text,
      localContext: localDataSummary,
    );

    if (!mounted) return;
    setState(() {
      _aiIsTyping = false;
      _aiMessages.add(ChatMessage(text: finalResponse, isUser: false, timestamp: DateTime.now()));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_aiScrollController.hasClients) {
        _aiScrollController.animateTo(
          _aiScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSettingsDialog(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    String activeProvider = prefs.getString('ai_provider') ?? 'local';
    final keyController = TextEditingController(text: prefs.getString('ai_api_key') ?? '');

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.settings_outlined, color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold),
                  const SizedBox(width: 8),
                  const Text('AI API SETTINGS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SELECT AI ENGINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButton<String>(
                      value: activeProvider,
                      isExpanded: true,
                      dropdownColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      items: const [
                        DropdownMenuItem(value: 'local', child: Text('Local Smart Advisor (No Key)')),
                        DropdownMenuItem(value: 'gemini', child: Text('Gemini API (Free Tier)')),
                        DropdownMenuItem(value: 'openai', child: Text('ChatGPT / OpenAI API')),
                        DropdownMenuItem(value: 'grok', child: Text('Grok / xAI API')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            activeProvider = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (activeProvider != 'local') ...[
                      const Text('PASTE API SECRET KEY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: keyController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Enter API key here...',
                          fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightSurfaceCard,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activeProvider == 'gemini'
                            ? 'Tip: You can get a free Gemini API Key from Google AI Studio.'
                            : 'Enter your API key to make live requests.',
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ] else ...[
                      Text(
                        'Uses local RAG diagnostic algorithms to analyze database metrics and supply general business consulting tips conversationally.',
                        style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final p = await SharedPreferences.getInstance();
                    await p.setString('ai_provider', activeProvider);
                    await p.setString('ai_api_key', keyController.text);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('AI Settings saved successfully!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkPrimaryGold,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('SAVE SETTINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- WIDGET RENDER METHODS ---

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final activeEntre = ref.watch(currentEntrepreneurProvider);

    if (activeEntre == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.darkPrimaryGold));
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        bottom: false,
        child: _buildBody(activeEntre, isDark),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildBody(dynamic activeEntre, bool isDark) {
    switch (_currentTab) {
      case 0:
        return _buildHomeTab(activeEntre, isDark);
      case 1:
        return _buildOrdersTab(activeEntre, isDark);
      case 2:
        return _buildAdvisorTab(activeEntre, isDark);
      case 3:
        return _buildInsightsTab(activeEntre, isDark);
      case 4:
        return _buildProfileTab(activeEntre, isDark);
      default:
        return _buildHomeTab(activeEntre, isDark);
    }
  }

  // Tab 0: Home Page Redesign
  Widget _buildHomeTab(dynamic activeEntre, bool isDark) {
    final allOrders = ref.watch(ordersProvider);
    final products = ref.watch(productsProvider);
    final analyticsAsync = ref.watch(revenueAnalyticsProvider);
    final entreOrders = allOrders.where((o) => o.entrepreneurId == activeEntre.id).toList();

    // Calculations based on live data
    final totalOrders = entreOrders.length;
    final processingOrders = entreOrders.where((o) => o.status == 'Processing').length;
    final packedOrders = entreOrders.where((o) => o.status == 'Packed').length;
    final shippedOrders = entreOrders.where((o) => o.status == 'Shipped').length;
    final deliveredOrders = entreOrders.where((o) => o.status == 'Delivered').length;
    final rtoOrders = entreOrders.where((o) => o.status == 'RTO' || o.status == 'Returned').length;

    int revenueToday = 0;
    int revenueWeekly = 0;
    int revenueMonthly = 0;
    int netProfit = 0;

    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final oneMonthAgo = now.subtract(const Duration(days: 30));

    for (final order in entreOrders) {
      final orderDate = DateTime.parse(order.createdAt);
      if (orderDate.isAfter(oneDayAgo)) {
        revenueToday += order.totalAmount;
      }
      if (orderDate.isAfter(oneWeekAgo)) {
        revenueWeekly += order.totalAmount;
      }
      if (orderDate.isAfter(oneMonthAgo)) {
        revenueMonthly += order.totalAmount;
      }
      if (order.status != 'Returned' && order.status != 'RTO') {
        netProfit += (order.totalAmount * 0.45).round();
      }
    }

    final double marginPercent = revenueMonthly > 0 ? (netProfit / revenueMonthly) * 100 : 45.2;
    final double rtoRate = totalOrders > 0 ? (rtoOrders / totalOrders) * 100 : 4.8;
    final lowStockCount = products.where((p) => p.inventoryCount < 50).length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 116),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Aanya Sharma / AS Avatar)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning,',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activeEntre.name,
                    style: TextStyle(
                      fontSize: 21,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -.3,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _showNotificationsDialog(isDark);
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isDark ? .05 : .08),
                        border: Border.all(color: Colors.white.withOpacity(isDark ? .08 : .12)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            size: 21,
                          ),
                          Positioned(
                            top: 10,
                            right: 11,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.colorError,
                                border: Border.all(color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground, width: 1.5),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showProfileSwitcher(context, ref),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.darkPrimaryGold.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(activeEntre.name),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 20),

          // 2. Hero Revenue Card (₹1,24,800)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkPrimaryGold.withOpacity(isDark ? 0.16 : 0.22),
                  AppTheme.darkPrimaryGold.withOpacity(isDark ? 0.03 : 0.05),
                  Colors.white.withOpacity(isDark ? 0.02 : 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppTheme.darkPrimaryGold.withOpacity(isDark ? 0.22 : 0.35),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's gross revenue",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFFD8C98F) : AppTheme.lightAccentGold,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.colorSuccess.withOpacity(0.15),
                        border: Border.all(color: AppTheme.colorSuccess.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_outward_rounded, color: Color(0xFF34D399), size: 11),
                          const SizedBox(width: 4),
                          Text(
                            "12.4%",
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFF34D399) : Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(revenueToday == 0 ? 124800 : revenueToday),
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 16),
                // Sparkline graph Custom Painter
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: CustomPaint(
                    painter: SparklinePainter(const [38.0, 32.0, 36.0, 22.0, 26.0, 14.0, 18.0, 8.0, 4.0]),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Stat Row
          GridView.count(
            crossAxisCount: 3,
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.05,
            crossAxisSpacing: 10,
            children: [
              _buildHomeStatCard("Weekly", _formatCompactCurrency(revenueWeekly == 0 ? 820000 : revenueWeekly), "+8.2%", true, isDark),
              _buildHomeStatCard("Net Profit", _formatCompactCurrency(netProfit == 0 ? 56200 : netProfit), "est. 45%", true, isDark),
              _buildHomeStatCard("Margin", "${marginPercent.toStringAsFixed(1)}%", "healthy", null, isDark, isHighlight: true),
            ],
          ),
          const SizedBox(height: 14),

          // 4. Performance Chart (Dynamic LineChart)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Performance',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F0F12) : AppTheme.lightSurfaceCard,
                        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        children: [
                          _buildChartSelectorButton(0, "Revenue", isDark),
                          _buildChartSelectorButton(1, "Profit", isDark),
                          _buildChartSelectorButton(2, "Orders", isDark),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                analyticsAsync.when(
                  data: (data) {
                    return SizedBox(
                      height: 140,
                      child: LineChart(
                        _getLineChartData(data, _activeChartIndex, isDark),
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator(color: AppTheme.darkPrimaryGold)),
                  ),
                  error: (e, s) => SizedBox(
                    height: 140,
                    child: Center(child: Text("Error loading chart data: $e", style: const TextStyle(fontSize: 11))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Fulfillment Pipeline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fulfillment',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -.2,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentTab = 1; // Go to orders tab
                  });
                },
                child: Text(
                  'View all',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPipelineStep("Processing", processingOrders + packedOrders == 0 ? 12 : processingOrders + packedOrders, const Color(0xFFF59E0B), isDark),
                    Container(width: 18, height: 1.5, color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    _buildPipelineStep("Shipped", shippedOrders == 0 ? 8 : shippedOrders, const Color(0xFF3B82F6), isDark),
                    Container(width: 18, height: 1.5, color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    _buildPipelineStep("Delivered", deliveredOrders == 0 ? 124 : deliveredOrders, const Color(0xFF10B981), isDark),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppTheme.colorError.withOpacity(0.08),
                    border: Border.all(color: AppTheme.colorError.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.colorError, size: 17),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                            children: [
                              const TextSpan(text: "RTO rate at "),
                              TextSpan(
                                text: "${rtoRate.toStringAsFixed(1)}%",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF87171)),
                              ),
                              TextSpan(text: " — $rtoOrders orders at risk"),
                            ],
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, size: 16),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. AI Insight Banner
          GestureDetector(
            onTap: () {
              setState(() {
                _currentTab = 2; // Go to AI tab
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkPrimaryGold.withOpacity(0.1),
                    AppTheme.darkPrimaryGold.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppTheme.darkPrimaryGold.withOpacity(0.28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.black),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        'Qaafiya AI insight',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkAccentGold : AppTheme.lightPrimaryGold,
                          letterSpacing: .2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    lowStockCount > 0 
                      ? "$lowStockCount SKUs are below 50 units. Reorder now — replenishment takes 5–8 days and a stock-out could cost you ~₹38K this week."
                      : "Inventory levels are stable. Blended margin is healthy at ${marginPercent.toStringAsFixed(1)}%. Trigger prepaid confirmation to improve COD conversions.",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFE7E5DF) : AppTheme.lightTextPrimary,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 7. Quick Actions Horizontal Scroll
          Text(
            'Quick actions',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: -.2,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildActionCard(Icons.shopping_bag_outlined, 'Products', () => context.push('/products'), isDark),
                _buildActionCard(Icons.factory_outlined, 'Suppliers', () => context.push('/suppliers'), isDark),
                _buildActionCard(Icons.warehouse_outlined, 'Warehouse', () => context.push('/warehouses'), isDark),
                _buildActionCard(Icons.account_balance_wallet_outlined, 'COD', () => context.push('/cod'), isDark),
                _buildActionCard(Icons.local_shipping_outlined, 'Shipments', () => context.push('/shipments'), isDark),
                _buildActionCard(Icons.military_tech_rounded, 'Score', () => context.push('/score'), isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompactCurrency(num value) {
    if (value >= 100000) {
      double lakhs = value / 100000.0;
      String str = lakhs.toStringAsFixed(2);
      if (str.endsWith('.00')) {
        str = str.substring(0, str.length - 3);
      } else if (str.endsWith('0')) {
        str = str.substring(0, str.length - 1);
      }
      return '₹$str\L';
    } else if (value >= 1000) {
      double thousands = value / 1000.0;
      String str = thousands.toStringAsFixed(2);
      if (str.endsWith('.00')) {
        str = str.substring(0, str.length - 3);
      } else if (str.endsWith('0')) {
        str = str.substring(0, str.length - 1);
      }
      return '₹$str\K';
    } else {
      return '₹$value';
    }
  }

  Widget _buildHomeStatCard(String label, String value, String subText, bool? isTrendUp, bool isDark, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : const Color(0xFFF4F4F5),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                color: isHighlight
                    ? (isDark ? AppTheme.darkAccentGold : AppTheme.lightPrimaryGold)
                    : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                fontWeight: FontWeight.w700,
                letterSpacing: -.3,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isTrendUp != null)
                Icon(
                  isTrendUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 11,
                  color: isTrendUp ? AppTheme.colorSuccess : AppTheme.colorError,
                ),
              if (isTrendUp != null) const SizedBox(width: 2),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subText,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isTrendUp != null
                          ? (isTrendUp ? AppTheme.colorSuccess : AppTheme.colorError)
                          : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSelectorButton(int index, String label, bool isDark) {
    final active = _activeChartIndex == index;
    final activeBg = isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeChartIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: active
              ? LinearGradient(
                  colors: [AppTheme.darkAccentGold, activeBg],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: active
                ? Colors.black87
                : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  LineChartData _getLineChartData(List<Map<String, dynamic>> rawData, int chartType, bool isDark) {
    final List<FlSpot> spots = [];
    double maxY = 10;
    
    for (int i = 0; i < rawData.length; i++) {
      final item = rawData[i];
      double val = 0;
      if (chartType == 0) {
        val = (item['revenue'] as int) / 100000;
      } else if (chartType == 1) {
        val = (item['netProfit'] as int) / 100000;
      } else {
        val = (item['ordersCount'] as int).toDouble();
      }
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxY) maxY = val;
    }

    maxY = maxY * 1.15;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          strokeWidth: 0.5,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: maxY > 0 ? (maxY / 3) : 1.0,
            getTitlesWidget: (val, meta) {
              return Text(
                chartType == 2 ? '${val.toInt()}' : '${val.toStringAsFixed(1)}L',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
              final idx = val.toInt();
              if (idx >= 0 && idx < rawData.length) {
                final mon = rawData[idx]['month'] as String;
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    mon.length > 3 ? mon.substring(0, 3) : mon,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (rawData.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: chartType == 1
              ? AppTheme.colorSuccess
              : (chartType == 2 ? AppTheme.colorInfo : AppTheme.darkPrimaryGold),
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                (chartType == 1
                    ? AppTheme.colorSuccess
                    : (chartType == 2 ? AppTheme.colorInfo : AppTheme.darkPrimaryGold)).withOpacity(0.18),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPipelineStep(String label, int val, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            label == "Processing"
                ? Icons.assignment_rounded
                : (label == "Shipped" ? Icons.local_shipping_rounded : Icons.check_circle_rounded),
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$val',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            fontWeight: FontWeight.w600,
          ),
        )
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String label, VoidCallback onTap, bool isDark) {
    final activeColor = isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151518) : Colors.white,
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withOpacity(0.08),
                border: Border.all(
                  color: activeColor.withOpacity(0.18),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: activeColor, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
      ),
    );
  }

  // Tab 1: Orders Registry Redesign
  Widget _buildOrdersTab(dynamic activeEntre, bool isDark) {
    final allOrders = ref.watch(ordersProvider);
    final entreOrders = allOrders.where((o) => o.entrepreneurId == activeEntre.id).toList();

    // Filter by query and status
    final filteredOrders = entreOrders.where((order) {
      final matchesSearch = order.orderNumber.toLowerCase().contains(_orderSearchQuery.toLowerCase()) ||
          order.customerName.toLowerCase().contains(_orderSearchQuery.toLowerCase());
      final matchesStatus = _orderStatusFilter == "All" || order.status == _orderStatusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    final statusFilters = ['All', 'Processing', 'Shipped', 'Delivered', 'RTO'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fulfillment pipeline',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Orders',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  letterSpacing: -.4,
                ),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TextField(
            onChanged: (val) {
              setState(() {
                _orderSearchQuery = val;
              });
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.darkPrimaryGold, size: 20),
              hintText: "Search order ID or customer...",
              fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // Horizontal Status Filters
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: statusFilters.length,
            itemBuilder: (context, index) {
              final f = statusFilters[index];
              final active = _orderStatusFilter == f;
              final activeBg = isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _orderStatusFilter = f;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: active
                        ? LinearGradient(
                            colors: [AppTheme.darkAccentGold, activeBg],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: active ? null : (isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard),
                    border: Border.all(
                      color: active ? Colors.transparent : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: active
                            ? Colors.black87
                            : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Orders List
        Expanded(
          child: filteredOrders.isEmpty
              ? const Center(child: Text("No matching orders found."))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 116),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    final emoji = _getOrderEmoji(order);
                    
                    Color statusColor = const Color(0xFFF59E0B);
                    if (order.status == 'Shipped') statusColor = const Color(0xFF3B82F6);
                    if (order.status == 'Delivered') statusColor = const Color(0xFF10B981);
                    if (order.status == 'RTO' || order.status == 'Returned') statusColor = const Color(0xFFEF4444);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 11),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: InkWell(
                        onTap: () => _showOrderDetailsSheet(context, order, isDark),
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.13),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(emoji, style: const TextStyle(fontSize: 16)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '#${order.orderNumber}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            order.customerName,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: statusColor,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          order.status,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${order.items.length} items • ${DateFormat('dd MMM, HH:mm').format(DateTime.parse(order.createdAt))}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    formatter.format(order.totalAmount),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  // Tab 2: AI Advisor Chat Screen Redesign
  Widget _buildAdvisorTab(dynamic activeEntre, bool isDark) {
    final quickChips = ['Margin optimization', 'RTO diagnosis', 'Inventory risk', 'Festive scale plan'];

    return Column(
      children: [
        // AI Header
        Container(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B0B0D) : AppTheme.lightSurface,
            border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF1C1C20) : AppTheme.lightBorder)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Qaafiya AI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF34D399),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Local advisor • online',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppTheme.darkPrimaryGold),
                onPressed: () => _showSettingsDialog(isDark),
              ),
            ],
          ),
        ),

        // Chat messages
        Expanded(
          child: _aiMessages.isEmpty
              ? const Center(child: Text("Initializing connections..."))
              : ListView.builder(
                  controller: _aiScrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(18),
                  itemCount: _aiMessages.length,
                  itemBuilder: (context, index) {
                    final m = _aiMessages[index];
                    return _buildChatBubble(m, isDark);
                  },
                ),
        ),

        // Typing Indicator
        if (_aiIsTyping)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
            child: Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(AppTheme.darkPrimaryGold)),
                ),
                const SizedBox(width: 8),
                Text(
                  'Qaafiya AI is formulating advice...',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        // Quick Prompt Chips
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            itemCount: quickChips.length,
            itemBuilder: (context, idx) {
              final chipText = quickChips[idx];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  onPressed: () => _sendMessage(chipText),
                  backgroundColor: AppTheme.darkPrimaryGold.withOpacity(0.08),
                  side: BorderSide(color: AppTheme.darkPrimaryGold.withOpacity(0.22), width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  label: Text(
                    chipText,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkPrimaryGold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Prompt Input Row
        Container(
          padding: EdgeInsets.only(
            left: 16, 
            right: 16, 
            top: 10, 
            bottom: 84 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B0B0D) : AppTheme.lightSurface,
            border: Border(top: BorderSide(color: isDark ? const Color(0xFF1C1C20) : AppTheme.lightBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aiController,
                  onSubmitted: _sendMessage,
                  decoration: InputDecoration(
                    hintText: "Ask Qaafiya AI...",
                    fillColor: isDark ? const Color(0xFF151518) : AppTheme.lightSurfaceCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _sendMessage(_aiController.text),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildChatBubble(ChatMessage m, bool isDark) {
    final isUser = m.isUser;
    final bubbleBg = isUser 
        ? (isDark ? const Color(0xFF1C1C22) : AppTheme.lightSurfaceCard)
        : (isDark ? AppTheme.darkPrimaryGold.withOpacity(0.07) : AppTheme.lightPrimaryGold.withOpacity(0.06));
    
    final border = isUser
        ? (isDark ? const Color(0xFF2A2A30) : AppTheme.lightBorder)
        : AppTheme.darkPrimaryGold.withOpacity(0.25);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleBg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
          ),
        ),
        child: Text(
          m.text,
          style: TextStyle(
            fontSize: 13,
            height: 1.55,
            color: isDark ? const Color(0xFFE7E5DF) : AppTheme.lightTextPrimary,
          ),
        ),
      ),
    );
  }

  // Tab 3: Insights (Analytics) Tab Redesign
  Widget _buildInsightsTab(dynamic activeEntre, bool isDark) {
    final allOrders = ref.watch(ordersProvider);
    final products = ref.watch(productsProvider);
    final entreOrders = allOrders.where((o) => o.entrepreneurId == activeEntre.id).toList();

    int revenueMonthly = 0;
    int netProfit = 0;

    final now = DateTime.now();
    final oneMonthAgo = now.subtract(const Duration(days: 30));

    for (final order in entreOrders) {
      final orderDate = DateTime.parse(order.createdAt);
      if (orderDate.isAfter(oneMonthAgo)) {
        revenueMonthly += order.totalAmount;
      }
      if (order.status != 'Returned' && order.status != 'RTO') {
        netProfit += (order.totalAmount * 0.45).round();
      }
    }

    final double marginPercent = revenueMonthly > 0 ? (netProfit / revenueMonthly) * 100 : 45.2;

    // Filter dynamic categories
    final Map<String, int> categoriesMap = {};
    for (final p in products) {
      categoriesMap[p.category] = (categoriesMap[p.category] ?? 0) + p.sellingPrice;
    }
    
    // Fallback categories matching redesign
    final categoryBars = [
      { 'label': 'Wellness & Honey', 'pct': 0.82, 'amount': '₹3.4L', 'color': const Color(0xFFD4AF37) },
      { 'label': 'Home & Decor', 'pct': 0.64, 'amount': '₹2.6L', 'color': const Color(0xFFD4AF37) },
      { 'label': 'Apparel & Textile', 'pct': 0.41, 'amount': '₹1.4L', 'color': const Color(0xFF8C6D0F) },
      { 'label': 'Kitchen & Steel', 'pct': 0.23, 'amount': '₹0.8L', 'color': const Color(0xFF4A3A06) },
    ];

    final topProducts = products.take(4).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 116),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'This month • 1–18 Jun',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Insights',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 18),

          // Twin Summary Card
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkPrimaryGold.withOpacity(0.16),
                        Colors.white.withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: AppTheme.darkPrimaryGold.withOpacity(0.22)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revenue',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFFD8C98F) : AppTheme.lightAccentGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatCompactCurrency(revenueMonthly == 0 ? 824000 : revenueMonthly),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '▲ 8.2% vs May',
                        style: TextStyle(fontSize: 11, color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard,
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net profit',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatCompactCurrency(netProfit == 0 ? 362000 : netProfit),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '▲ ${marginPercent.toStringAsFixed(1)}% margin',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 22),

          // Category Bars
          Text(
            'Revenue by category',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              letterSpacing: -.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: categoryBars.map((c) {
                final label = c['label'] as String;
                final valStr = c['amount'] as String;
                final pct = c['pct'] as double;
                final color = c['color'] as Color;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          Text(valStr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          height: 8,
                          color: isDark ? const Color(0xFF0F0F12) : AppTheme.lightSurfaceCard,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: pct,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  gradient: LinearGradient(
                                    colors: [
                                      color.withOpacity(0.5),
                                      color,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),

          // Top Products by Margin
          Text(
            'Top products by margin',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              letterSpacing: -.2,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topProducts.length,
            itemBuilder: (context, idx) {
              final p = topProducts[idx];
              final listEmojis = ['🍯', '🪔', '🧴', '🧵'];
              final emoji = idx < listEmojis.length ? listEmojis[idx] : '📦';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard,
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.darkPrimaryGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "SKU ${p.sku} • ${p.inventoryCount} left",
                            style: TextStyle(
                              fontSize: 11,
                              color: p.inventoryCount < 50 ? const Color(0xFFFBBF24) : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${p.profitMargin}%',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.darkAccentGold),
                    )
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Delivery Health
          Text(
            'Delivery health',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              letterSpacing: -.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard,
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivered rate',
                        style: TextStyle(fontSize: 11.5, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '94.1%',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '124 of 144 orders',
                        style: TextStyle(fontSize: 10.5, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard,
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RTO rate',
                        style: TextStyle(fontSize: 11.5, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '4.8%',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFF87171)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'below 5% target',
                        style: TextStyle(fontSize: 10.5, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      )
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // Tab 4: Profile & Settings Tab Redesign
  Widget _buildProfileTab(dynamic activeEntre, bool isDark) {
    final allOrders = ref.watch(ordersProvider);
    final products = ref.watch(productsProvider);
    final entreOrders = allOrders.where((o) => o.entrepreneurId == activeEntre.id).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 116),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 18),

          // Identity Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkPrimaryGold.withOpacity(0.12),
                  Colors.white.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppTheme.darkPrimaryGold.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.darkPrimaryGold.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(activeEntre.name),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  activeEntre.name,
                  style: TextStyle(
                    fontSize: 19,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activeEntre.businessName,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.darkPrimaryGold.withOpacity(0.14),
                    border: Border.all(color: AppTheme.darkPrimaryGold.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: AppTheme.darkPrimaryGold, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        'ELITE RANK #${activeEntre.rank} · GOLD TIER',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.darkAccentGold,
                          fontWeight: FontWeight.bold,
                          letterSpacing: .3,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Score / stats Grid
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard,
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${activeEntre.eliteScore}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.darkAccentGold, letterSpacing: -.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Elite score',
                        style: TextStyle(fontSize: 10.5, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontWeight: FontWeight.w500),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard,
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${entreOrders.length}',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, letterSpacing: -.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Orders',
                        style: TextStyle(fontSize: 10.5, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontWeight: FontWeight.w500),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard,
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${products.length}',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, letterSpacing: -.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Products',
                        style: TextStyle(fontSize: 10.5, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontWeight: FontWeight.w500),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 22),

          // Menu Groups
          _buildProfileMenuGroup(
            "Business",
            [
              _buildProfileMenuItem(Icons.business_center_outlined, 'Business details', null, () {}, isDark),
              _buildProfileMenuItem(Icons.account_balance_wallet_outlined, 'Payments & COD', null, () {}, isDark),
              _buildProfileMenuItem(Icons.people_outline_rounded, 'Team & roles', null, () {}, isDark),
            ],
            isDark,
          ),
          _buildProfileMenuGroup(
            "Preferences",
            [
              _buildProfileMenuItem(Icons.notifications_none_rounded, 'Notifications', '3', () {
                _showNotificationsDialog(isDark);
              }, isDark),
              _buildProfileMenuItem(
                Icons.g_translate_rounded, 
                'Language', 
                ref.watch(languageProvider) == AppLanguage.hindi ? 'Hindi' : 'English', 
                () {
                  final currentLang = ref.read(languageProvider);
                  final targetLangName = currentLang == AppLanguage.hindi ? 'English' : 'हिंदी';
                  PremiumDialog.show(
                    context: context,
                    title: currentLang == AppLanguage.hindi ? "भाषा बदलें?" : "Change Language?",
                    icon: Icons.g_translate_rounded,
                    content: Text(
                      currentLang == AppLanguage.hindi 
                          ? "क्या आप भाषा को बदलकर $targetLangName करना चाहते हैं?"
                          : "Are you sure you want to change the app language to $targetLangName?",
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(currentLang == AppLanguage.hindi ? 'रद्द करें' : 'CANCEL'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(languageProvider.notifier).toggleLanguage();
                          final newLang = ref.read(languageProvider);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                newLang == AppLanguage.hindi
                                    ? "भाषा बदलकर हिंदी कर दी गई है"
                                    : "Language changed to English",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                              ),
                              duration: const Duration(milliseconds: 1500),
                              backgroundColor: AppTheme.darkPrimaryGold,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        },
                        child: Text(currentLang == AppLanguage.hindi ? 'पुष्टि करें' : 'CONFIRM'),
                      ),
                    ],
                  );
                }, 
                isDark,
              ),
              _buildProfileMenuItem(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, 
                'Appearance', 
                isDark ? 'Dark' : 'Light', 
                () {
                  final currentLang = ref.read(languageProvider);
                  final targetThemeName = isDark 
                      ? (currentLang == AppLanguage.hindi ? 'लाइट थीम' : 'Light Theme') 
                      : (currentLang == AppLanguage.hindi ? 'डार्क थीम' : 'Dark Theme');
                  PremiumDialog.show(
                    context: context,
                    title: currentLang == AppLanguage.hindi ? "थीम बदलें?" : "Switch Theme?",
                    icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    content: Text(
                      currentLang == AppLanguage.hindi 
                          ? "क्या आप $targetThemeName पर स्विच करना चाहते हैं?"
                          : "Are you sure you want to switch to $targetThemeName?",
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(currentLang == AppLanguage.hindi ? 'रद्द करें' : 'CANCEL'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                        child: Text(currentLang == AppLanguage.hindi ? 'पुष्टि करें' : 'CONFIRM'),
                      ),
                    ],
                  );
                }, 
                isDark,
              ),
            ],
            isDark,
          ),
          _buildProfileMenuGroup(
            "Support",
            [
              _buildProfileMenuItem(Icons.help_outline_rounded, 'Help & support', null, () {}, isDark),
              _buildProfileMenuItem(Icons.menu_book_rounded, 'Console guide', null, () => _showConsoleGuide(context, ref), isDark),
            ],
            isDark,
          ),

          // Logout Button
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              final currentLang = ref.read(languageProvider);
              PremiumDialog.show(
                context: context,
                title: currentLang == AppLanguage.hindi ? "लॉग आउट करें?" : "Log Out?",
                icon: Icons.logout_rounded,
                content: Text(
                  currentLang == AppLanguage.hindi 
                      ? "क्या आप वास्तव में लॉग आउट करना चाहते हैं?"
                      : "Are you sure you want to log out of the console?",
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(currentLang == AppLanguage.hindi ? 'रद्द करें' : 'CANCEL'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            currentLang == AppLanguage.hindi 
                                ? "डेमो मोड: लॉगआउट सफल" 
                                : "Demo Mode: Session cleared. Please switch roles at top.",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      );
                    },
                    child: Text(currentLang == AppLanguage.hindi ? 'पुष्टि करें' : 'CONFIRM'),
                  ),
                ],
              );
            },
            child: Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.colorError.withOpacity(0.08),
                border: Border.all(color: AppTheme.colorError.withOpacity(0.22)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: Color(0xFFF87171), size: 17),
                  SizedBox(width: 9),
                  Text(
                    'Log out',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFF87171),
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfileMenuGroup(String title, List<Widget> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF71717B),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: items),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProfileMenuItem(IconData icon, String label, String? trailing, VoidCallback onTap, bool isDark) {
    final gold = isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF1C1C20) : AppTheme.lightBorder, width: 1)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: gold, size: 18),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE7E5DF) : AppTheme.lightTextPrimary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Text(
                trailing,
                style: const TextStyle(fontSize: 12, color: Color(0xFF71717A), fontWeight: FontWeight.bold),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF52525B), size: 17),
          ],
        ),
      ),
    );
  }

  // --- BOTTOM NAV BAR REDESIGN ---
  Widget _buildBottomNav(bool isDark) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 74 + bottomPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0x0009090B), const Color(0xFF09090B)]
              : [const Color(0x00FFFFFF), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.38],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding, left: 16, right: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavButton(0, Icons.home_outlined, Icons.home_rounded, "Home", isDark),
            _buildNavButton(1, Icons.assignment_outlined, Icons.assignment_rounded, "Orders", isDark),
            _buildCenterNavButton(2, isDark),
            _buildNavButton(3, Icons.insert_chart_outlined_rounded, Icons.insert_chart_rounded, "Insights", isDark),
            _buildNavButton(4, Icons.person_outline_rounded, Icons.person_rounded, "Profile", isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(int index, IconData icon, IconData activeIcon, String label, bool isDark) {
    final active = _currentTab == index;
    final activeColor = isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold;
    final inactiveColor = const Color(0xFF71717A);
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: active ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                active ? activeIcon : icon,
                color: active ? activeColor : inactiveColor,
                size: 23,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavButton(int index, bool isDark) {
    final active = _currentTab == index;
    final gold = isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold;
    final activeColor = isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold;
    final inactiveColor = const Color(0xFF71717A);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = index;
        });
      },
      child: Transform.translate(
        offset: const Offset(0, -6),
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: active
                      ? LinearGradient(
                          colors: [
                            isDark ? AppTheme.darkAccentGold : const Color(0xFFFFF7D6),
                            gold,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: active 
                      ? null 
                      : (isDark ? gold.withOpacity(0.14) : gold.withOpacity(0.08)),
                  border: Border.all(
                    color: gold.withOpacity(active ? 0.6 : 0.4),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(active ? 0.35 : 0.08),
                      blurRadius: active ? 14 : 6,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: active 
                        ? (isDark ? const Color(0xFF09090B) : Colors.white) 
                        : gold,
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Advisor",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- GENERAL HELPER MODAL METHODS ---

  void _showConsoleGuide(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final theme = ref.watch(themeModeProvider);
    final isDark = theme == ThemeMode.dark;
    
    PremiumDialog.show(
      context: context,
      title: Translations.translate('role_usage_guide', lang),
      icon: Icons.menu_book_rounded,
      iconColor: AppTheme.darkPrimaryGold,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Translations.translate('role_description_title', lang),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.darkPrimaryGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.darkPrimaryGold.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💼 ', style: TextStyle(fontSize: 14)),
                Text(
                  lang == AppLanguage.hindi ? 'उद्यमी (Entrepreneur)' : 'Entrepreneur Dashboard',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.darkPrimaryGold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildGuideItem(Icons.military_tech_rounded, lang == AppLanguage.hindi ? "एलीट स्कोर (Elite Score):" : "Elite Score Monitoring", lang == AppLanguage.hindi ? "आपकी व्यावसायिक स्थिरता, समय पर शिपमेंट, और ग्राहक प्रतिक्रिया के आधार पर आपके विकास स्तर की गणना करता है।" : "Analyzes growth, profitability, fulfillment, and operations metrics. Boosting this increases your partner rank.", isDark),
          _buildGuideItem(Icons.receipt_long_rounded, lang == AppLanguage.hindi ? "ऑर्डर रजिस्ट्री (Order Registry):" : "Order Registry & GST Invoices", lang == AppLanguage.hindi ? "ऑर्डर प्रबंधित करें, जीएसटी गणना के साथ रसीद डाउनलोड करें और सीधे ग्राहकों के साथ साझा करें।" : "Manage status lifecycles, view custom product images, calculate standard tax values and export shareable PDF/image layouts.", isDark),
          _buildGuideItem(Icons.psychology_rounded, lang == AppLanguage.hindi ? "क़ाफ़िया एआई (Qaafiya AI):" : "AI RAG Assistant Insights", lang == AppLanguage.hindi ? "एक उन्नत सहायक जो सीधे आपके गोदाम, स्टॉक और बिक्री डेटा का विश्लेषण करके व्यावसायिक सुझाव देता है।" : "Ask queries about your business data, product metrics, and warehouses using local RAG database scans.", isDark),
          _buildGuideItem(Icons.sync_alt_rounded, lang == AppLanguage.hindi ? "डेमो प्रोफाइल स्विचर:" : "Demo Switcher Mode", lang == AppLanguage.hindi ? "अलग-अलग रैंक के उद्यमी की भूमिकाओं का अनुभव करने के लिए प्रोफ़ाइल बदलें।" : "Switch profiles via the header card to witness how different ranks change platform dashboards dynamically.", isDark),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.darkPrimaryGold,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            Translations.translate('got_it', lang),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideItem(IconData icon, String title, String desc, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.darkPrimaryGold),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileSwitcher(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final list = ref.watch(entrepreneursListProvider);
            final activeEntre = ref.watch(currentEntrepreneurProvider);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Translations.translate('select_demo_profile', ref.watch(languageProvider)).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkBorder : AppTheme.lightSurfaceCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 0.5),
                        ),
                        child: Text(
                          '${list.length} FOUNDERS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Translations.translate('profile_switch_desc', ref.watch(languageProvider)),
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: list.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(color: AppTheme.darkPrimaryGold),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: list.length,
                            itemBuilder: (context, idx) {
                              final item = list[idx];
                              final isCurrent = item.id == activeEntre?.id;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isCurrent
                                      ? (isDark
                                          ? AppTheme.darkPrimaryGold.withOpacity(0.08)
                                          : AppTheme.lightPrimaryGold.withOpacity(0.06))
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isCurrent
                                        ? (isDark ? AppTheme.darkPrimaryGold.withOpacity(0.3) : AppTheme.lightPrimaryGold.withOpacity(0.3))
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: isCurrent
                                            ? [
                                                AppTheme.darkPrimaryGold,
                                                AppTheme.darkPrimaryGold.withOpacity(0.6),
                                              ]
                                            : [
                                                isDark ? Colors.grey[900]! : Colors.grey[200]!,
                                                isDark ? Colors.grey[850]! : Colors.grey[100]!,
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _getInitials(item.name),
                                        style: TextStyle(
                                          color: isCurrent
                                              ? Colors.black87
                                              : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: isCurrent
                                          ? (isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold)
                                          : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item.businessName,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                  trailing: isCurrent
                                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.darkPrimaryGold, size: 20)
                                      : Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.black26 : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Rank #${item.rank}',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                            ),
                                          ),
                                        ),
                                  onTap: () {
                                    ref.read(currentEntrepreneurProvider.notifier).setEntrepreneur(item);
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  void _showNotificationsDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNotificationItem("Low stock alert: Organic Forest Honey (32 remaining)", "1 hour ago", isDark),
              _buildNotificationItem("RTO threat warning: 3 orders at risk of return", "3 hours ago", isDark),
              _buildNotificationItem("Payment settlement: ₹1,24,800 credited successfully", "1 day ago", isDark),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE', style: TextStyle(color: AppTheme.darkPrimaryGold, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(String title, String time, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔔 ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(fontSize: 10, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- REGISTRY HELPER DETAILED MODALS ---

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
                        '#${order.orderNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (order.status == 'Delivered' ? AppTheme.colorSuccess : AppTheme.colorWarning).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: order.status == 'Delivered' ? AppTheme.colorSuccess : AppTheme.colorWarning,
                          ),
                        ),
                      ),
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
                                child: const Icon(Icons.shopping_bag_outlined, size: 16),
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
                                  DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(entry.timestamp)),
                                  style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
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
                const Text(
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
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Text(formatter.format(total), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.darkPrimaryGold)),
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
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(lang == AppLanguage.hindi ? 'इनवॉइस डाउनलोड हो गया!' : 'Invoice PDF downloaded successfully!')),
            );
          },
          child: const Text('CONFIRM DOWNLOAD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _simulateInvoiceShare(BuildContext context, Order order, WidgetRef ref) {
    final lang = ref.read(languageProvider);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang == AppLanguage.hindi 
              ? 'इनवॉइस साझा करने के लिए लिंक कॉपी हो गया!' 
              : 'Invoice shareable link copied! Ready to share on WhatsApp.',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.colorSuccess,
      ),
    );
  }
}

// Sparkline Custom Painter
class SparklinePainter extends CustomPainter {
  final List<double> data;
  SparklinePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = AppTheme.darkPrimaryGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final double stepX = size.width / (data.length - 1);
    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double minVal = data.reduce((a, b) => a < b ? a : b);
    final double valRange = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    double getY(double val) {
      return size.height - 4 - ((val - minVal) / valRange) * (size.height - 8);
    }

    path.moveTo(0, getY(data[0]));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, getY(data[0]));

    for (int i = 1; i < data.length; i++) {
      final double x = i * stepX;
      final double y = getY(data[i]);
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final gradient = LinearGradient(
      colors: [AppTheme.darkPrimaryGold.withOpacity(0.35), Colors.transparent],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    fillPaint.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final lastX = size.width;
    final lastY = getY(data.last);
    final dotPaint = Paint()..color = AppTheme.darkAccentGold..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(lastX, lastY), 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) => oldDelegate.data != data;
}
