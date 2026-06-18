import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'entities/isar_entities.dart';

class IsarService {
  late final Isar isar;
  
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [
        EntrepreneurEntitySchema,
        ProductEntitySchema,
        SupplierEntitySchema,
        WarehouseEntitySchema,
        OrderEntitySchema,
        CodSettlementEntitySchema,
        CommunityPostEntitySchema,
        SupportTicketEntitySchema,
        AdminApplicationEntitySchema,
      ],
      directory: dir.path,
    );
    
    await _seedDatabase();
    await _shiftDatesToCurrentTimeline();
    await _populateRealisticOrdersForAll();
    await _populateSupplierAndSupportData();
  }

  Future<void> _seedDatabase() async {
    final count = await isar.entrepreneurEntitys.count();
    if (count > 0) return; // Already seeded

    try {
      print("Seeding Isar Database with mock JSON data...");

      // Seed entrepreneurs
      final entrepreneursStr = await rootBundle.loadString('assets/json/entrepreneurs.json');
      final List entrepreneursJson = jsonDecode(entrepreneursStr);
      final listEntre = entrepreneursJson.map((e) => EntrepreneurEntity()
        ..uid = e['id']
        ..name = e['name']
        ..businessName = e['businessName']
        ..email = e['email']
        ..phone = e['phone']
        ..avatar = e['avatar']
        ..eliteScore = e['eliteScore']
        ..growthScore = e['growthScore']
        ..profitabilityScore = e['profitabilityScore']
        ..fulfillmentScore = e['fulfillmentScore']
        ..supplierScore = e['supplierScore']
        ..deliveryScore = e['deliveryScore']
        ..operationsScore = e['operationsScore']
        ..rank = e['rank']
        ..isApproved = e['isApproved']
        ..createdAt = e['createdAt']
      ).toList();
      
      await isar.writeTxn(() async {
        await isar.entrepreneurEntitys.putAll(listEntre);
      });
      
      // Seed products
      final productsStr = await rootBundle.loadString('assets/json/products.json');
      final List productsJson = jsonDecode(productsStr);
      final listProd = productsJson.map((e) => ProductEntity()
        ..uid = e['id']
        ..name = e['name']
        ..sku = e['sku']
        ..category = e['category']
        ..costPrice = e['costPrice']
        ..sellingPrice = e['sellingPrice']
        ..profitMargin = e['profitMargin']
        ..inventoryCount = e['inventoryCount']
        ..supplierId = e['supplierId']
        ..warehouseId = e['warehouseId']
      ).toList();
      
      await isar.writeTxn(() async {
        await isar.productEntitys.putAll(listProd);
      });

      // Seed suppliers
      final suppliersStr = await rootBundle.loadString('assets/json/suppliers.json');
      final List suppliersJson = jsonDecode(suppliersStr);
      final listSupp = suppliersJson.map((e) => SupplierEntity()
        ..uid = e['id']
        ..name = e['name']
        ..contactPerson = e['contactPerson']
        ..email = e['email']
        ..phone = e['phone']
        ..rating = e['rating']
        ..leadTime = e['leadTime']
        ..status = e['status']
        ..category = e['category']
        ..reliabilityScore = e['reliabilityScore']
      ).toList();
      
      await isar.writeTxn(() async {
        await isar.supplierEntitys.putAll(listSupp);
      });

      // Seed warehouses
      final warehousesStr = await rootBundle.loadString('assets/json/warehouses.json');
      final List warehousesJson = jsonDecode(warehousesStr);
      final listWare = warehousesJson.map((e) => WarehouseEntity()
        ..uid = e['id']
        ..name = e['name']
        ..location = e['location']
        ..capacity = e['capacity']
        ..usedCapacity = e['usedCapacity']
        ..status = e['status']
        ..managerName = e['managerName']
        ..contactPhone = e['contactPhone']
      ).toList();
      
      await isar.writeTxn(() async {
        await isar.warehouseEntitys.putAll(listWare);
      });

      // Seed orders
      final ordersStr = await rootBundle.loadString('assets/json/orders.json');
      final List ordersJson = jsonDecode(ordersStr);
      final listOrders = ordersJson.map((e) => OrderEntity()
        ..uid = e['id']
        ..orderNumber = e['orderNumber']
        ..entrepreneurId = e['entrepreneurId']
        ..businessName = e['businessName']
        ..customerName = e['customerName']
        ..customerEmail = e['customerEmail']
        ..customerPhone = e['customerPhone']
        ..shippingAddress = e['shippingAddress']
        ..city = e['city']
        ..state = e['state']
        ..pincode = e['pincode']
        ..totalAmount = e['totalAmount']
        ..status = e['status']
        ..paymentMethod = e['paymentMethod']
        ..paymentStatus = e['paymentStatus']
        ..createdAt = e['createdAt']
        ..itemsJson = jsonEncode(e['items'])
        ..courierPartner = e['courierPartner']
        ..trackingNumber = e['trackingNumber']
        ..timelineJson = jsonEncode(e['shipmentTimeline'])
      ).toList();
      
      await isar.writeTxn(() async {
        await isar.orderEntitys.putAll(listOrders);
      });

      // Seed COD Settlements
      final codStr = await rootBundle.loadString('assets/json/cod_history.json');
      final List codJson = jsonDecode(codStr);
      final listCod = codJson.map((e) => CodSettlementEntity()
        ..uid = e['id']
        ..settlementCycle = e['settlementCycle']
        ..periodStart = e['periodStart']
        ..periodEnd = e['periodEnd']
        ..amount = e['amount']
        ..ordersCount = e['ordersCount']
        ..status = e['status']
        ..bankReference = e['bankReference']
        ..settledAt = e['settledAt']
      ).toList();
      
      await isar.writeTxn(() async {
        await isar.codSettlementEntitys.putAll(listCod);
      });

      // Seed Community Posts
      final postsStr = await rootBundle.loadString('assets/json/community_posts.json');
      final List postsJson = jsonDecode(postsStr);
      final listPosts = postsJson.map((e) => CommunityPostEntity()
        ..uid = e['id']
        ..authorName = e['authorName']
        ..authorBusiness = e['authorBusiness']
        ..authorAvatar = e['authorAvatar']
        ..title = e['title']
        ..content = e['content']
        ..likes = e['likes']
        ..comments = e['comments']
        ..createdAt = e['createdAt']
      ).toList();
      
      await isar.writeTxn(() async {
        await isar.communityPostEntitys.putAll(listPosts);
      });

      // Seed Support Tickets
      final ticketsStr = await rootBundle.loadString('assets/json/support_tickets.json');
      final List ticketsJson = jsonDecode(ticketsStr);
      final listTickets = ticketsJson.map((e) => SupportTicketEntity()
        ..uid = e['id']
        ..entrepreneurId = e['entrepreneurId']
        ..businessName = e['businessName']
        ..title = e['title']
        ..description = e['description']
        ..category = e['category']
        ..priority = e['priority']
        ..status = e['status']
        ..createdAt = e['createdAt']
      ).toList();
      
      await isar.writeTxn(() async {
        await isar.supportTicketEntitys.putAll(listTickets);
      });

      // Seed Admin Applications
      final appsStr = await rootBundle.loadString('assets/json/admin_applications.json');
      final List appsJson = jsonDecode(appsStr);
      final listApps = appsJson.map((e) => AdminApplicationEntity()
        ..uid = e['id']
        ..applicantName = e['applicantName']
        ..businessName = e['businessName']
        ..email = e['email']
        ..phone = e['phone']
        ..annualRevenue = e['annualRevenue']
        ..category = e['category']
        ..description = e['description']
        ..status = e['status']
        ..appliedAt = e['appliedAt']
      ).toList();
      
      await isar.writeTxn(() async {
        await isar.adminApplicationEntitys.putAll(listApps);
      });

      print("Isar Database seeded successfully!");
    } catch (e, stackTrace) {
      print("Error during database seeding: $e");
      print(stackTrace);
    }
  }

  Future<void> _shiftDatesToCurrentTimeline() async {
    try {
      final orders = await isar.orderEntitys.where().findAll();
      if (orders.isEmpty) return;

      // Find the latest order date
      DateTime? latestOrderDate;
      for (final order in orders) {
        try {
          final dt = DateTime.parse(order.createdAt);
          if (latestOrderDate == null || dt.isAfter(latestOrderDate)) {
            latestOrderDate = dt;
          }
        } catch (_) {}
      }

      if (latestOrderDate == null) return;

      final now = DateTime.now();
      final difference = now.difference(latestOrderDate);

      // If the difference is very small (e.g. less than 12 hours), no need to shift
      if (difference.inHours.abs() < 12) {
        print("Data dates are already up to date. No shift required.");
        return;
      }

      print("Shifting Isar database dates forward by ${difference.inDays} days to match current timeline...");

      await isar.writeTxn(() async {
        // 1. Shift Orders
        for (final order in orders) {
          try {
            final dt = DateTime.parse(order.createdAt);
            order.createdAt = dt.add(difference).toIso8601String();

            if (order.timelineJson.isNotEmpty) {
              final List timeline = jsonDecode(order.timelineJson);
              for (final entry in timeline) {
                if (entry is Map && entry.containsKey('timestamp')) {
                  final tStr = entry['timestamp'];
                  final tDt = DateTime.parse(tStr);
                  entry['timestamp'] = tDt.add(difference).toIso8601String();
                }
              }
              order.timelineJson = jsonEncode(timeline);
            }
          } catch (_) {}
        }
        await isar.orderEntitys.putAll(orders);

        // 2. Shift COD Settlements
        final settlements = await isar.codSettlementEntitys.where().findAll();
        for (final set in settlements) {
          try {
            final start = DateTime.parse(set.periodStart);
            final end = DateTime.parse(set.periodEnd);
            final settled = DateTime.parse(set.settledAt);
            set.periodStart = start.add(difference).toIso8601String();
            set.periodEnd = end.add(difference).toIso8601String();
            set.settledAt = settled.add(difference).toIso8601String();
          } catch (_) {}
        }
        await isar.codSettlementEntitys.putAll(settlements);

        // 3. Shift Community Posts
        final posts = await isar.communityPostEntitys.where().findAll();
        for (final post in posts) {
          try {
            final dt = DateTime.parse(post.createdAt);
            post.createdAt = dt.add(difference).toIso8601String();
          } catch (_) {}
        }
        await isar.communityPostEntitys.putAll(posts);

        // 4. Shift Support Tickets
        final tickets = await isar.supportTicketEntitys.where().findAll();
        for (final ticket in tickets) {
          try {
            final dt = DateTime.parse(ticket.createdAt);
            ticket.createdAt = dt.add(difference).toIso8601String();
          } catch (_) {}
        }
        await isar.supportTicketEntitys.putAll(tickets);

        // 5. Shift Admin Applications
        final apps = await isar.adminApplicationEntitys.where().findAll();
        for (final app in apps) {
          try {
            final dt = DateTime.parse(app.appliedAt);
            app.appliedAt = dt.add(difference).toIso8601String();
          } catch (_) {}
        }
        await isar.adminApplicationEntitys.putAll(apps);
      });

      print("Isar Database dates shifted successfully!");
    } catch (e) {
      print("Error shifting mock data dates: $e");
    }
  }

  Future<void> _populateRealisticOrdersForAll() async {
    try {
      final products = await isar.productEntitys.where().findAll();
      final entrepreneurs = await isar.entrepreneurEntitys.where().findAll();
      
      if (products.isEmpty || entrepreneurs.isEmpty) return;

      final now = DateTime.now();
      final List<OrderEntity> newOrders = [];

      // Clear existing orders to avoid duplicate overlays and mixed states
      await isar.writeTxn(() async {
        await isar.orderEntitys.clear();
      });

      int orderCounter = 1000;
      for (final entre in entrepreneurs) {
        final rand = Random(entre.uid.hashCode);
        
        // Scale order count based on entrepreneur's rank
        // Rank 1 gets ~90-100 orders, Rank 30 gets ~20-25 orders for rich analytics
        final rank = entre.rank > 0 ? entre.rank : 15;
        final orderCount = max(20, 100 - (rank * 2.5).round());

        for (int i = 0; i < orderCount; i++) {
          // Date distribution
          DateTime oDate;
          if (i < 5) {
            // Today (last 24 hours)
            oDate = now.subtract(Duration(hours: rand.nextInt(24), minutes: rand.nextInt(60)));
          } else if (i < 20) {
            // Last 7 days
            oDate = now.subtract(Duration(days: 1 + rand.nextInt(6), hours: rand.nextInt(24)));
          } else if (i < 50) {
            // Last 30 days
            oDate = now.subtract(Duration(days: 7 + rand.nextInt(23), hours: rand.nextInt(24)));
          } else {
            // Last 180 days (6 months) for chart trend distribution
            oDate = now.subtract(Duration(days: 30 + rand.nextInt(150), hours: rand.nextInt(24)));
          }

          // Random status
          String oStatus = 'Delivered';
          if (i < 2) {
            // Ensure some pending/processing for pipeline diagnostics
            oStatus = i == 0 ? 'Pending' : 'Processing';
          } else {
            final statusRoll = rand.nextDouble();
            if (statusRoll < 0.08) {
              oStatus = 'Pending';
            } else if (statusRoll < 0.20) {
              oStatus = 'Processing';
            } else if (statusRoll < 0.32) {
              oStatus = 'Packed';
            } else if (statusRoll < 0.48) {
              oStatus = 'Shipped';
            } else if (statusRoll < 0.85) {
              oStatus = 'Delivered';
            } else if (statusRoll < 0.93) {
              oStatus = 'Returned';
            } else {
              oStatus = 'RTO';
            }
          }

          // Payment
          final String oPay = rand.nextDouble() > 0.45 ? 'COD' : 'Pre-paid';
          String oPayStat = 'Paid';
          if (oPay == 'COD') {
            if (oStatus == 'Delivered') {
              oPayStat = rand.nextDouble() > 0.3 ? 'Settled' : 'Collected';
            } else if (oStatus == 'Returned' || oStatus == 'RTO') {
              oPayStat = 'Cancelled';
            } else {
              oPayStat = 'Pending';
            }
          }

          // Pick 1 to 3 random products
          final itemsCount = 1 + rand.nextInt(2);
          final items = <Map<String, dynamic>>[];
          int total = 0;
          for (int j = 0; j < itemsCount; j++) {
            final prod = products[rand.nextInt(products.length)];
            final qty = 1 + rand.nextInt(2);
            items.add({
              'productId': prod.uid,
              'productName': prod.name,
              'quantity': qty,
              'price': prod.sellingPrice,
            });
            total += prod.sellingPrice * qty;
          }

          // Build timeline
          final timeline = [
            {
              'status': 'Pending',
              'title': 'Order Confirmed',
              'description': 'Order has been placed successfully.',
              'timestamp': oDate.toIso8601String(),
            },
            if (oStatus != 'Pending')
              {
                'status': 'Processing',
                'title': 'Processing',
                'description': 'Inventory allocated.',
                'timestamp': oDate.add(const Duration(hours: 2)).toIso8601String(),
              },
            if (oStatus == 'Packed' || oStatus == 'Shipped' || oStatus == 'Delivered')
              {
                'status': 'Packed',
                'title': 'Packed',
                'description': 'Handed to courier partner.',
                'timestamp': oDate.add(const Duration(hours: 6)).toIso8601String(),
              },
            if (oStatus == 'Shipped' || oStatus == 'Delivered')
              {
                'status': 'Shipped',
                'title': 'Shipped',
                'description': 'In transit.',
                'timestamp': oDate.add(const Duration(hours: 12)).toIso8601String(),
              },
            if (oStatus == 'Delivered')
              {
                'status': 'Delivered',
                'title': 'Delivered',
                'description': 'Package delivered successfully.',
                'timestamp': oDate.add(const Duration(days: 2)).toIso8601String(),
              }
          ];

          final orderNumber = 'QA-2026-${entre.uid.replaceAll(RegExp(r'\D'), '')}-${orderCounter++}';
          final order = OrderEntity()
            ..uid = 'O_${entre.uid}_$i'
            ..orderNumber = orderNumber
            ..entrepreneurId = entre.uid
            ..businessName = entre.businessName
            ..customerName = 'Customer ${entre.name.split(" ").first} $i'
            ..customerEmail = 'customer$i@example.com'
            ..customerPhone = '+91 99999 0000$i'
            ..shippingAddress = 'House $i, Sector 4, Indiranagar'
            ..city = 'Bengaluru'
            ..state = 'Karnataka'
            ..pincode = '560038'
            ..totalAmount = total
            ..status = oStatus
            ..paymentMethod = oPay
            ..paymentStatus = oPayStat
            ..createdAt = oDate.toIso8601String()
            ..itemsJson = jsonEncode(items)
            ..courierPartner = 'BlueDart Apex'
            ..trackingNumber = 'QFY${1234500 + orderCounter}IN'
            ..timelineJson = jsonEncode(timeline);

          newOrders.add(order);
        }
      }

      await isar.writeTxn(() async {
        await isar.orderEntitys.putAll(newOrders);
      });
      print("Generated ${newOrders.length} scaled orders for all entrepreneur profiles!");
    } catch (e) {
      print("Error generating fresh mock orders: $e");
    }
  }

  Future<void> _populateSupplierAndSupportData() async {
    try {
      // 1. Assign products to active supplier S200 ("Jaipur Blockprints Ltd") and set low stock
      final products = await isar.productEntitys.where().findAll();
      final List<ProductEntity> productsToUpdate = [];
      for (final prod in products) {
        if (prod.uid == 'P100' || prod.uid == 'P101' || prod.uid == 'P102') {
          prod.supplierId = 'S200';
          // Make P100 and P101 low stock (under 50) for warning demo
          if (prod.uid == 'P100') prod.inventoryCount = 18;
          if (prod.uid == 'P101') prod.inventoryCount = 35;
          if (prod.uid == 'P102') prod.inventoryCount = 125;
          productsToUpdate.add(prod);
        }
      }
      
      if (productsToUpdate.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.productEntitys.putAll(productsToUpdate);
        });
        print("Associated products P106, P112, P136 with S200 and adjusted stock counts.");
      }

      // 2. Populate support tickets for every entrepreneur in the database
      final entrepreneurs = await isar.entrepreneurEntitys.where().findAll();
      final List<SupportTicketEntity> newTickets = [];
      
      for (final entre in entrepreneurs) {
        // Check if this entrepreneur already has support tickets in Isar
        final ticketCount = await isar.supportTicketEntitys
            .filter()
            .entrepreneurIdEqualTo(entre.uid)
            .count();
            
        if (ticketCount == 0) {
          // Add 3 realistic support tickets for this entrepreneur
          final now = DateTime.now();
          
          final t1 = SupportTicketEntity()
            ..uid = 'T-${entre.uid}-1'
            ..entrepreneurId = entre.uid
            ..businessName = entre.businessName
            ..title = 'BlueDart Courier Pickup Delay'
            ..description = 'Our daily dispatch courier has not arrived at the warehouse for pickup yet. Yesterday\'s shipment is still pending dispatch. Please check SLA.'
            ..category = 'Shipment & NDR'
            ..priority = 'High'
            ..status = 'In-Progress'
            ..createdAt = now.subtract(const Duration(hours: 18)).toIso8601String();

          final t2 = SupportTicketEntity()
            ..uid = 'T-${entre.uid}-2'
            ..entrepreneurId = entre.uid
            ..businessName = entre.businessName
            ..title = 'Request for Custom Branded Packaging'
            ..description = 'We want to introduce branded boxes for the upcoming festive season. Need approval to store custom packaging material at Bangalore Warehouse.'
            ..category = 'Warehouse Operations'
            ..priority = 'Medium'
            ..status = 'Open'
            ..createdAt = now.subtract(const Duration(days: 2)).toIso8601String();

          final t3 = SupportTicketEntity()
            ..uid = 'T-${entre.uid}-3'
            ..entrepreneurId = entre.uid
            ..businessName = entre.businessName
            ..title = 'COD Clearing Cycle #14 Reconciliation'
            ..description = 'The T+2 settlement for orders between June 12-14 has a variance of ₹3,450. Requesting itemized reconciliation ledger.'
            ..category = 'COD Finance'
            ..priority = 'Low'
            ..status = 'Resolved'
            ..createdAt = now.subtract(const Duration(days: 8)).toIso8601String();

          newTickets.add(t1);
          newTickets.add(t2);
          newTickets.add(t3);
        }
      }

      if (newTickets.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.supportTicketEntitys.putAll(newTickets);
        });
        print("Generated ${newTickets.length} support tickets for empty entrepreneur profiles!");
      }
    } catch (e) {
      print("Error seeding supplier and support data: $e");
    }
  }
}
