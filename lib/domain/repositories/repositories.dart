import '../models/domain_models.dart';

abstract class IEntrepreneurRepository {
  Future<List<Entrepreneur>> getAllEntrepreneurs();
  Future<Entrepreneur?> getEntrepreneurById(String id);
  Future<void> updateEntrepreneur(Entrepreneur entrepreneur);
}

abstract class IProductRepository {
  Future<List<Product>> getAllProducts();
  Future<Product?> getProductById(String id);
  Future<void> saveProduct(Product product);
  Future<void> deleteProduct(String id);
}

abstract class ISupplierRepository {
  Future<List<Supplier>> getAllSuppliers();
  Future<Supplier?> getSupplierById(String id);
  Future<void> saveSupplier(Supplier supplier);
  Future<void> deleteSupplier(String id);
}

abstract class IWarehouseRepository {
  Future<List<Warehouse>> getAllWarehouses();
  Future<Warehouse?> getWarehouseById(String id);
  Future<void> saveWarehouse(Warehouse warehouse);
  Future<void> deleteWarehouse(String id);
}

abstract class IOrderRepository {
  Future<List<Order>> getAllOrders();
  Future<List<Order>> getOrdersByEntrepreneur(String entrepreneurId);
  Future<Order?> getOrderById(String id);
  Future<void> saveOrder(Order order);
  Future<void> deleteOrder(String id);
}

abstract class ICodRepository {
  Future<List<CodSettlement>> getAllSettlements();
  Future<void> saveSettlement(CodSettlement settlement);
}

abstract class ICommunityRepository {
  Future<List<CommunityPost>> getAllPosts();
  Future<void> savePost(CommunityPost post);
  Future<void> deletePost(String id);
}

abstract class ISupportRepository {
  Future<List<SupportTicket>> getAllTickets();
  Future<List<SupportTicket>> getTicketsByEntrepreneur(String entrepreneurId);
  Future<void> saveTicket(SupportTicket ticket);
  Future<void> deleteTicket(String id);
}

abstract class IAdminRepository {
  Future<List<AdminApplication>> getAllApplications();
  Future<void> saveApplication(AdminApplication application);
}
