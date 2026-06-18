import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../providers/providers.dart';
import '../../../domain/models/domain_models.dart';

class CodScreen extends ConsumerWidget {
  const CodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final allOrders = ref.watch(ordersProvider);
    final settlements = ref.watch(codSettlementsProvider);

    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Live COD calculations based on entrepreneur's orders
    final codOrders = allOrders.where((o) => o.paymentMethod == 'COD').toList();

    num codPending = 0;   // Delivered but not settled, or shipped/transit COD value
    num codCollected = 0; // Delivered and collected, but not settled yet
    num codSettled = 0;   // Fully settled COD value

    for (final order in codOrders) {
      if (order.status == 'Delivered') {
        if (order.paymentStatus == 'Collected') {
          codCollected += order.totalAmount;
        } else if (order.paymentStatus == 'Settled') {
          codSettled += order.totalAmount;
        } else {
          codPending += order.totalAmount;
        }
      } else if (order.status != 'Returned' && order.status != 'RTO' && order.status != 'Pending') {
        codPending += order.totalAmount; // In transit COD risk
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('COD CLEARING HOUSE'),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildFinanceCard(
                        "Pending Clearing",
                        formatter.format(codPending),
                        AppTheme.colorWarning,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFinanceCard(
                        "Collected Cash",
                        formatter.format(codCollected),
                        AppTheme.colorInfo,
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFinanceCard(
                  "Fully Settled COD (Platform History)",
                  formatter.format(codSettled),
                  AppTheme.colorSuccess,
                  isDark,
                  isFullWidth: true,
                ),
                const SizedBox(height: 24),

                // 2. Bar Chart Analytics
                Text(
                  'SETTLEMENT VOLUME ANALYTICS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Clearing Volume',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 150,
                        child: BarChart(
                          _getBarChartData(settlements, isDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Settlement History
                Text(
                  'SETTLEMENT REGISTRY CYCLES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                if (settlements.isEmpty)
                  const Center(child: Text("No settlements recorded."))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: settlements.length,
                    itemBuilder: (context, index) {
                      final set = settlements[index];
                      final isSettled = set.status == 'Settled';

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
                                  Text(
                                    set.settlementCycle,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (isSettled ? AppTheme.colorSuccess : AppTheme.colorWarning).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      set.status.toUpperCase(),
                                      style: TextStyle(
                                        color: isSettled ? AppTheme.colorSuccess : AppTheme.colorWarning,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Cleared Date: ${isSettled ? DateFormat('dd MMM yyyy').format(DateTime.parse(set.settledAt)) : "Awaiting processing"}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    formatter.format(set.amount),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkPrimaryGold),
                                  ),
                                ],
                              ),
                              if (isSettled) ...[
                                const Divider(height: 16),
                                Text(
                                  'Bank Reference TXN ID: ${set.bankReference}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceCard(String title, String val, Color highlightColor, bool isDark, {bool isFullWidth = false}) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: isFullWidth ? double.infinity : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              val,
              style: TextStyle(
                fontSize: isFullWidth ? 22 : 18,
                fontWeight: FontWeight.bold,
                color: highlightColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartData _getBarChartData(List<CodSettlement> sets, bool isDark) {
    final List<BarChartGroupData> groups = [];
    final displaySets = sets.reversed.toList(); // Chronological order
    final limit = displaySets.length > 5 ? 5 : displaySets.length;

    for (int i = 0; i < limit; i++) {
      final item = displaySets[displaySets.length - limit + i];
      final val = item.amount / 10000; // in ten-thousands for scale
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              color: AppTheme.darkPrimaryGold,
              width: 14,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 20,
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder.withOpacity(0.5),
              ),
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
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
              int idx = val.toInt();
              if (idx >= 0 && idx < limit) {
                final cycleNum = displaySets[displaySets.length - limit + idx].settlementCycle.replaceAll("Cycle #", "C");
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    cycleNum,
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
      barGroups: groups,
    );
  }
}
