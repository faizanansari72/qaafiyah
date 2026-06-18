import 'dart:convert';
import 'package:isar/isar.dart';
import '../local/entities/isar_entities.dart';
import '../local/isar_service.dart';
import '../../domain/models/domain_models.dart';
import '../../domain/repositories/repositories.dart';

// 1. Entrepreneur Repository
class EntrepreneurRepository implements IEntrepreneurRepository {
  final IsarService _isarService;
  EntrepreneurRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  @override
  Future<List<Entrepreneur>> getAllEntrepreneurs() async {
    final entities = await _isar.entrepreneurEntitys.where().sortByRank().findAll();
    return entities.map(_map).toList();
  }

  @override
  Future<Entrepreneur?> getEntrepreneurById(String id) async {
    final entity = await _isar.entrepreneurEntitys.filter().uidEqualTo(id).findFirst();
    return entity != null ? _map(entity) : null;
  }

  @override
  Future<void> updateEntrepreneur(Entrepreneur e) async {
    final entity = await _isar.entrepreneurEntitys.filter().uidEqualTo(e.id).findFirst() ?? EntrepreneurEntity();
    entity.uid = e.id;
    entity.name = e.name;
    entity.businessName = e.businessName;
    entity.email = e.email;
    entity.phone = e.phone;
    entity.avatar = e.avatar;
    entity.eliteScore = e.eliteScore;
    entity.growthScore = e.growthScore;
    entity.profitabilityScore = e.profitabilityScore;
    entity.fulfillmentScore = e.fulfillmentScore;
    entity.supplierScore = e.supplierScore;
    entity.deliveryScore = e.deliveryScore;
    entity.operationsScore = e.operationsScore;
    entity.rank = e.rank;
    entity.isApproved = e.isApproved;
    entity.createdAt = e.createdAt;

    await _isar.writeTxn(() async {
      await _isar.entrepreneurEntitys.put(entity);
    });
  }

  Entrepreneur _map(EntrepreneurEntity entity) {
    return Entrepreneur(
      id: entity.uid,
      name: entity.name,
      businessName: entity.businessName,
      email: entity.email,
      phone: entity.phone,
      avatar: entity.avatar,
      eliteScore: entity.eliteScore,
      growthScore: entity.growthScore,
      profitabilityScore: entity.profitabilityScore,
      fulfillmentScore: entity.fulfillmentScore,
      supplierScore: entity.supplierScore,
      deliveryScore: entity.deliveryScore,
      operationsScore: entity.operationsScore,
      rank: entity.rank,
      isApproved: entity.isApproved,
      createdAt: entity.createdAt,
    );
  }
}

// 2. Product Repository
class ProductRepository implements IProductRepository {
  final IsarService _isarService;
  ProductRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  @override
  Future<List<Product>> getAllProducts() async {
    final entities = await _isar.productEntitys.where().sortByUid().findAll();
    return entities.map(_map).toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    final entity = await _isar.productEntitys.filter().uidEqualTo(id).findFirst();
    return entity != null ? _map(entity) : null;
  }

  @override
  Future<void> saveProduct(Product p) async {
    final entity = await _isar.productEntitys.filter().uidEqualTo(p.id).findFirst() ?? ProductEntity();
    entity.uid = p.id;
    entity.name = p.name;
    entity.sku = p.sku;
    entity.category = p.category;
    entity.costPrice = p.costPrice;
    entity.sellingPrice = p.sellingPrice;
    entity.profitMargin = p.profitMargin;
    entity.inventoryCount = p.inventoryCount;
    entity.supplierId = p.supplierId;
    entity.warehouseId = p.warehouseId;

    await _isar.writeTxn(() async {
      await _isar.productEntitys.put(entity);
    });
  }

  @override
  Future<void> deleteProduct(String id) async {
    final entity = await _isar.productEntitys.filter().uidEqualTo(id).findFirst();
    if (entity != null) {
      await _isar.writeTxn(() async {
        await _isar.productEntitys.delete(entity.id);
      });
    }
  }

  Product _map(ProductEntity entity) {
    return Product(
      id: entity.uid,
      name: entity.name,
      sku: entity.sku,
      category: entity.category,
      costPrice: entity.costPrice,
      sellingPrice: entity.sellingPrice,
      profitMargin: entity.profitMargin,
      inventoryCount: entity.inventoryCount,
      supplierId: entity.supplierId,
      warehouseId: entity.warehouseId,
    );
  }
}

