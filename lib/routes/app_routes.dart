import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/onboarding_screen.dart';
import '../presentation/screens/role_switch_wrapper.dart';
import '../presentation/screens/score/score_screen.dart';
import '../presentation/screens/orders/orders_screen.dart';
import '../presentation/screens/products/products_screen.dart';
import '../presentation/screens/suppliers/suppliers_screen.dart';
import '../presentation/screens/warehouses/warehouses_screen.dart';
import '../presentation/screens/cod/cod_screen.dart';
import '../presentation/screens/shipments/shipments_screen.dart';
import '../presentation/screens/analytics/analytics_screen.dart';
import '../presentation/screens/ai_assistant/ai_screen.dart';
import '../presentation/screens/community/community_screen.dart';
import '../presentation/screens/support/support_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String score = '/score';
  static const String orders = '/orders';
  static const String products = '/products';
  static const String suppliers = '/suppliers';
  static const String warehouses = '/warehouses';
  static const String cod = '/cod';
  static const String shipments = '/shipments';
  static const String analytics = '/analytics';
  static const String ai = '/ai';
  static const String community = '/community';
  static const String support = '/support';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const RoleSwitchWrapper(),
      ),
      GoRoute(
        path: score,
        builder: (context, state) => const ScoreScreen(),
      ),
      GoRoute(
        path: orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: products,
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: suppliers,
        builder: (context, state) => const SuppliersScreen(),
      ),
      GoRoute(
        path: warehouses,
        builder: (context, state) => const WarehousesScreen(),
      ),
      GoRoute(
        path: cod,
        builder: (context, state) => const CodScreen(),
      ),
      GoRoute(
        path: shipments,
        builder: (context, state) => const ShipmentsScreen(),
      ),
      GoRoute(
        path: analytics,
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: ai,
        builder: (context, state) => const AiScreen(),
      ),
      GoRoute(
        path: community,
        builder: (context, state) => const CommunityScreen(),
      ),
      GoRoute(
        path: support,
        builder: (context, state) => const SupportScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found: ${state.error}',
          style: const TextStyle(fontSize: 16, color: Colors.red),
        ),
      ),
    ),
  );
}
