import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../providers/providers.dart';
import 'dashboard/entrepreneur_dashboard_view.dart';
import 'dashboard/admin_dashboard_view.dart';
import 'dashboard/supplier_dashboard_view.dart';
import 'dashboard/logistics_dashboard_view.dart';

// Current tab index provider for navigation
final currentTabProvider = StateProvider<int>((ref) => 0);

class RoleSwitchWrapper extends ConsumerWidget {
  const RoleSwitchWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    final activeTab = ref.watch(currentTabProvider);
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

    String getRoleBadgeEmoji(UserRole r) {
      switch (r) {
        case UserRole.entrepreneur: return '💼';
        case UserRole.admin: return '👑';
        case UserRole.supplier: return '🏭';
        case UserRole.logisticsPartner: return '🚛';
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightSurface,
        elevation: 0,
        titleSpacing: 16,
        centerTitle: false,
        title: Image.asset(
          'assets/images/logo.png',
          height: 24,
          fit: BoxFit.contain,
        ),
        actions: [
          // Language Switcher Toggle
          IconButton(
            onPressed: () {
              ref.read(languageProvider.notifier).toggleLanguage();
              final currentLang = ref.read(languageProvider);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    currentLang == AppLanguage.hindi
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
            icon: Icon(
              Icons.g_translate_rounded,
              size: 19,
              color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
            ),
            tooltip: 'Switch Language / भाषा बदलें',
          ),

          // Theme Toggle
          IconButton(
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          
          // Role Swapping Dropdown Menu
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard,
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  )
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<UserRole>(
                  value: role,
                  dropdownColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                  ),
                  onChanged: (UserRole? newRole) {
                    if (newRole != null) {
                      ref.read(userRoleProvider.notifier).state = newRole;
                      ref.read(currentTabProvider.notifier).state = 0; // Reset tab
                    }
                  },
                  items: UserRole.values.map<DropdownMenuItem<UserRole>>((UserRole val) {
                    return DropdownMenuItem<UserRole>(
                      value: val,
                      child: Row(
                        children: [
                          Text(
                            getRoleBadgeEmoji(val),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            val.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: getBodyView(),
    );
  }
}
