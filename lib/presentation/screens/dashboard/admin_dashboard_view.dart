import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../providers/providers.dart';
import '../../../domain/models/domain_models.dart';

class AdminDashboardView extends ConsumerWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(adminApplicationsProvider);
    final suppliers = ref.watch(suppliersProvider);
    final entrepreneurs = ref.watch(entrepreneursListProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Platform Summary stats
    final totalMembers = entrepreneurs.length;
    final avgScore = totalMembers > 0
        ? (entrepreneurs.map((e) => e.eliteScore).reduce((a, b) => a + b) / totalMembers).round()
        : 0;
    
    // Total gross is statically mocked for platform dashboard (e.g., ₹24.8 Cr processed)
    final grossVolume = formatter.format(24800000);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Title Summary
            Row(
              children: [
                const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.darkPrimaryGold, size: 24),
                const SizedBox(width: 8),
                Text(
                  'QAAFIYA OPERATIONS CONSOLE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Platform Analytics
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    "Gross Volume",
                    grossVolume,
                    Icons.monetization_on_outlined,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    "Active Cohorts",
                    "$totalMembers Founders",
                    Icons.people_outline_rounded,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    "Average Health Score",
                    "$avgScore/100",
                    Icons.insights_rounded,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    "Platform RTO Avg",
                    "6.4%",
                    Icons.trending_down_rounded,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Entrepreneur Applications Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ENTREPRENEUR APPLICATIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.darkPrimaryGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${applications.where((a) => a.status == 'Pending').length} PENDING',
                    style: const TextStyle(
                      color: AppTheme.darkPrimaryGold,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (applications.isEmpty)
              const Center(child: Text('No applications submitted.'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: applications.length,
                itemBuilder: (context, idx) {
                  final app = applications[idx];
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
                                app.businessName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              _buildStatusBadge(app.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Founder: ${app.applicantName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('•'),
                              const SizedBox(width: 8),
                              Text(
                                app.annualRevenue,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkPrimaryGold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            app.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Text(
                                'Sector: ${app.category}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                              const Spacer(),
                              if (app.status == 'Pending') ...[
                                TextButton(
                                  onPressed: () {
                                    ref.read(adminApplicationsProvider.notifier).save(
                                      app.copyWith(status: 'Rejected'),
                                    );
                                  },
                                  child: const Text('REJECT', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.read(adminApplicationsProvider.notifier).save(
                                      app.copyWith(status: 'Approved'),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.colorSuccess,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  child: const Text('APPROVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ]
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),

            // 4. Supplier Verification Module
            Text(
              'SUPPLIER NODES FOR VERIFICATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: suppliers.length > 5 ? 5 : suppliers.length, // Show first 5
                itemBuilder: (context, idx) {
                  final supp = suppliers[idx];
                  final isActive = supp.status == 'Active';
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                          width: idx == 4 ? 0 : 0.5,
                        ),
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(supp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${supp.category} • Avg Lead Time: ${supp.leadTime} days'),
                      trailing: Switch(
                        value: isActive,
                        activeColor: AppTheme.darkPrimaryGold,
                        onChanged: (val) {
                          ref.read(suppliersProvider.notifier).save(
                            supp.copyWith(status: val ? 'Active' : 'Suspended'),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 5. Cohort Analytics
            Text(
              'COHORT PERFORMANCE ANALYTICS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(1.2),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'COHORT SECTOR',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'RELIABILITY',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'RTO RATE',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        ),
                      ),
                    ],
                  ),
                  _buildCohortRow("Apparel & Fabrics", "86%", "5.2%", isDark),
                  _buildCohortRow("Organic Cosmetics", "91%", "6.1%", isDark),
                  _buildCohortRow("Gourmet Teas", "79%", "4.4%", isDark),
                  _buildCohortRow("Premium Leather", "88%", "8.2%", isDark),
                  _buildCohortRow("Home Decor & Arts", "82%", "7.5%", isDark),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String val, IconData icon, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightSurfaceCard,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.darkPrimaryGold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  val,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),
          )
        ],
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
      case 'Approved':
        bg = AppTheme.colorSuccess.withOpacity(0.15);
        fg = AppTheme.colorSuccess;
        break;
      case 'Rejected':
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

  TableRow _buildCohortRow(String sector, String reliability, String rtoRate, bool isDark) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            sector,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            reliability,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.colorSuccess),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            rtoRate,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.colorError),
          ),
        ),
      ],
    );
  }
}
