import 'package:isar/isar.dart';

part 'isar_entities.g.dart';

@collection
class EntrepreneurEntity {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String uid;
  
  late String name;
  late String businessName;
  late String email;
  late String phone;
  late String avatar;
  
  late int eliteScore;
  late int growthScore;
  late int profitabilityScore;
  late int fulfillmentScore;
  late int supplierScore;
  late int deliveryScore;
  late int operationsScore;
  late int rank;
  late bool isApproved;
  late String createdAt;
}

@collection
class ProductEntity {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String uid;
  
  late String name;
  late String sku;
  late String category;
  late int costPrice;
  late int sellingPrice;
  late int profitMargin;
  late int inventoryCount;
  late String supplierId;
  late String warehouseId;
}

@collection
class SupplierEntity {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String uid;
  
  late String name;
  late String contactPerson;
  late String email;
  late String phone;
  late double rating;
  late int leadTime;
  late String status;
  late String category;
  late int reliabilityScore;
}

@collection
class WarehouseEntity {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String uid;
  
  late String name;
  late String location;
  late int capacity;
  late int usedCapacity;
  late String status;
  late String managerName;
  late String contactPhone;
}

@collection
class OrderEntity {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String uid;
  
  late String orderNumber;
  late String entrepreneurId;
  late String businessName;
  late String customerName;
  late String customerEmail;
  late String customerPhone;
  late String shippingAddress;
  late String city;
  late String state;
  late String pincode;
  late int totalAmount;
  late String status; // Pending, Processing, Packed, Shipped, Delivered, Returned, RTO
  late String paymentMethod; // COD, Pre-paid
  late String paymentStatus; // Pending, Collected, Settled, Paid
  late String createdAt;
  
  late String itemsJson;
  late String courierPartner;
  late String trackingNumber;
  late String timelineJson;
}

@collection
class CodSettlementEntity {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String uid;
  
  late String settlementCycle;
  late String periodStart;
  late String periodEnd;
  late int amount;
  late int ordersCount;
  late String status; // Pending, Processing, Settled
  late String bankReference;
  late String settledAt;
}

@collection
class CommunityPostEntity {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String uid;
  
  late String authorName;
  late String authorBusiness;
  late String authorAvatar;
  late String title;
  late String content;
  late int likes;
  late int comments;
  late String createdAt;
}

@collection
class SupportTicketEntity {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String uid;
  
  late String entrepreneurId;
  late String businessName;
  late String title;
  late String description;
  late String category;
  late String priority;
  late String status;
  late String createdAt;
}

@collection
class AdminApplicationEntity {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String uid;
  
  late String applicantName;
  late String businessName;
  late String email;
  late String phone;
  late String annualRevenue;
  late String category;
  late String description;
  late String status;
  late String appliedAt;
}
