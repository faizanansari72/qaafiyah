import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/localization/translations.dart';
import '../../../core/widgets/premium_dialog.dart';
import '../../providers/providers.dart';

class EntrepreneurDashboardView extends ConsumerStatefulWidget {
  const EntrepreneurDashboardView({super.key});

  @override
  ConsumerState<EntrepreneurDashboardView> createState() => _EntrepreneurDashboardViewState();
}

class _EntrepreneurDashboardViewState extends ConsumerState<EntrepreneurDashboardView> {
  int _activeChartIndex = 0; // 0: Revenue, 1: Profit, 2: Orders

  final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  String _getInitials(String name) {
    if (name.isEmpty) return "Q";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final activeEntre = ref.watch(currentEntrepreneurProvider);
    final allOrders = ref.watch(ordersProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final analyticsAsync = ref.watch(revenueAnalyticsProvider);
    
    // Watch list here to pre-initialize it on dashboard load
    final _ = ref.watch(entrepreneursListProvider);

    if (activeEntre == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.darkPrimaryGold));
    }

    // Filter orders for active entrepreneur
    final entreOrders = allOrders.where((o) => o.entrepreneurId == activeEntre.id).toList();

    // Calculations based on live database orders
    final totalOrders = entreOrders.length;
    final pendingOrders = entreOrders.where((o) => o.status == 'Pending').length;
    final processingOrders = entreOrders.where((o) => o.status == 'Processing').length;
    final packedOrders = entreOrders.where((o) => o.status == 'Packed').length;
    final shippedOrders = entreOrders.where((o) => o.status == 'Shipped').length;
    final deliveredOrders = entreOrders.where((o) => o.status == 'Delivered').length;
    final returnedOrders = entreOrders.where((o) => o.status == 'Returned').length;
    final rtoOrders = entreOrders.where((o) => o.status == 'RTO').length;

    // Financial calculations
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
      