// 3. Supplier Repository
class SupplierRepository implements ISupplierRepository {
  final IsarService _isarService;
  SupplierRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  @override
  Future<List<Supplier>> getAllSuppliers() async {
    final entities = await _isar.supplierEntitys.where().sortByUid().findAll();
    return entities.map(_map).toList();
  }

  @override
  Future<Supplier?> getSupplierById(String id) async {
    final entity = await _isar.supplierEntitys.filter().uidEqualTo(id).findFirst();
    return entity != null ? _map(entity) : null;
  }

  @override
  Future<void> saveSupplier(Supplier s) async {
    final entity = await _isar.supplierEntitys.filter().uidEqualTo(s.id).findFirst() ?? SupplierEntity();
    entity.uid = s.id;
    entity.name = s.name;
    entity.contactPerson = s.contactPerson;
    entity.email = s.email;
    entity.phone = s.phone;
    entity.rating = s.rating;
    entity.leadTime = s.leadTime;
    entity.status = s.status;
    entity.category = s.category;
    entity.reliabilityScore = s.reliabilityScore;

    await _isar.writeTxn(() async {
      await _isar.supplierEntitys.put(entity);
    });
  }

  @override
  Future<void> deleteSupplier(String id) async {
    final entity = await _isar.supplierEntitys.filter().uidEqualTo(id).findFirst();
    if (entity != null) {
      await _isar.writeTxn(() async {
        await _isar.supplierEntitys.delete(entity.id);
      });
    }
  }

  Supplier _map(SupplierEntity entity) {
    return Supplier(
      id: entity.uid,
      name: entity.name,
      contactPerson: entity.contactPerson,
      email: entity.email,
      phone: entity.phone,
      rating: entity.rating,
      leadTime: entity.leadTime,
      status: entity.status,
      category: entity.category,
      reliabilityScore: entity.reliabilityScore,
    );
  }
}

// 4. Warehouse Repository
class WarehouseRepository implements IWarehouseRepository {
  final IsarService _isarService;
  WarehouseRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  @override
  Future<List<Warehouse>> getAllWarehouses() async {
    final entities = await _isar.warehouseEntitys.where().sortByUid().findAll();
    return entities.map(_map).toList();
  }

  @override
  Future<Warehouse?> getWarehouseById(String id) async {
    final entity = await _isar.warehouseEntitys.filter().uidEqualTo(id).findFirst();
    return entity != null ? _map(entity) : null;
  }

  @override
  Future<void> saveWarehouse(Warehouse w) async {
    final entity = await _isar.warehouseEntitys.filter().uidEqualTo(w.id).findFirst() ?? WarehouseEntity();
    entity.uid = w.id;
    entity.name = w.name;
    entity.location = w.location;
    entity.capacity = w.capacity;
    entity.usedCapacity = w.usedCapacity;
    entity.status = w.status;
    entity.managerName = w.managerName;
    entity.contactPhone = w.contactPhone;

    await _isar.writeTxn(() async {
      await _isar.warehouseEntitys.put(entity);
    });
  }

  @override
  Future<void> deleteWarehouse(String id) async {
    final entity = await _isar.warehouseEntitys.filter().uidEqualTo(id).findFirst();
    if (entity != null) {
      await _isar.writeTxn(() async {
        await _isar.warehouseEntitys.delete(entity.id);
      });
    }
  }

  Warehouse _map(WarehouseEntity entity) {
    return Warehouse(
      id: entity.uid,
      name: entity.name,
      location: entity.location,
      capacity: entity.capacity,
      usedCapacity: entity.usedCapacity,
      status: entity.status,
      managerName: entity.managerName,
      contactPhone: entity.contactPhone,
    );
  }
}

// 5. Order Repository
class OrderRepository implements IOrderRepository {
  final IsarService _isarService;
  OrderRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  @override
  Future<List<Order>> getAllOrders() async {
    final entities = await _isar.orderEntitys.where().sortByCreatedAtDesc().findAll();
    return entities.map(_map).toList();
  }

  @override
  Future<List<Order>> getOrdersByEntrepreneur(String entrepreneurId) async {
    final entities = await _isar.orderEntitys.filter().entrepreneurIdEqualTo(entrepreneurId).sortByCreatedAtDesc().findAll();
    return entities.map(_map).toList();
  }

  @override
  Future<Order?> getOrderById(String id) async {
    final entity = await _isar.orderEntitys.filter().uidEqualTo(id).findFirst();
    return entity != null ? _map(entity) : null;
  }

