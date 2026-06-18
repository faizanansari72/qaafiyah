import 'package:freezed_annotation/freezed_annotation.dart';

part 'domain_models.freezed.dart';
part 'domain_models.g.dart';

@freezed
class Entrepreneur with _$Entrepreneur {
  const factory Entrepreneur({
    required String id,
    required String name,
    required String businessName,
    required String email,
    required String phone,
    required String avatar,
    required int eliteScore,
    required int growthScore,
    required int profitabilityScore,
    required int fulfillmentScore,
    required int supplierScore,
    required int deliveryScore,
    required int operationsScore,
    required int rank,
    required bool isApproved,
    required String createdAt,
  }) = _Entrepreneur;

  factory Entrepreneur.fromJson(Map<String, dynamic> json) => _$EntrepreneurFromJson(json);
}

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required String sku,
    required String category,
    required int costPrice,
    required int sellingPrice,
    required int profitMargin,
    required int inventoryCount,
    required String supplierId,
    required String warehouseId,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}

@freezed
class Supplier with _$Supplier {
  const factory Supplier({
    required String id,
    required String name,
    required String contactPerson,
    required String email,
    required String phone,
    required double rating,
    required int leadTime,
    required String status,
    required String category,
    required int reliabilityScore,
  }) = _Supplier;

  factory Supplier.fromJson(Map<String, dynamic> json) => _$SupplierFromJson(json);
}

@freezed
class Warehouse with _$Warehouse {
  const factory Warehouse({
    required String id,
    required String name,
    required String location,
    required int capacity,
    required int usedCapacity,
    required String status,
    required String managerName,
    required String contactPhone,
  }) = _Warehouse;

  factory Warehouse.fromJson(Map<String, dynamic> json) => _$WarehouseFromJson(json);
}

@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String productId,
    required String productName,
    required int quantity,
    required int price,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
}

@freezed
class ShipmentTimelineEntry with _$ShipmentTimelineEntry {
  const factory ShipmentTimelineEntry({
    required String status,
    required String title,
    required String description,
    required String timestamp,
  }) = _ShipmentTimelineEntry;

  factory ShipmentTimelineEntry.fromJson(Map<String, dynamic> json) => _$ShipmentTimelineEntryFromJson(json);
}

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required String orderNumber,
    required String entrepreneurId,
    required String businessName,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String shippingAddress,
    required String city,
    required String state,
    required String pincode,
    required int totalAmount,
    required String status, // Pending, Processing, Packed, Shipped, Delivered, Returned, RTO
    required String paymentMethod, // COD, Pre-paid
    required String paymentStatus, // Pending, Collected, Settled, Paid
    required String createdAt,
    required List<OrderItem> items,
    required String courierPartner,
    required String trackingNumber,
    required List<ShipmentTimelineEntry> shipmentTimeline,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

@freezed
class CodSettlement with _$CodSettlement {
  const factory CodSettlement({
    required String id,
    required String settlementCycle,
    required String periodStart,
    required String periodEnd,
    required int amount,
    required int ordersCount,
    required String status, // Pending, Processing, Settled
    required String bankReference,
    required String settledAt,
  }) = _CodSettlement;

  factory CodSettlement.fromJson(Map<String, dynamic> json) => _$CodSettlementFromJson(json);
}

@freezed
class CommunityPost with _$CommunityPost {
  const factory CommunityPost({
    required String id,
    required String authorName,
    required String authorBusiness,
    required String authorAvatar,
    required String title,
    required String content,
    required int likes,
    required int comments,
    required String createdAt,
  }) = _CommunityPost;

  factory CommunityPost.fromJson(Map<String, dynamic> json) => _$CommunityPostFromJson(json);
}

@freezed
class SupportTicket with _$SupportTicket {
  const factory SupportTicket({
    required String id,
    required String entrepreneurId,
    required String businessName,
    required String title,
    required String description,
    required String category,
    required String priority,
    required String status,
    required String createdAt,
  }) = _SupportTicket;

  factory SupportTicket.fromJson(Map<String, dynamic> json) => _$SupportTicketFromJson(json);
}

@freezed
class AdminApplication with _$AdminApplication {
  const factory AdminApplication({
    required String id,
    required String applicantName,
    required String businessName,
    required String email,
    required String phone,
    required String annualRevenue,
    required String category,
    required String description,
    required String status, // Pending, Approved, Rejected
    required String appliedAt,
  }) = _AdminApplication;

  factory AdminApplication.fromJson(Map<String, dynamic> json) => _$AdminApplicationFromJson(json);
}