      // Calculate profit from order items if product matches, else use static margin (e.g. 45%)
      if (order.status != 'Returned' && order.status != 'RTO') {
        netProfit += (order.totalAmount * 0.45).round(); // 45% default profit margin
      }
    }

    final double marginPercent = revenueMonthly > 0 ? (netProfit / revenueMonthly) * 100 : 45.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Entrepreneur Header Card
            GestureDetector(
              onTap: () {
                // Open bottom sheet to switch entrepreneur profile for demo switching
                _showProfileSwitcher(context, ref);
              },
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.darkPrimaryGold,
                            AppTheme.darkPrimaryGold.withOpacity(0.4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.darkPrimaryGold.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(activeEntre.name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                activeEntre.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.darkPrimaryGold.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'RANK #${activeEntre.rank}',
                                  style: const TextStyle(
                                    color: AppTheme.darkPrimaryGold,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeEntre.businessName,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.sync_alt_rounded, size: 12, color: AppTheme.darkPrimaryGold),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  Translations.translate('switch_profile', ref.watch(languageProvider)),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Health score circular gauge
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.darkPrimaryGold.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${activeEntre.eliteScore}',
                              style: TextStyle(
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                              'SCORE',
                              style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: AppTheme.darkPrimaryGold),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Orders Pipeline Overview (Moved from bottom)
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FULFILLMENT PIPELINE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPipelineIndicator("Pending", pendingOrders, AppTheme.darkPrimaryGold),
                      _buildPipelineIndicator("Processing", processingOrders + packedOrders, Colors.orange),
                      _buildPipelineIndicator("Shipped", shippedOrders, Colors.blue),
                      _buildPipelineIndicator("Delivered", deliveredOrders, Colors.green),
                      _buildPipelineIndicator("Returned/RTO", returnedOrders + rtoOrders, Colors.red),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Orders in System',
                        style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ),
                      Text(
                        '$totalOrders Orders',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Revenue Overview Metrics
            Text(
              'REVENUE DIAGNOSTICS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMetricCard(
                  title: "Today's Gross",
                  value: formatter.format(revenueToday),
                  trend: "+12.4% vs yest",
                  isTrendUp: true,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
                _buildMetricCard(
                  title: "Weekly Revenue",
                  value: formatter.format(revenueWeekly),
                  trend: "+8.2% vs prev",
                  isTrendUp: true,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
                _buildMetricCard(
                  title: "Net Profit (Est)",
                  value: formatter.format(netProfit),
                  trend: "45% avg markup",
                  isTrendUp: true,
                  color: AppTheme.colorSuccess,
                ),
                _buildMetricCard(
                  title: "Profit Margin",
                  value: "${marginPercent.toStringAsFixed(1)}%",
                  trend: "Healthy Range",
                  isTrendUp: true,
                  color: AppTheme.darkPrimaryGold,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. Interactive Charts Section
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PERFORMANCE TRENDS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      // Chart switcher buttons
                      Row(
                        children: [
                          _buildChartButton(0, "REV", isDark),
                          const SizedBox(width: 4),
                          _buildChartButton(1, "PRF", isDark),
                          const SizedBox(width: 4),
                          _buildChartButton(2, "ORD", isDark),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  analyticsAsync.when(
                    data: (data) {
                      return SizedBox(
                        height: 180,
                        child: LineChart(
                          _getLineChartData(data, _activeChartIndex, isDark),
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator(color: AppTheme.darkPrimaryGold)),
                    ),
                    error: (e, s) => SizedBox(
                      height: 180,
                      child: Center(child: Text("Error loading chart data: $e")),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Quick Actions
            Text(
              'EXECUTIVE OPERATIONS CONSOLE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.05,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildActionTile(Icons.military_tech_rounded, Translations.translate('score', ref.watch(languageProvider)), () => context.push('/score'), isDark),
                _buildActionTile(Icons.receipt_long_rounded, Translations.translate('orders_tab', ref.watch(languageProvider)), () => context.push('/orders'), isDark),
                _buildActionTile(Icons.inventory_2_outlined, Translations.translate('products_tab', ref.watch(languageProvider)), () => context.push('/products'), isDark),
                _buildActionTile(Icons.precision_manufacturing_outlined, Translations.translate('suppliers_tab', ref.watch(languageProvider)), () => context.push('/suppliers'), isDark),
                _buildActionTile(Icons.warehouse_outlined, Translations.translate('warehouses_tab', ref.watch(languageProvider)), () => context.push('/warehouses'), isDark),
                _buildActionTile(Icons.account_balance_wallet_outlined, Translations.translate('cod_tab', ref.watch(languageProvider)), () => context.push('/cod'), isDark),
                _buildActionTile(Icons.local_shipping_outlined, Translations.translate('shipments_tab', ref.watch(languageProvider)), () => context.push('/shipments'), isDark),
                _buildActionTile(Icons.analytics_outlined, Translations.translate('analytics_tab', ref.watch(languageProvider)), () => context.push('/analytics'), isDark),
                _buildActionTile(Icons.psychology_outlined, Translations.translate('ai_tab', ref.watch(languageProvider)), () => context.push('/ai'), isDark),
                _buildActionTile(Icons.forum_outlined, Translations.translate('community_tab', ref.watch(languageProvider)), () => context.push('/community'), isDark),
                _buildActionTile(Icons.support_agent_rounded, Translations.translate('support_tab', ref.watch(languageProvider)), () => context.push('/support'), isDark),
                _buildActionTile(Icons.menu_book_rounded, Translations.translate('console_guide', ref.watch(languageProvider)), () => _showConsoleGuide(context, ref), isDark),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String trend,
    required bool isTrendUp,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isTrendUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 10,
                color: isTrendUp ? AppTheme.colorSuccess : AppTheme.colorError,
              ),
              const SizedBox(width: 2),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isTrendUp ? AppTheme.colorSuccess : AppTheme.colorError,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChartButton(int index, String label, bool isDark) {
    final active = _activeChartIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeChartIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: active
              ? (isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold)
              : Colors.transparent,
          border: Border.all(
            color: active
                ? Colors.transparent
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: active
                ? (isDark ? AppTheme.darkBackground : Colors.white)
                : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(8),
        borderRadius: 12,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightSurfaceCard,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineIndicator(String label, int val, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          '$val',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  LineChartData _getLineChartData(List<Map<String, dynamic>> rawData, int chartType, bool isDark) {
    final List<FlSpot> spots = [];
    double maxY = 10;
    
    for (int i = 0; i < rawData.length; i++) {
      final item = rawData[i];
      double val = 0;
      if (chartType == 0) {
        // Revenue (scaled in lakhs for chart)
        val = (item['revenue'] as int) / 100000;
      } else if (chartType == 1) {
        // Net Profit (lakhs)
        val = (item['netProfit'] as int) / 100000;
      } else {
        // Orders
        val = (item['ordersCount'] as int).toDouble();
      }
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxY) maxY = val;
    }

    maxY = maxY * 1.15; // 15% headroom

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
              int idx = val.toInt();
              if (idx >= 0 && idx < rawData.length) {
                final mon = rawData[idx]['month'] as String;
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    mon.substring(0, 3), // e.g. "Jan"
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
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 3.5,
              color: isDark ? AppTheme.darkBackground : Colors.white,
              strokeColor: barData.color ?? AppTheme.darkPrimaryGold,
              strokeWidth: 2,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                (chartType == 1
                        ? AppTheme.colorSuccess
                        : (chartType == 2 ? AppTheme.colorInfo : AppTheme.darkPrimaryGold))
                    .withOpacity(0.15),
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
                  // Drag Handle
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
                  
                  // Header Title
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
                  
                  // Profile List
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
                                              ? Colors.black
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
}
