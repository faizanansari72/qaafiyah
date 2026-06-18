// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EntrepreneurImpl _$$EntrepreneurImplFromJson(Map<String, dynamic> json) =>
    _$EntrepreneurImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      businessName: json['businessName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      avatar: json['avatar'] as String,
      eliteScore: (json['eliteScore'] as num).toInt(),
      growthScore: (json['growthScore'] as num).toInt(),
      profitabilityScore: (json['profitabilityScore'] as num).toInt(),
      fulfillmentScore: (json['fulfillmentScore'] as num).toInt(),
      supplierScore: (json['supplierScore'] as num).toInt(),
      deliveryScore: (json['deliveryScore'] as num).toInt(),
      operationsScore: (json['operationsScore'] as num).toInt(),
      rank: (json['rank'] as num).toInt(),
      isApproved: json['isApproved'] as bool,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$$EntrepreneurImplToJson(_$EntrepreneurImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'businessName': instance.businessName,
      'email': instance.email,
      'phone': instance.phone,
      'avatar': instance.avatar,
      'eliteScore': instance.eliteScore,
      'growthScore': instance.growthScore,
      'profitabilityScore': instance.profitabilityScore,
      'fulfillmentScore': instance.fulfillmentScore,
      'supplierScore': instance.supplierScore,
      'deliveryScore': instance.deliveryScore,
      'operationsScore': instance.operationsScore,
      'rank': instance.rank,
      'isApproved': instance.isApproved,
      'createdAt': instance.createdAt,
    };

_$ProductImpl _$$ProductImplFromJson(Map<String, dynamic> json) =>
    _$ProductImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      category: json['category'] as String,
      costPrice: (json['costPrice'] as num).toInt(),
      sellingPrice: (json['sellingPrice'] as num).toInt(),
      profitMargin: (json['profitMargin'] as num).toInt(),
      inventoryCount: (json['inventoryCount'] as num).toInt(),
      supplierId: json['supplierId'] as String,
      warehouseId: json['warehouseId'] as String,
    );

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sku': instance.sku,
      'category': instance.category,
      'costPrice': instance.costPrice,
      'sellingPrice': instance.sellingPrice,
      'profitMargin': instance.profitMargin,
      'inventoryCount': instance.inventoryCount,
      'supplierId': instance.supplierId,
      'warehouseId': instance.warehouseId,
    };

_$SupplierImpl _$$SupplierImplFromJson(Map<String, dynamic> json) =>
    _$SupplierImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      contactPerson: json['contactPerson'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      rating: (json['rating'] as num).toDouble(),
      leadTime: (json['leadTime'] as num).toInt(),
      status: json['status'] as String,
      category: json['category'] as String,
      reliabilityScore: (json['reliabilityScore'] as num).toInt(),
    );

Map<String, dynamic> _$$SupplierImplToJson(_$SupplierImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'contactPerson': instance.contactPerson,
      'email': instance.email,
      'phone': instance.phone,
      'rating': instance.rating,
      'leadTime': instance.leadTime,
      'status': instance.status,
      'category': instance.category,
      'reliabilityScore': instance.reliabilityScore,
    };

_$WarehouseImpl _$$WarehouseImplFromJson(Map<String, dynamic> json) =>
    _$WarehouseImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      capacity: (json['capacity'] as num).toInt(),
      usedCapacity: (json['usedCapacity'] as num).toInt(),
      status: json['status'] as String,
      managerName: json['managerName'] as String,
      contactPhone: json['contactPhone'] as String,
    );

Map<String, dynamic> _$$WarehouseImplToJson(_$WarehouseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'location': instance.location,
      'capacity': instance.capacity,
      'usedCapacity': instance.usedCapacity,
      'status': instance.status,
      'managerName': instance.managerName,
      'contactPhone': instance.contactPhone,
    };

_$OrderItemImpl _$$OrderItemImplFromJson(Map<String, dynamic> json) =>
    _$OrderItemImpl(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num).toInt(),
    );

Map<String, dynamic> _$$OrderItemImplToJson(_$OrderItemImpl instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'quantity': instance.quantity,
      'price': instance.price,
    };

