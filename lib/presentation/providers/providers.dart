import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/isar_service.dart';
import '../../data/repositories/repositories_impl.dart';
import '../../data/services/ai_service.dart';
import '../../domain/models/domain_models.dart';
import '../../domain/repositories/repositories.dart';

// 1. Isar Service Provider
final isarServiceProvider = Provider<IsarService>((ref) => IsarService());

// 1.1 AI Service Provider
final aiServiceProvider = Provider<AiService>((ref) => AiService());

// 2. Repository Providers
final entrepreneurRepositoryProvider = Provider<IEntrepreneurRepository>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return EntrepreneurRepository(isar);
});

final productRepositoryProvider = Provider<IProductRepository>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return ProductRepository(isar);
});

final supplierRepositoryProvider = Provider<ISupplierRepository>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return SupplierRepository(isar);
});

final warehouseRepositoryProvider = Provider<IWarehouseRepository>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return WarehouseRepository(isar);
});

final orderRepositoryProvider = Provider<IOrderRepository>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return OrderRepository(isar);
});

final codRepositoryProvider = Provider<ICodRepository>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return CodRepository(isar);
});

final communityRepositoryProvider = Provider<ICommunityRepository>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return CommunityRepository(isar);
});

final supportRepositoryProvider = Provider<ISupportRepository>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return SupportRepository(isar);
});

final adminRepositoryProvider = Provider<IAdminRepository>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return AdminRepository(isar);
});

// 3. User Roles
enum UserRole {
  entrepreneur,
  admin,
  supplier,
  logisticsPartner;

  String get name {
    switch (this) {
      case UserRole.entrepreneur:
        return 'Entrepreneur';
      case UserRole.admin:
        return 'Qaafiya Admin';
      case UserRole.supplier:
        return 'Supplier';
      case UserRole.logisticsPartner:
        return 'Logistics Partner';
    }
  }
}

final userRoleProvider = StateProvider<UserRole>((ref) => UserRole.entrepreneur);

// 4. Current Entrepreneur Provider (The active entrepreneur profile)
final currentEntrepreneurProvider = StateNotifierProvider<CurrentEntrepreneurNotifier, Entrepreneur?>((ref) {
  final repo = ref.watch(entrepreneurRepositoryProvider);
  return CurrentEntrepreneurNotifier(repo);
});

class CurrentEntrepreneurNotifier extends StateNotifier<Entrepreneur?> {
  final IEntrepreneurRepository _repo;
  CurrentEntrepreneurNotifier(this._repo) : super(null) {
    loadDefault();
  }

  Future<void> loadDefault() async {
    final list = await _repo.getAllEntrepreneurs();
    if (list.isNotEmpty) {
      state = list.first; // Default to first (rank #1, Aarav Sharma)
    }
  }

  void setEntrepreneur(Entrepreneur e) {
    state = e;
  }
}

// 5. Language Provider (Persistent language switching between English and Hindi)
enum AppLanguage { english, hindi }

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.english) {
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('appLanguage') ?? 'en';
    state = lang == 'hi' ? AppLanguage.hindi : AppLanguage.english;
  }

  Future<void> toggleLanguage() async {
    final newLang = state == AppLanguage.english ? AppLanguage.hindi : AppLanguage.english;
    state = newLang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLanguage', newLang == AppLanguage.hindi ? 'hi' : 'en');
  }
}

// 6. Theme Mode Provider (Persistent dark/light theme switching)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode') ?? 'dark';
    state = theme == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      await prefs.setString('themeMode', 'light');
    } else {
      state = ThemeMode.dark;
      await prefs.setString('themeMode', 'dark');
    }
  }
}

// 6. DB Initialization State
final isDbInitializingProvider = StateProvider<bool>((ref) => true);

// 7. Notifier Providers for Active Entities (CRUD states)

// All Entrepreneurs List
final entrepreneursListProvider = StateNotifierProvider<EntrepreneursNotifier, List<Entrepreneur>>((ref) {
  final repo = ref.watch(entrepreneurRepositoryProvider);
  return EntrepreneursNotifier(repo);
});

class EntrepreneursNotifier extends StateNotifier<List<Entrepreneur>> {
  final IEntrepreneurRepository _repo;
  EntrepreneursNotifier(this._repo) : super([]) {
    load();
  }

  Future<void> load() async {
    state = await _repo.getAllEntrepreneurs();
  }

  Future<void> update(Entrepreneur e) async {
    await _repo.updateEntrepreneur(e);
    await load();
  }
}

// Products List
final productsProvider = StateNotifierProvider<ProductsNotifier, List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return ProductsNotifier(repo);
});

class ProductsNotifier extends StateNotifier<List<Product>> {
  final IProductRepository _repo;
  ProductsNotifier(this._repo) : super([]) {
    load();
  }

