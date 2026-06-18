import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qaafiya/domain/models/domain_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../providers/providers.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final analyticsAsync = ref.watch(revenueAnalyticsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('EXECUTIVE BI ANALYTICS'),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
          labelColor: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
          unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "Finance"),
            Tab(text: "Logistics"),
            Tab(text: "Supply Chain"),
          ],
        ),
      ),
      body: SafeArea(
        child: analyticsAsync.when(
          data: (data) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildFinanceAnalytics(data, isDark),
                _buildLogisticsAnalytics(data, isDark),
                _buildSupplyChainAnalytics(data, isDark),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.darkPrimaryGold)),
          error: (e, s) => Center(child: Text("Error loading analytics: $e")),
        ),
      ),
    );
  }

  Widget _buildFinanceAnalytics(List<Map<String, dynamic>> data, bool isDark) {
    // Net profit avg, average monthly growth, total gross
    int totalGross = 0;
    int totalProfit = 0;
    for (final item in data) {
      totalGross += item['revenue'] as int;
      totalProfit += item['netProfit'] as int;
    }
    final avgMonthlyRevenue = (totalGross / data.length).round();
    final profitMargin = ((totalProfit / totalGross) * 100).round();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROFITABILITY QUADRANT',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold),
          ),
          const SizedBox(height: 12),
          
          // Line Chart comparing Revenue and Net Profit
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Revenue vs Net Profit Trends (in Lakhs)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    _getComparisonLineChart(data, isDark),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem("Gross Revenue", AppTheme.darkPrimaryGold),
                    const SizedBox(width: 20),
                    _buildLegendItem("Net Profit", AppTheme.colorSuccess),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cards Grid
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Avg MRR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(formatter.format(avgMonthlyRevenue), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Profit Margin Avg', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$profitMargin%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.colorSuccess)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Product sales contribution analysis
          _buildProductContributionCard(isDark),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProductContributionCard(bool isDark) {
    final productsList = ref.watch(productsProvider);
    final ordersList = ref.watch(ordersProvider);

    final Map<String, int> productQuantities = {};
    final Map<String, int> productSales = {};

    for (final order in ordersList) {
      if (order.status != 'Returned' && order.status != 'RTO') {
        for (final item in order.items) {
          productQuantities[item.productName] = (productQuantities[item.productName] ?? 0) + item.quantity;
          productSales[item.productName] = (productSales[item.productName] ?? 0) + (item.price * item.quantity);
        }
      }
    }

    final sortedProducts = productSales.keys.toList()
      ..sort((a, b) => (productSales[b] ?? 0).compareTo(productSales[a] ?? 0));

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'PRODUCT CONTRIBUTION DICTIONARY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.colorSuccess.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE RAG SCAN',
                  style: TextStyle(color: AppTheme.colorSuccess, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          if (sortedProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: Text("No product sales recorded in local database timeline.")),
            )
          else
            ...sortedProducts.take(6).map((prodName) {
              final qty = productQuantities[prodName] ?? 0;
              final total = productSales[prodName] ?? 0;
              final pInfo = productsList.firstWhere(
                (p) => p.name.toLowerCase() == prodName.toLowerCase(),
                orElse: () => Product(id: '', name: '', sku: '', category: 'General', costPrice: 0, sellingPrice: 0, profitMargin: 45, inventoryCount: 0, supplierId: '', warehouseId: ''),
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 16,
                        color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prodName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Category: ${pInfo.category} • Sold: $qty units',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatter.format(total),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Margin: ${pInfo.profitMargin}%',
                          style: const TextStyle(fontSize: 10, color: AppTheme.colorSuccess, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildLogisticsAnalytics(List<Map<String, dynamic>> data, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DELIVERY & LOGISTICS QUADRANT',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold),
          ),
          const SizedBox(height: 12),

          // Orders trend bar chart
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fulfillment Volumetrics (Orders count)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 160,
                  child: BarChart(
                    _getOrdersBarChart(data, isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KPI block
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('OPERATIONAL EFFICIENCY RATIOS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildProgressBarRow("Delivery SLA Success Rate", 94, AppTheme.colorSuccess),
                const SizedBox(height: 8),
                _buildProgressBarRow("NDR Re-attempt Recovery", 68, AppTheme.colorInfo),
                const SizedBox(height: 8),
                _buildProgressBarRow("RTO Losses (Scale)", 6, AppTheme.colorError),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSupplyChainAnalytics(List<Map<String, dynamic>> data, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INVENTORY & SUPPLY CHAIN QUADRANT',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold),
          ),
          const SizedBox(height: 12),

          // Multi-warehouse status
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Warehouse Allocations & Storage levels', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 16),
                _buildWarehouseBar("Delhi NCR Fulfillment Hub", 72, isDark),
                const SizedBox(height: 10),
                _buildWarehouseBar("Mumbai Port Gateway Warehouse", 82, isDark),
                const SizedBox(height: 10),
                _buildWarehouseBar("South India Logistics Center", 38, isDark),
                const SizedBox(height: 10),
                _buildWarehouseBar("East India Distribution Node", 90, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Supplier Reliability
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VENDOR INTEGRITY RATINGS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                _buildSupplierScoreRow("Jaipur Blockprints Ltd", 94, "5 days avg"),
                _buildSupplierScoreRow("Darjeeling Gold Estates", 88, "7 days avg"),
                _buildSupplierScoreRow("Agra Leather Crafts", 91, "6 days avg"),
                _buildSupplierScoreRow("Varanasi Weaves", 76, "12 days avg"),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildProgressBarRow(String label, int val, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            Text('$val%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: val / 100,
            minHeight: 4,
            backgroundColor: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildWarehouseBar(String name, int val, bool isDark) {
    final isCritical = val > 85;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontSize: 11)),
            Text('$val%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCritical ? AppTheme.colorError : AppTheme.darkPrimaryGold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: val / 100,
            minHeight: 6,
            backgroundColor: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            valueColor: AlwaysStoppedAnimation<Color>(isCritical ? AppTheme.colorError : AppTheme.darkPrimaryGold),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierScoreRow(String name, int score, String details) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text(
                details,
                style: TextStyle(fontSize: 10, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: AppTheme.colorSuccess.withOpacity(0.12),
                ),
                child: Text('$score%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.colorSuccess)),
              ),
            ],
          )
        ],
      ),
    );
  }

  LineChartData _getComparisonLineChart(List<Map<String, dynamic>> rawData, bool isDark) {
    final List<FlSpot> revSpots = [];
    final List<FlSpot> profitSpots = [];
    double maxY = 10;

    for (int i = 0; i < rawData.length; i++) {
      final item = rawData[i];
      final revVal = (item['revenue'] as int) / 100000;
      final profVal = (item['netProfit'] as int) / 100000;
      revSpots.add(FlSpot(i.toDouble(), revVal));
      profitSpots.add(FlSpot(i.toDouble(), profVal));
      if (revVal > maxY) maxY = revVal;
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
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (rawData.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: maxY > 0 ? (maxY / 3) : 1.0,
            getTitlesWidget: (v, m) => Text('${v.toStringAsFixed(1)}L', style: TextStyle(fontSize: 8, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, m) {
              int idx = v.toInt();
              if (idx >= 0 && idx < rawData.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(rawData[idx]['month'].substring(0, 3), style: TextStyle(fontSize: 8, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      lineBarsData: [
        // Revenue Bar
        LineChartBarData(
          spots: revSpots,
          isCurved: true,
          color: AppTheme.darkPrimaryGold,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
        // Profit Bar
        LineChartBarData(
          spots: profitSpots,
          isCurved: true,
          color: AppTheme.colorSuccess,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }

  BarChartData _getOrdersBarChart(List<Map<String, dynamic>> rawData, bool isDark) {
    final List<BarChartGroupData> groups = [];
    for (int i = 0; i < rawData.length; i++) {
      final item = rawData[i];
      final val = (item['ordersCount'] as int).toDouble();
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              color: AppTheme.colorInfo,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        show: true,
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, m) {
              int idx = v.toInt();
              if (idx >= 0 && idx < rawData.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(rawData[idx]['month'].substring(0, 3), style: TextStyle(fontSize: 8, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      barGroups: groups,
    );
  }
}