_$ShipmentTimelineEntryImpl _$$ShipmentTimelineEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ShipmentTimelineEntryImpl(
      status: json['status'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: json['timestamp'] as String,
    );

Map<String, dynamic> _$$ShipmentTimelineEntryImplToJson(
        _$ShipmentTimelineEntryImpl instance) =>
    <String, dynamic>{
      'status': instance.status,
      'title': instance.title,
      'description': instance.description,
      'timestamp': instance.timestamp,
    };

_$OrderImpl _$$OrderImplFromJson(Map<String, dynamic> json) => _$OrderImpl(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      entrepreneurId: json['entrepreneurId'] as String,
      businessName: json['businessName'] as String,
      customerName: json['customerName'] as String,
      customerEmail: json['customerEmail'] as String,
      customerPhone: json['customerPhone'] as String,
      shippingAddress: json['shippingAddress'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String,
      totalAmount: (json['totalAmount'] as num).toInt(),
      status: json['status'] as String,
      paymentMethod: json['paymentMethod'] as String,
      paymentStatus: json['paymentStatus'] as String,
      createdAt: json['createdAt'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      courierPartner: json['courierPartner'] as String,
      trackingNumber: json['trackingNumber'] as String,
      shipmentTimeline: (json['shipmentTimeline'] as List<dynamic>)
          .map((e) => ShipmentTimelineEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$OrderImplToJson(_$OrderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderNumber': instance.orderNumber,
      'entrepreneurId': instance.entrepreneurId,
      'businessName': instance.businessName,
      'customerName': instance.customerName,
      'customerEmail': instance.customerEmail,
      'customerPhone': instance.customerPhone,
      'shippingAddress': instance.shippingAddress,
      'city': instance.city,
      'state': instance.state,
      'pincode': instance.pincode,
      'totalAmount': instance.totalAmount,
      'status': instance.status,
      'paymentMethod': instance.paymentMethod,
      'paymentStatus': instance.paymentStatus,
      'createdAt': instance.createdAt,
      'items': instance.items,
      'courierPartner': instance.courierPartner,
      'trackingNumber': instance.trackingNumber,
      'shipmentTimeline': instance.shipmentTimeline,
    };

_$CodSettlementImpl _$$CodSettlementImplFromJson(Map<String, dynamic> json) =>
    _$CodSettlementImpl(
      id: json['id'] as String,
      settlementCycle: json['settlementCycle'] as String,
      periodStart: json['periodStart'] as String,
      periodEnd: json['periodEnd'] as String,
      amount: (json['amount'] as num).toInt(),
      ordersCount: (json['ordersCount'] as num).toInt(),
      status: json['status'] as String,
      bankReference: json['bankReference'] as String,
      settledAt: json['settledAt'] as String,
    );

Map<String, dynamic> _$$CodSettlementImplToJson(_$CodSettlementImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'settlementCycle': instance.settlementCycle,
      'periodStart': instance.periodStart,
      'periodEnd': instance.periodEnd,
      'amount': instance.amount,
      'ordersCount': instance.ordersCount,
      'status': instance.status,
      'bankReference': instance.bankReference,
      'settledAt': instance.settledAt,
    };

_$CommunityPostImpl _$$CommunityPostImplFromJson(Map<String, dynamic> json) =>
    _$CommunityPostImpl(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      authorBusiness: json['authorBusiness'] as String,
      authorAvatar: json['authorAvatar'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      likes: (json['likes'] as num).toInt(),
      comments: (json['comments'] as num).toInt(),
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$$CommunityPostImplToJson(_$CommunityPostImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'authorName': instance.authorName,
      'authorBusiness': instance.authorBusiness,
      'authorAvatar': instance.authorAvatar,
      'title': instance.title,
      'content': instance.content,
      'likes': instance.likes,
      'comments': instance.comments,
      'createdAt': instance.createdAt,
    };

_$SupportTicketImpl _$$SupportTicketImplFromJson(Map<String, dynamic> json) =>
    _$SupportTicketImpl(
      id: json['id'] as String,
      entrepreneurId: json['entrepreneurId'] as String,
      businessName: json['businessName'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$$SupportTicketImplToJson(_$SupportTicketImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'entrepreneurId': instance.entrepreneurId,
      'businessName': instance.businessName,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'priority': instance.priority,
      'status': instance.status,
      'createdAt': instance.createdAt,
    };

_$AdminApplicationImpl _$$AdminApplicationImplFromJson(
        Map<String, dynamic> json) =>
    _$AdminApplicationImpl(
      id: json['id'] as String,
      applicantName: json['applicantName'] as String,
      businessName: json['businessName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      annualRevenue: json['annualRevenue'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      appliedAt: json['appliedAt'] as String,
    );

Map<String, dynamic> _$$AdminApplicationImplToJson(
        _$AdminApplicationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'applicantName': instance.applicantName,
      'businessName': instance.businessName,
      'email': instance.email,
      'phone': instance.phone,
      'annualRevenue': instance.annualRevenue,
      'category': instance.category,
      'description': instance.description,
      'status': instance.status,
      'appliedAt': instance.appliedAt,
    };