  @override
  Future<void> saveOrder(Order o) async {
    final entity = await _isar.orderEntitys.filter().uidEqualTo(o.id).findFirst() ?? OrderEntity();
    entity.uid = o.id;
    entity.orderNumber = o.orderNumber;
    entity.entrepreneurId = o.entrepreneurId;
    entity.businessName = o.businessName;
    entity.customerName = o.customerName;
    entity.customerEmail = o.customerEmail;
    entity.customerPhone = o.customerPhone;
    entity.shippingAddress = o.shippingAddress;
    entity.city = o.city;
    entity.state = o.state;
    entity.pincode = o.pincode;
    entity.totalAmount = o.totalAmount;
    entity.status = o.status;
    entity.paymentMethod = o.paymentMethod;
    entity.paymentStatus = o.paymentStatus;
    entity.createdAt = o.createdAt;
    entity.itemsJson = jsonEncode(o.items.map((i) => i.toJson()).toList());
    entity.courierPartner = o.courierPartner;
    entity.trackingNumber = o.trackingNumber;
    entity.timelineJson = jsonEncode(o.shipmentTimeline.map((t) => t.toJson()).toList());

    await _isar.writeTxn(() async {
      await _isar.orderEntitys.put(entity);
    });
  }

  @override
  Future<void> deleteOrder(String id) async {
    final entity = await _isar.orderEntitys.filter().uidEqualTo(id).findFirst();
    if (entity != null) {
      await _isar.writeTxn(() async {
        await _isar.orderEntitys.delete(entity.id);
      });
    }
  }

  Order _map(OrderEntity entity) {
    final List itemsRaw = jsonDecode(entity.itemsJson);
    final items = itemsRaw.map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e))).toList();

    final List timelineRaw = jsonDecode(entity.timelineJson);
    final timeline = timelineRaw.map((e) => ShipmentTimelineEntry.fromJson(Map<String, dynamic>.from(e))).toList();

    return Order(
      id: entity.uid,
      orderNumber: entity.orderNumber,
      entrepreneurId: entity.entrepreneurId,
      businessName: entity.businessName,
      customerName: entity.customerName,
      customerEmail: entity.customerEmail,
      customerPhone: entity.customerPhone,
      shippingAddress: entity.shippingAddress,
      city: entity.city,
      state: entity.state,
      pincode: entity.pincode,
      totalAmount: entity.totalAmount,
      status: entity.status,
      paymentMethod: entity.paymentMethod,
      paymentStatus: entity.paymentStatus,
      createdAt: entity.createdAt,
      items: items,
      courierPartner: entity.courierPartner,
      trackingNumber: entity.trackingNumber,
      shipmentTimeline: timeline,
    );
  }
}

// 6. COD Repository
class CodRepository implements ICodRepository {
  final IsarService _isarService;
  CodRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  @override
  Future<List<CodSettlement>> getAllSettlements() async {
    final entities = await _isar.codSettlementEntitys.where().sortByPeriodEndDesc().findAll();
    return entities.map(_map).toList();
  }

  @override
  Future<void> saveSettlement(CodSettlement s) async {
    final entity = await _isar.codSettlementEntitys.filter().uidEqualTo(s.id).findFirst() ?? CodSettlementEntity();
    entity.uid = s.id;
    entity.settlementCycle = s.settlementCycle;
    entity.periodStart = s.periodStart;
    entity.periodEnd = s.periodEnd;
    entity.amount = s.amount;
    entity.ordersCount = s.ordersCount;
    entity.status = s.status;
    entity.bankReference = s.bankReference;
    entity.settledAt = s.settledAt;

    await _isar.writeTxn(() async {
      await _isar.codSettlementEntitys.put(entity);
    });
  }

  CodSettlement _map(CodSettlementEntity entity) {
    return CodSettlement(
      id: entity.uid,
      settlementCycle: entity.settlementCycle,
      periodStart: entity.periodStart,
      periodEnd: entity.periodEnd,
      amount: entity.amount,
      ordersCount: entity.ordersCount,
      status: entity.status,
      bankReference: entity.bankReference,
      settledAt: entity.settledAt,
    );
  }
}

// 7. Community Repository
class CommunityRepository implements ICommunityRepository {
  final IsarService _isarService;
  CommunityRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  @override
  Future<List<CommunityPost>> getAllPosts() async {
    final entities = await _isar.communityPostEntitys.where().sortByCreatedAtDesc().findAll();
    return entities.map(_map).toList();
  }

