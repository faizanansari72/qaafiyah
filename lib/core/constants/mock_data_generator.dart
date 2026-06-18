import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  final random = Random(42); // Seeded for reproducibility
  final assetsDir = Directory('assets/json');
  if (!assetsDir.existsSync()) {
    assetsDir.createSync(recursive: true);
  }

  print('Generating mock data...');

  // 1. Generate 30 Entrepreneurs
  final entrepreneurs = List.generate(30, (index) {
    final id = 'E${1000 + index}';
    final firstNames = ['Aarav', 'Vihaan', 'Aditya', 'Ishaan', 'Kabir', 'Sai', 'Ananya', 'Diya', 'Meera', 'Riya', 'Karan', 'Rahul', 'Neha', 'Rohan', 'Amit', 'Priya', 'Sanjay', 'Vikram', 'Divya', 'Nisha', 'Vijay', 'Arjun', 'Sneha', 'Pooja', 'Sunil', 'Kiran', 'Rajesh', 'Anil', 'Geetha', 'Harish'];
    final lastNames = ['Sharma', 'Verma', 'Gupta', 'Mehra', 'Joshi', 'Patel', 'Reddy', 'Nair', 'Iyer', 'Sen', 'Das', 'Roy', 'Singh', 'Choudhury', 'Rao', 'Bose', 'Mishra', 'Trivedi', 'Pandey', 'Saxena', 'Kapoor', 'Malhotra', 'Khanna', 'Bahl', 'Suri', 'Chopra', 'Johar', 'Nanda', 'Prasad', 'Menon'];
    final name = '${firstNames[index % firstNames.length]} ${lastNames[index % lastNames.length]}';
    final businessNames = [
      'Kora Couture', 'Zari Silks', 'Indus Brews', 'Himalayan Organics', 'Soma Botanicals',
      'Vedic Wellness', 'Nile Leather', 'Opal Jewels', 'Clay & Co', 'Jaipur Loom',
      'Spice Root', 'Dune Threads', 'Aura Lighting', 'Amber Crafts', 'Rasa Foods',
      'Mitti Kitchen', 'Mantra Spaces', 'Karma Living', 'Jiva Tea', 'Rooh Fragrances',
      'Vriksh Farms', 'Eka Designs', 'Sutra Home', 'Sanskriti Art', 'Nilgiri Blends',
      'Kailash Goods', 'Mithai Box', 'Ananda Spas', 'Saffron Trail', 'Tantra Active'
    ];
    final businessName = businessNames[index % businessNames.length];
    
    // Scores
    final growthScore = 75 + random.nextInt(23);
    final profitabilityScore = 70 + random.nextInt(28);
    final fulfillmentScore = 80 + random.nextInt(18);
    final supplierScore = 75 + random.nextInt(23);
    final deliveryScore = 82 + random.nextInt(16);
    final operationsScore = 78 + random.nextInt(20);
    
    final eliteScore = ((growthScore + profitabilityScore + fulfillmentScore + supplierScore + deliveryScore + operationsScore) / 6).round();

    return {
      'id': id,
      'name': name,
      'businessName': businessName,
      'email': '${name.toLowerCase().replaceAll(' ', '.')}@qaafiya.one',
      'phone': '+91 98765 ${10000 + index}',
      'avatar': 'https://api.dicebear.com/7.x/adventurer/svg?seed=$id',
      'eliteScore': eliteScore,
      'growthScore': growthScore,
      'profitabilityScore': profitabilityScore,
      'fulfillmentScore': fulfillmentScore,
      'supplierScore': supplierScore,
      'deliveryScore': deliveryScore,
      'operationsScore': operationsScore,
      'rank': 0, // Will rank later
      'isApproved': index < 25, // First 25 are active/approved, remaining 5 are pending
      'createdAt': DateTime.now().subtract(Duration(days: 30 + index * 5)).toIso8601String(),
    };
  });

  // Rank entrepreneurs by eliteScore
  entrepreneurs.sort((a, b) => (b['eliteScore'] as int).compareTo(a['eliteScore'] as int));
  for (int i = 0; i < entrepreneurs.length; i++) {
    entrepreneurs[i]['rank'] = i + 1;
  }

  // 2. Generate 5 Warehouses
  final warehouses = [
    {'id': 'W101', 'name': 'Delhi NCR Fulfillment Hub', 'location': 'Gurugram, Haryana', 'capacity': 10000, 'usedCapacity': 7200, 'status': 'Active', 'managerName': 'Rajesh Kumar', 'contactPhone': '+91 99887 76655'},
    {'id': 'W102', 'name': 'Mumbai Port Gateway Warehouse', 'location': 'Bhiwandi, Maharashtra', 'capacity': 15000, 'usedCapacity': 12400, 'status': 'Active', 'managerName': 'Sunil Patil', 'contactPhone': '+91 98765 43210'},
    {'id': 'W103', 'name': 'South India Logistics Center', 'location': 'Whitefield, Bengaluru', 'capacity': 8000, 'usedCapacity': 3100, 'status': 'Active', 'managerName': 'Ramesh Naidu', 'contactPhone': '+91 91234 56789'},
    {'id': 'W104', 'name': 'East India Distribution Node', 'location': 'Howrah, West Bengal', 'capacity': 6000, 'usedCapacity': 5400, 'status': 'Active', 'managerName': 'Amit Sen', 'contactPhone': '+91 90011 22334'},
    {'id': 'W105', 'name': 'West India Storage Hub', 'location': 'Ahmedabad, Gujarat', 'capacity': 5000, 'usedCapacity': 1200, 'status': 'Maintenance', 'managerName': 'Hardik Shah', 'contactPhone': '+91 88776 65544'}
  ];

  // 3. Generate 20 Suppliers
  final categories = ['Apparel & Fabrics', 'Gourmet Food & Teas', 'Organic Cosmetics', 'Premium Leather', 'Home Decor & Arts', 'Wellness & Herbal'];
  final suppliers = List.generate(20, (index) {
    final id = 'S${200 + index}';
    final supplierNames = [
      'Jaipur Blockprints Ltd', 'Darjeeling Gold Estates', 'Kashmir Pashmina Handlooms', 'Kerala Herbals Co',
      'Agra Leather Crafts', 'Mitti Terracotta Studio', 'Varanasi Weaves', 'Himalayan Shilajit Corp',
      'Assam Leaf & Bud', 'Rajasthan Stonecrafts', 'Malabar Spices Co', 'Coorg Coffee Growers',
      'Sanganer Dyeing House', 'Kora Khadi Cooperative', 'Ganga Clay Artisans', 'Deccan Organic Oils',
      'Khadi Silk Weavers', 'Nilgiri Herbs', 'Kutch Embroidery Collective', 'Moradabad Brassworks'
    ];
    final contacts = ['Ankit Sharma', 'Joydeep Sen', 'Muzamil Dar', 'Kiran Nair', 'Vikas Gupta', 'Arun Prajapati', 'Prem Mishra', 'Dorje Tashi', 'Barua Baruah', 'Devendra Singh', 'Mathew Abraham', 'Boppanna Appiah', 'Lalit Chippa', 'Jagdish Bhai', 'Gopal Das', 'Shailesh Reddy', 'Ramakant Dev', 'Leela Mani', 'Khimji Bhai', 'Suresh Rastogi'];
    
    final category = categories[index % categories.length];
    final rating = 3.8 + random.nextDouble() * 1.2;
    final leadTime = 3 + random.nextInt(12); // 3 to 14 days
    final status = random.nextDouble() > 0.15 ? 'Active' : 'Suspended';
    final reliabilityScore = 70 + random.nextInt(30);

    return {
      'id': id,
      'name': supplierNames[index % supplierNames.length],
      'contactPerson': contacts[index % contacts.length],
      'email': 'contact@${supplierNames[index % supplierNames.length].toLowerCase().replaceAll(' ', '')}.com',
      'phone': '+91 97766 ${20000 + index}',
      'rating': double.parse(rating.toStringAsFixed(1)),
      'leadTime': leadTime,
      'status': status,
      'category': category,
      'reliabilityScore': reliabilityScore,
    };
  });

  // 4. Generate 50 Products
  final products = List.generate(50, (index) {
    final id = 'P${100 + index}';
    final productNames = [
      'Royal Silk Banarasi Saree', 'Kashmiri Walnut Wood Bowl', 'Organic Darjeeling First Flush Tea', 'Premium Vegan Leather Satchel',
      'Natural Sandalwood Essential Oil', 'Handmade Terracotta Planter Set', 'Jaipuri Indigo Blockprint Kurta', 'Pure Shilajit Resin Extra Strength',
      'Single Estate Assam Black Tea', 'Agra White Marble Coasters', 'Malabar Organic Black Pepper', 'Coorg Roast Coffee Beans',
      'Sanganeri Cotton Bedsheet', 'Organic Hemp Seed Oil', 'Handcrafted Ceramic Dinner Set', 'Rosewater Hydrosol Toner',
      'Khadi Handspun Cotton Shirt', 'Nilgiri Eucalyptus Balm', 'Kutchi Mirror Work Cushion Cover', 'Moradabad Engraved Brass Vase',
      'Premium Saffron Filament (A++)', 'Raw Unfiltered Forest Honey', 'Cardamom Infused Green Tea', 'Full Grain Leather Notebook',
      'Vedic Neem Cleansing Bar', 'Terracotta Serving Handi', 'Bhagalpur Tussar Silk Shawl', 'Ayurvedic Kumkumadi Tailam',
      'Masala Chai CTC Premium', 'Carved Soapstone Incense Holder', 'Organic Turmeric Powder High Curcumin', 'Coorg Vanilla Beans',
      'Blockprint Cotton Table Runner', 'Cold Pressed Coconut Oil', 'Blue Pottery Serving Plate', 'Jasmine Flower Water',
      'Handloom Linen Trousers', 'Herbal Pain Relief Oil', 'Embroidered Leather Mojaris', 'Brass Diya Stand Tiered',
      'Kashmiri Kesar Kahwa Pack', 'Organic Amla Juice Concentrate', 'Tulsi Ginger Herbal Tea', 'Premium Suede Leather Pouch',
      'Handcrafted Sandalwood Soap', 'Mitti Clay Water Jug', 'Chanderi Silk Dupatta', 'Pure Aloe Vera Skin Gel',
      'English Breakfast Tea Blend', 'Inlaid Wooden Jewelry Box'
    ];
    final name = productNames[index % productNames.length];
    
    final supplierId = suppliers[random.nextInt(suppliers.length)]['id'];
    
    // Pricing
    final costPrice = 150 + random.nextInt(1850);
    // Margins usually 30% to 150% markup
    final markupPercent = 0.4 + random.nextDouble() * 1.1; // 40% to 150% markup
    final sellingPrice = (costPrice * (1 + markupPercent)).round();
    final profitMargin = (((sellingPrice - costPrice) / sellingPrice) * 100).round();
    final inventoryCount = 10 + random.nextInt(490);

    return {
      'id': id,
      'name': name,
      'sku': 'QFY-${name.substring(0, 3).toUpperCase()}-${100 + index}',
      'category': categories[index % categories.length],
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'profitMargin': profitMargin,
      'inventoryCount': inventoryCount,
      'supplierId': supplierId,
      'warehouseId': warehouses[random.nextInt(warehouses.length)]['id'],
    };
  });

  // 5. Generate 100 Orders
  final listStates = ['Delhi', 'Maharashtra', 'Karnataka', 'West Bengal', 'Gujarat', 'Tamil Nadu', 'Telangana', 'Uttar Pradesh', 'Rajasthan', 'Haryana'];
  final listCities = ['New Delhi', 'Mumbai', 'Bengaluru', 'Kolkata', 'Ahmedabad', 'Chennai', 'Hyderabad', 'Noida', 'Jaipur', 'Gurugram'];
  final listCourierPartners = ['Delhivery Premium', 'BlueDart Apex', 'Shadowfax Priority', 'Xpressbees Express'];
  
  final orders = List.generate(100, (index) {
    final id = 'O${5000 + index}';
    final orderNumber = 'QA-2026-${10000 + index}';
    
    // Pick entrepreneur
    final entre = entrepreneurs[random.nextInt(entrepreneurs.length)];
    final entrepreneurId = entre['id'];
    
    // Pick products
    final numberOfItems = 1 + random.nextInt(3);
    final orderItems = <Map<String, dynamic>>[];
    int totalAmount = 0;
    
    for (int i = 0; i < numberOfItems; i++) {
      final prod = products[random.nextInt(products.length)];
      final qty = 1 + random.nextInt(2);
      final price = prod['sellingPrice'] as int;
      orderItems.add({
        'productId': prod['id'],
        'productName': prod['name'],
        'quantity': qty,
        'price': price,
      });
      totalAmount += price * qty;
    }
    
    // Details
    final custFirstNames = ['Raj', 'Amit', 'Sunil', 'Preeti', 'Sonia', 'Rohan', 'Neelam', 'Vikram', 'Deepak', 'Geeta', 'Sanjay', 'Pooja', 'Ramesh', 'Harish', 'Manju', 'Savita', 'Abhishek', 'Shweta', 'Kunal', 'Jyoti'];
    final custLastNames = ['Sharma', 'Varma', 'Gupta', 'Singh', 'Chawla', 'Mehta', 'Nair', 'Kumar', 'Reddy', 'Patel', 'Das', 'Sen', 'Banerjee', 'Rao', 'Bose', 'Mishra', 'Trivedi', 'Joshi', 'Aggarwal', 'Dutta'];
    final customerName = '${custFirstNames[random.nextInt(custFirstNames.length)]} ${custLastNames[random.nextInt(custLastNames.length)]}';
    
    final stateIndex = random.nextInt(listStates.length);
    final state = listStates[stateIndex];
    final city = listCities[stateIndex];
    final pincode = '${110000 + random.nextInt(780000)}';
    
    // Order Statuses & Transitions
    // Order of statuses: Pending, Processing, Packed, Shipped, Delivered, Returned, RTO
    final statusRand = random.nextDouble();
    String status = 'Delivered';
    if (statusRand < 0.05) {
      status = 'Pending';
    } else if (statusRand < 0.15) {
      status = 'Processing';
    } else if (statusRand < 0.20) {
      status = 'Packed';
    } else if (statusRand < 0.35) {
      status = 'Shipped';
    } else if (statusRand < 0.85) {
      status = 'Delivered';
    } else if (statusRand < 0.92) {
      status = 'Returned';
    } else {
      status = 'RTO';
    }

    final paymentMethod = random.nextDouble() > 0.4 ? 'COD' : 'Pre-paid';
    
    // COD state transitions: Pending, Collected, Settled
    String paymentStatus = 'Paid';
    if (paymentMethod == 'COD') {
      if (status == 'Delivered') {
        paymentStatus = random.nextDouble() > 0.5 ? 'Settled' : 'Collected';
      } else if (status == 'Returned' || status == 'RTO') {
        paymentStatus = 'Cancelled';
      } else {
        paymentStatus = 'Pending';
      }
    } else {
      paymentStatus = 'Paid'; // Prepaid is paid immediately
    }

    // Created dates over the last 6 months (Jan to Jun 2026)
    final dateDiffDays = random.nextInt(180);
    final createdAt = DateTime.now().subtract(Duration(days: dateDiffDays, hours: random.nextInt(24), minutes: random.nextInt(60)));
    
    // Shipment Courier details
    final courierPartner = listCourierPartners[random.nextInt(listCourierPartners.length)];
    final trackingNumber = 'QFY${random.nextInt(9000000) + 1000000}IN';
    
    // Generate shipment timeline based on status
    final timeline = <Map<String, String>>[];
    timeline.add({
      'status': 'Pending',
      'title': 'Order Confirmed',
      'description': 'Order has been placed by customer via ${entre['businessName']}.',
      'timestamp': createdAt.toIso8601String(),
    });
    
    if (status != 'Pending') {
      final processingTime = createdAt.add(Duration(hours: 6 + random.nextInt(18)));
      timeline.add({
        'status': 'Processing',
        'title': 'Order Processing',
        'description': 'Order inventory verified and allocated at warehouse.',
        'timestamp': processingTime.toIso8601String(),
      });
      
      if (status != 'Processing') {
        final packedTime = processingTime.add(Duration(hours: 4 + random.nextInt(12)));
        timeline.add({
          'status': 'Packed',
          'title': 'Packed & Dispatched',
          'description': 'Order packaged securely and handed over to $courierPartner.',
          'timestamp': packedTime.toIso8601String(),
        });
        
        if (status != 'Packed') {
          final shippedTime = packedTime.add(Duration(hours: 12 + random.nextInt(24)));
          timeline.add({
            'status': 'Shipped',
            'title': 'Shipped out of Hub',
            'description': 'Package in transit. Air waybill ($trackingNumber) active.',
            'timestamp': shippedTime.toIso8601String(),
          });
          
          if (status == 'Delivered') {
            final deliveredTime = shippedTime.add(Duration(days: 1 + random.nextInt(3)));
            timeline.add({
              'status': 'Delivered',
              'title': 'Delivered Successfully',
              'description': 'Delivered to recipient. Signature verified.',
              'timestamp': deliveredTime.toIso8601String(),
            });
          } else if (status == 'Returned') {
            final deliveredTime = shippedTime.add(Duration(days: 2));
            final returnedTime = deliveredTime.add(Duration(days: 1 + random.nextInt(2)));
            timeline.add({
              'status': 'Delivered',
              'title': 'Delivered Successfully',
              'description': 'Delivered to recipient.',
              'timestamp': deliveredTime.toIso8601String(),
            });
            timeline.add({
              'status': 'Returned',
              'title': 'Return Initiated & Received',
              'description': 'Customer requested return. Product returned to warehouse.',
              'timestamp': returnedTime.toIso8601String(),
            });
          } else if (status == 'RTO') {
            final rtoTime = shippedTime.add(Duration(days: 2 + random.nextInt(2)));
            timeline.add({
              'status': 'RTO',
              'title': 'RTO (Returned to Origin)',
              'description': 'Delivery attempted 3 times. Customer unavailable. Returning to warehouse.',
              'timestamp': rtoTime.toIso8601String(),
            });
          }
        }
      }
    }

    return {
      'id': id,
      'orderNumber': orderNumber,
      'entrepreneurId': entrepreneurId,
      'businessName': entre['businessName'],
      'customerName': customerName,
      'customerEmail': '${customerName.toLowerCase().replaceAll(' ', '')}@gmail.com',
      'customerPhone': '+91 91100 ${10000 + index}',
      'shippingAddress': '${10 + random.nextInt(900)}, Park Avenue, Behind Landmark Hotel',
      'city': city,
      'state': state,
      'pincode': pincode,
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'createdAt': createdAt.toIso8601String(),
      'items': orderItems,
      'courierPartner': courierPartner,
      'trackingNumber': trackingNumber,
      'shipmentTimeline': timeline,
    };
  });

  // 6. Generate 6 Months Revenue Analytics (Jan to Jun 2026)
  final months = ['Jan 2026', 'Feb 2026', 'Mar 2026', 'Apr 2026', 'May 2026', 'Jun 2026'];
  final revenueAnalytics = List.generate(6, (index) {
    // Steadily increasing revenue trend to simulate growth
    final baseRevenue = 850000 + index * 180000 + random.nextInt(100000);
    final costOfGoods = (baseRevenue * 0.42).round();
    final operatingExpenses = (baseRevenue * 0.18).round();
    final marketingCosts = (baseRevenue * 0.15).round();
    final profit = baseRevenue - costOfGoods - operatingExpenses - marketingCosts;
    final profitMargin = ((profit / baseRevenue) * 100).round();
    
    // Order stats
    final ordersCount = 350 + index * 80 + random.nextInt(50);
    final codCount = (ordersCount * 0.65).round();
    final prepaidCount = ordersCount - codCount;

    return {
      'month': months[index],
      'revenue': baseRevenue,
      'costOfGoods': costOfGoods,
      'expenses': operatingExpenses + marketingCosts,
      'netProfit': profit,
      'profitMargin': profitMargin,
      'ordersCount': ordersCount,
      'codOrders': codCount,
      'prepaidOrders': prepaidCount,
    };
  });

  // 7. COD Settlement History
  final codHistory = List.generate(15, (index) {
    final amount = 75000 + random.nextInt(150000);
    final date = DateTime.now().subtract(Duration(days: index * 7 + 2));
    final status = index == 0 ? 'Pending' : (index == 1 ? 'Processing' : 'Settled');
    return {
      'id': 'COD-SET-${100 + index}',
      'settlementCycle': 'Cycle #${40 + index}',
      'periodStart': date.subtract(Duration(days: 7)).toIso8601String(),
      'periodEnd': date.toIso8601String(),
      'amount': amount,
      'ordersCount': 25 + random.nextInt(35),
      'status': status,
      'bankReference': status == 'Settled' ? 'TXN-${998877 + index}AXB' : 'N/A',
      'settledAt': status == 'Settled' ? date.add(Duration(days: 2)).toIso8601String() : 'N/A',
    };
  });

  // 8. Community Posts
  final communityPosts = [
    {
      'id': 'P-COM-1',
      'authorName': 'Aarav Sharma',
      'authorBusiness': 'Kora Couture',
      'authorAvatar': 'https://api.dicebear.com/7.x/adventurer/svg?seed=E1000',
      'title': 'Scaling beyond ₹15L MRR: Our Supply Chain Breakthrough!',
      'content': 'We recently solved our bottleneck with Varanasi silk fabric suppliers. By securing a 3-month rolling contract, we stabilized cost prices by 12% and improved profit margins to 58%. Highly recommend other premium apparel founders to lock in supplier terms early.',
      'likes': 42,
      'comments': 12,
      'createdAt': DateTime.now().subtract(Duration(hours: 4)).toIso8601String(),
    },
    {
      'id': 'P-COM-2',
      'authorName': 'Meera Joshi',
      'authorBusiness': 'Soma Botanicals',
      'authorAvatar': 'https://api.dicebear.com/7.x/adventurer/svg?seed=E1004',
      'title': 'Ramp up before the Festive Rush! 🎁',
      'content': 'For the upcoming festive season, we are seeing a 2x demand surge. Just secured extra capacity at the Delhi NCR Hub. Quick tip: leverage the Qaafiya Logistics courier dashboard to switch to BlueDart Apex for high-ticket gifting orders to lower RTO from 12% to 4%.',
      'likes': 28,
      'comments': 5,
      'createdAt': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
    },
    {
      'id': 'P-COM-3',
      'authorName': 'Rahul Patel',
      'authorBusiness': 'Vedic Wellness',
      'authorAvatar': 'https://api.dicebear.com/7.x/adventurer/svg?seed=E1005',
      'title': 'Navigating COD Settlement Cycles',
      'content': 'Has anyone noticed the improved COD settlement speeds? Qaafiya team just cut down settlement wait times to 2 days! This has boosted our cash flow by 30%, allowing us to re-invest in Meta ads instantly. Kudos to the logistics and finance squads.',
      'likes': 35,
      'comments': 8,
      'createdAt': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
    }
  ];

  // 9. Support Tickets
  final supportTickets = [
    {
      'id': 'T-801',
      'entrepreneurId': 'E1000',
      'businessName': 'Kora Couture',
      'title': 'Custom Box Packaging Integration at Whitefield Warehouse',
      'description': 'We would like to send our custom branded magnetic lock boxes to Whitefield Warehouse. Needs approval for custom packing workflow.',
      'category': 'Warehouse Operations',
      'priority': 'Medium',
      'status': 'Open',
      'createdAt': DateTime.now().subtract(Duration(hours: 18)).toIso8601String(),
    },
    {
      'id': 'T-802',
      'entrepreneurId': 'E1002',
      'businessName': 'Indus Brews',
      'title': 'RTO Dispute: Order #QA-2026-10042',
      'description': 'Courier partner marked the parcel as customer rejected, but our customer confirms they never received a delivery call. Requesting NDR check.',
      'category': 'Shipment & NDR',
      'priority': 'High',
      'status': 'In-Progress',
      'createdAt': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
    },
    {
      'id': 'T-803',
      'entrepreneurId': 'E1005',
      'businessName': 'Vedic Wellness',
      'title': 'COD Settlement Discrepancy Cycle #42',
      'description': 'Amount settled is short by ₹4,800. Looks like one delivered order was missed in the calculations. Details attached.',
      'category': 'COD Finance',
      'priority': 'High',
      'status': 'Resolved',
      'createdAt': DateTime.now().subtract(Duration(days: 4)).toIso8601String(),
    }
  ];

  // 10. Admin Entrepreneur Applications
  final adminApplications = [
    {
      'id': 'APP-001',
      'applicantName': 'Vikram Malhotra',
      'businessName': 'Royal Spices Co.',
      'email': 'vikram@royalspices.in',
      'phone': '+91 99999 11111',
      'annualRevenue': '₹1.2 Crores',
      'category': 'Gourmet Food & Teas',
      'description': 'Premium, organic single-origin spices sourced directly from smallholder farmers in Wayanad and Idukki. Exporting to 5 countries.',
      'status': 'Pending',
      'appliedAt': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
    },
    {
      'id': 'APP-002',
      'applicantName': 'Ananya Sen',
      'businessName': 'Clay & Glow',
      'email': 'ananya@clayglow.com',
      'phone': '+91 98888 22222',
      'annualRevenue': '₹75 Lakhs',
      'category': 'Organic Cosmetics',
      'description': 'Clean beauty luxury brand focused on ancient volcanic mud masks and premium cold-pressed flower serums. Targeting elite cosmetic buyers.',
      'status': 'Approved',
      'appliedAt': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
    },
    {
      'id': 'APP-003',
      'applicantName': 'Kunal Khanna',
      'businessName': 'Khanna Leatherware',
      'email': 'kunal@khannaleather.com',
      'phone': '+91 97777 33333',
      'annualRevenue': '₹3.4 Crores',
      'category': 'Premium Leather',
      'description': 'Vegetable-tanned full-grain leather bags and travel accessories. Custom hardware, life-time guarantee. Seeking premium distribution.',
      'status': 'Rejected',
      'appliedAt': DateTime.now().subtract(Duration(days: 8)).toIso8601String(),
    }
  ];

  // Write files
  File('${assetsDir.path}/entrepreneurs.json').writeAsStringSync(jsonEncode(entrepreneurs));
  File('${assetsDir.path}/warehouses.json').writeAsStringSync(jsonEncode(warehouses));
  File('${assetsDir.path}/suppliers.json').writeAsStringSync(jsonEncode(suppliers));
  File('${assetsDir.path}/products.json').writeAsStringSync(jsonEncode(products));
  File('${assetsDir.path}/orders.json').writeAsStringSync(jsonEncode(orders));
  File('${assetsDir.path}/analytics_revenue.json').writeAsStringSync(jsonEncode(revenueAnalytics));
  File('${assetsDir.path}/cod_history.json').writeAsStringSync(jsonEncode(codHistory));
  File('${assetsDir.path}/community_posts.json').writeAsStringSync(jsonEncode(communityPosts));
  File('${assetsDir.path}/support_tickets.json').writeAsStringSync(jsonEncode(supportTickets));
  File('${assetsDir.path}/admin_applications.json').writeAsStringSync(jsonEncode(adminApplications));

  print('All mock data JSON files generated successfully!');
}
