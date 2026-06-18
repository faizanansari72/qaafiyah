import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/providers.dart';
import 'dashboard/entrepreneur_dashboard_view.dart';
import 'dashboard/admin_dashboard_view.dart';
import 'dashboard/supplier_dashboard_view.dart';
import 'dashboard/logistics_dashboard_view.dart';

// Current tab index provider for navigation
final currentTabProvider = StateProvider<int>((ref) => 0);

class RoleSwitchWrapper extends ConsumerWidget {
  const RoleSwitchWrapper({super.key});

  // Role Swapping Badge Helper
  String _getRoleBadgeEmoji(UserRole r) {
    switch (r) {
      case UserRole.entrepreneur: return '💼';
      case UserRole.admin: return '👑';
      case UserRole.supplier: return '🏭';
      case UserRole.logisticsPartner: return '🚛';
    }
  }

  // Show a premium role switcher bottom sheet
  void _showRoleSwitcherSheet(BuildContext context, WidgetRef ref, UserRole currentRole, bool isDark) {
    final gold = isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
              const SizedBox(height: 18),
              Text(
                'SWITCH USER CONSOLE',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: gold,
                ),
              ),
              const SizedBox(height: 12),
              ...UserRole.values.map((val) {
                final selected = val == currentRole;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: selected
                        ? gold.withOpacity(0.08)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected ? gold.withOpacity(0.3) : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: selected ? gold.withOpacity(0.12) : (isDark ? Colors.grey[900]! : Colors.grey[100]!),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getRoleBadgeEmoji(val),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    title: Text(
                      val.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: selected
                            ? gold
                            : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                      ),
                    ),
                    trailing: selected
                        ? Icon(Icons.check_circle_rounded, color: gold, size: 20)
                        : null,
                    onTap: () {
                      ref.read(userRoleProvider.notifier).state = val;
                      ref.read(currentTabProvider.notifier).state = 0; // Reset tab
                      Navigator.pop(context);
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Premium exit confirmation dialog
  Future<bool> _showExitConfirmationDialog(BuildContext context, bool isDark) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.exit_to_app_rounded, color: AppTheme.darkPrimaryGold, size: 22),
              const SizedBox(width: 8),
              Text(
                'QUIT APP?',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 1.2,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to exit Qaafiya?',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkPrimaryGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text(
                'QUIT',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    // Switch active view based on active role
    Widget getBodyView() {
      switch (role) {
        case UserRole.entrepreneur:
          return const EntrepreneurDashboardView();
        case UserRole.admin:
          return const AdminDashboardView();
        case UserRole.supplier:
          return const SupplierDashboardView();
        case UserRole.logisticsPartner:
          return const LogisticsDashboardView();
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldQuit = await _showExitConfirmationDialog(context, isDark);
        if (shouldQuit) {
          exit(0);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBackground : AppTheme.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 16,
              centerTitle: false,
              title: Image.asset(
                'assets/images/logo.png',
                height: 24,
                fit: BoxFit.contain,
              ),
              actions: [
                // Custom Role Swapping Pill Button
                GestureDetector(
                  onTap: () => _showRoleSwitcherSheet(context, ref, role, isDark),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10, left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getRoleBadgeEmoji(role), style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                        Text(
                          role.name,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.unfold_more_rounded,
                          size: 13,
                          color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: getBodyView(),
      ),
    );
  }
}