  Future<void> load() async {
    state = await _repo.getAllProducts();
  }

  Future<void> save(Product p) async {
    await _repo.saveProduct(p);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.deleteProduct(id);
    await load();
  }
}

// Orders List
final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return OrdersNotifier(repo);
});

class OrdersNotifier extends StateNotifier<List<Order>> {
  final IOrderRepository _repo;
  OrdersNotifier(this._repo) : super([]) {
    load();
  }

  Future<void> load() async {
    state = await _repo.getAllOrders();
  }

  Future<void> save(Order o) async {
    await _repo.saveOrder(o);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.deleteOrder(id);
    await load();
  }
}

// Suppliers List
final suppliersProvider = StateNotifierProvider<SuppliersNotifier, List<Supplier>>((ref) {
  final repo = ref.watch(supplierRepositoryProvider);
  return SuppliersNotifier(repo);
});

class SuppliersNotifier extends StateNotifier<List<Supplier>> {
  final ISupplierRepository _repo;
  SuppliersNotifier(this._repo) : super([]) {
    load();
  }

  Future<void> load() async {
    state = await _repo.getAllSuppliers();
  }

  Future<void> save(Supplier s) async {
    await _repo.saveSupplier(s);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.deleteSupplier(id);
    await load();
  }
}

// Warehouses List
final warehousesProvider = StateNotifierProvider<WarehousesNotifier, List<Warehouse>>((ref) {
  final repo = ref.watch(warehouseRepositoryProvider);
  return WarehousesNotifier(repo);
});

class WarehousesNotifier extends StateNotifier<List<Warehouse>> {
  final IWarehouseRepository _repo;
  WarehousesNotifier(this._repo) : super([]) {
    load();
  }

  Future<void> load() async {
    state = await _repo.getAllWarehouses();
  }

  Future<void> save(Warehouse w) async {
    await _repo.saveWarehouse(w);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.deleteWarehouse(id);
    await load();
  }
}

// COD Settlements List
final codSettlementsProvider = StateNotifierProvider<CodSettlementsNotifier, List<CodSettlement>>((ref) {
  final repo = ref.watch(codRepositoryProvider);
  return CodSettlementsNotifier(repo);
});

class CodSettlementsNotifier extends StateNotifier<List<CodSettlement>> {
  final ICodRepository _repo;
  CodSettlementsNotifier(this._repo) : super([]) {
    load();
  }

  Future<void> load() async {
    state = await _repo.getAllSettlements();
  }

  Future<void> save(CodSettlement s) async {
    await _repo.saveSettlement(s);
    await load();
  }
}

// Community Posts List
final communityPostsProvider = StateNotifierProvider<CommunityPostsNotifier, List<CommunityPost>>((ref) {
  final repo = ref.watch(communityRepositoryProvider);
  return CommunityPostsNotifier(repo);
});

class CommunityPostsNotifier extends StateNotifier<List<CommunityPost>> {
  final ICommunityRepository _repo;
  CommunityPostsNotifier(this._repo) : super([]) {
    load();
  }

  Future<void> load() async {
    state = await _repo.getAllPosts();
  }

  Future<void> save(CommunityPost p) async {
    await _repo.savePost(p);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.deletePost(id);
    await load();
  }
}

// Support Tickets List
final supportTicketsProvider = StateNotifierProvider<SupportTicketsNotifier, List<SupportTicket>>((ref) {
  final repo = ref.watch(supportRepositoryProvider);
  return SupportTicketsNotifier(repo);
});

class SupportTicketsNotifier extends StateNotifier<List<SupportTicket>> {
  final ISupportRepository _repo;
  SupportTicketsNotifier(this._repo) : super([]) {
    load();
  }

  Future<void> load() async {
    state = await _repo.getAllTickets();
  }

  Future<void> save(SupportTicket t) async {
    await _repo.saveTicket(t);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.deleteTicket(id);
    await load();
  }
}

// Admin Applications List
final adminApplicationsProvider = StateNotifierProvider<AdminApplicationsNotifier, List<AdminApplication>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return AdminApplicationsNotifier(repo);
});

class AdminApplicationsNotifier extends StateNotifier<List<AdminApplication>> {
  final IAdminRepository _repo;
  AdminApplicationsNotifier(this._repo) : super([]) {
    load();
  }

  Future<void> load() async {
    state = await _repo.getAllApplications();
  }

  Future<void> save(AdminApplication a) async {
    await _repo.saveApplication(a);
    await load();
  }
}

// 8. FutureProvider for Analytics
final revenueAnalyticsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final str = await rootBundle.loadString('assets/json/analytics_revenue.json');
  final List decoded = jsonDecode(str);
  return decoded.cast<Map<String, dynamic>>();
});
