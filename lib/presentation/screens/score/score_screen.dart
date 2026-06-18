import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../providers/providers.dart';
import '../../../domain/models/domain_models.dart';

class ScoreScreen extends ConsumerWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEntre = ref.watch(currentEntrepreneurProvider);
    final allEntrepreneurs = ref.watch(entrepreneursListProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    String getInitials(String name) {
      if (name.isEmpty) return "Q";
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length > 1) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }

    if (activeEntre == null || allEntrepreneurs.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.darkPrimaryGold)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('ELITE FOUNDER SCOREBOARD'),
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
                // 1. Overall Score Dial Card
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Center(
                        child: Text(
                          "ELITE SCORECARD",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Big Score Circle
                      Center(
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.darkPrimaryGold,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.darkPrimaryGold.withOpacity(0.15),
                                blurRadius: 30,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${activeEntre.eliteScore}',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  '/ 100',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        activeEntre.businessName.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lead Founder: ${activeEntre.name}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const Divider(height: 32),
                      
                      // 2. Score Breakdown Sub-Scores
                      _buildScoreRow("Revenue Growth Velocity", activeEntre.growthScore, Colors.green),
                      _buildScoreRow("Net Profitability Ratio", activeEntre.profitabilityScore, AppTheme.darkPrimaryGold),
                      _buildScoreRow("Warehouse Fulfillment Speed", activeEntre.fulfillmentScore, Colors.orange),
                      _buildScoreRow("Supplier Reliability Index", activeEntre.supplierScore, Colors.blue),
                      _buildScoreRow("Delivery Hub Completion Rate", activeEntre.deliveryScore, Colors.purple),
                      _buildScoreRow("Overall Operations Score", activeEntre.operationsScore, Colors.teal),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Leaderboard Section
                Text(
                  'GLOBAL FOUNDER LEADERBOARD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allEntrepreneurs.length,
                  itemBuilder: (context, idx) {
                    final ent = allEntrepreneurs[idx];
                    final isCurrent = ent.id == activeEntre.id;
                    final rank = ent.rank;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: isCurrent 
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.darkPrimaryGold, width: 1.5),
                            )
                          : null,
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Rank Badge
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getRankColor(rank, isDark),
                                border: Border.all(color: AppTheme.darkBorder, width: 0.5),
                              ),
                              child: Center(
                                child: Text(
                                  '$rank',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: rank <= 3 ? Colors.black : (isDark ? Colors.white : Colors.black),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    ent.id == activeEntre.id
                                        ? AppTheme.darkPrimaryGold
                                        : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                                    ent.id == activeEntre.id
                                        ? AppTheme.darkPrimaryGold.withOpacity(0.5)
                                        : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  getInitials(ent.name),
                                  style: TextStyle(
                                    color: ent.id == activeEntre.id
                                        ? Colors.white
                                        : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Name & Biz
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ent.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    ent.businessName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Score
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${ent.eliteScore}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.darkPrimaryGold),
                                ),
                                const Text(
                                  'SCORE',
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
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

  Widget _buildScoreRow(String label, int score, Color barColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                '$score/100',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: barColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: barColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank, bool isDark) {
    if (rank == 1) return AppTheme.darkPrimaryGold; // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard;
  }
}