  @override
  Future<void> savePost(CommunityPost p) async {
    final entity = await _isar.communityPostEntitys.filter().uidEqualTo(p.id).findFirst() ?? CommunityPostEntity();
    entity.uid = p.id;
    entity.authorName = p.authorName;
    entity.authorBusiness = p.authorBusiness;
    entity.authorAvatar = p.authorAvatar;
    entity.title = p.title;
    entity.content = p.content;
    entity.likes = p.likes;
    entity.comments = p.comments;
    entity.createdAt = p.createdAt;

    await _isar.writeTxn(() async {
      await _isar.communityPostEntitys.put(entity);
    });
  }

  @override
  Future<void> deletePost(String id) async {
    final entity = await _isar.communityPostEntitys.filter().uidEqualTo(id).findFirst();
    if (entity != null) {
      await _isar.writeTxn(() async {
        await _isar.communityPostEntitys.delete(entity.id);
      });
    }
  }

  CommunityPost _map(CommunityPostEntity entity) {
    return CommunityPost(
      id: entity.uid,
      authorName: entity.authorName,
      authorBusiness: entity.authorBusiness,
      authorAvatar: entity.authorAvatar,
      title: entity.title,
      content: entity.content,
      likes: entity.likes,
      comments: entity.comments,
      createdAt: entity.createdAt,
    );
  }
}

// 8. Support Repository
class SupportRepository implements ISupportRepository {
  final IsarService _isarService;
  SupportRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  @override
  Future<List<SupportTicket>> getAllTickets() async {
    final entities = await _isar.supportTicketEntitys.where().sortByCreatedAtDesc().findAll();
    return entities.map(_map).toList();
  }

  @override
  Future<List<SupportTicket>> getTicketsByEntrepreneur(String entrepreneurId) async {
    final entities = await _isar.supportTicketEntitys.filter().entrepreneurIdEqualTo(entrepreneurId).sortByCreatedAtDesc().findAll();
    return entities.map(_map).toList();
  }

  @override
  Future<void> saveTicket(SupportTicket t) async {
    final entity = await _isar.supportTicketEntitys.filter().uidEqualTo(t.id).findFirst() ?? SupportTicketEntity();
    entity.uid = t.id;
    entity.entrepreneurId = t.entrepreneurId;
    entity.businessName = t.businessName;
    entity.title = t.title;
    entity.description = t.description;
    entity.category = t.category;
    entity.priority = t.priority;
    entity.status = t.status;
    entity.createdAt = t.createdAt;

    await _isar.writeTxn(() async {
      await _isar.supportTicketEntitys.put(entity);
    });
  }

  @override
  Future<void> deleteTicket(String id) async {
    final entity = await _isar.supportTicketEntitys.filter().uidEqualTo(id).findFirst();
    if (entity != null) {
      await _isar.writeTxn(() async {
        await _isar.supportTicketEntitys.delete(entity.id);
      });
    }
  }

  SupportTicket _map(SupportTicketEntity entity) {
    return SupportTicket(
      id: entity.uid,
      entrepreneurId: entity.entrepreneurId,
      businessName: entity.businessName,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      priority: entity.priority,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }
}

// 9. Admin Repository
class AdminRepository implements IAdminRepository {
  final IsarService _isarService;
  AdminRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  @override
  Future<List<AdminApplication>> getAllApplications() async {
    final entities = await _isar.adminApplicationEntitys.where().sortByAppliedAtDesc().findAll();
    return entities.map(_map).toList();
  }

  @override
  Future<void> saveApplication(AdminApplication a) async {
    final entity = await _isar.adminApplicationEntitys.filter().uidEqualTo(a.id).findFirst() ?? AdminApplicationEntity();
    entity.uid = a.id;
    entity.applicantName = a.applicantName;
    entity.businessName = a.businessName;
    entity.email = a.email;
    entity.phone = a.phone;
    entity.annualRevenue = a.annualRevenue;
    entity.category = a.category;
    entity.description = a.description;
    entity.status = a.status;
    entity.appliedAt = a.appliedAt;

    await _isar.writeTxn(() async {
      await _isar.adminApplicationEntitys.put(entity);
    });
  }

  AdminApplication _map(AdminApplicationEntity entity) {
    return AdminApplication(
      id: entity.uid,
      applicantName: entity.applicantName,
      businessName: entity.businessName,
      email: entity.email,
      phone: entity.phone,
      annualRevenue: entity.annualRevenue,
      category: entity.category,
      description: entity.description,
      status: entity.status,
      appliedAt: entity.appliedAt,
    );
  }
}
