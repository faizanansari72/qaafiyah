import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/premium_dialog.dart';
import '../../providers/providers.dart';
import '../../../domain/models/domain_models.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _searchQuery = "";
  String _selectedCategory = "All";

  final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Categories list dynamically fetched
    final categories = ["All", ...products.map((p) => p.category).toSet().toList()];

    // Filtering
    final filteredProducts = products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == "All" || p.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('PRODUCT CATALOG'),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Category Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.darkPrimaryGold),
                      hintText: "Search name or SKU code...",
                      fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Categories chips row
                  SizedBox(
                    height: 32,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final active = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: active
                                  ? (isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold)
                                  : (isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                                width: 0.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: active
                                      ? (isDark ? AppTheme.darkBackground : Colors.white)
                                      : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),

            // Products Grid
            Expanded(
              child: filteredProducts.isEmpty
                  ? const Center(child: Text("No products found in catalog."))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final prod = filteredProducts[index];
                        final isLowStock = prod.inventoryCount < 50;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        color: isDark ? Colors.black26 : Colors.black12,
                                        child: Image.asset(
                                          'assets/images/product_placeholder.jpg',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag_outlined),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  prod.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.darkPrimaryGold.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${prod.profitMargin}% MARGIN',
                                                  style: const TextStyle(
                                                    color: AppTheme.darkPrimaryGold,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'SKU: ${prod.sku} • Sector: ${prod.category}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  children: [
                                    _buildPriceBlock("Cost Price", formatter.format(prod.costPrice), isDark),
                                    const SizedBox(width: 20),
                                    _buildPriceBlock("Selling Price", formatter.format(prod.sellingPrice), isDark),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${prod.inventoryCount} units',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isLowStock ? AppTheme.colorError : AppTheme.colorSuccess,
                                          ),
                                        ),
                                        Text(
                                          isLowStock ? 'Low Stock Alert' : 'Stock Level Normal',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: isLowStock ? AppTheme.colorError : AppTheme.colorSuccess,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        PremiumDialog.show(
                                          context: context,
                                          title: "Delete Product?",
                                          icon: Icons.delete_forever_rounded,
                                          iconColor: AppTheme.colorError,
                                          content: Text(
                                            "Are you sure you want to permanently delete the product '${prod.name}' from your catalog?",
                                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('CANCEL'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colorError),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                ref.read(productsProvider.notifier).delete(prod.id);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Product deleted successfully.')),
                                                );
                                              },
                                              child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                            ),
                                          ],
                                        );
                                      },
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
                                      label: const Text('DELETE', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _showEditProductDialog(context, prod, isDark),
                                      icon: const Icon(Icons.edit_rounded, size: 14),
                                      label: const Text('EDIT CATALOG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard,
                                        foregroundColor: isDark ? Colors.white : Colors.black,
                                        side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProductDialog(context, isDark),
        backgroundColor: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
        foregroundColor: isDark ? AppTheme.darkBackground : Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildPriceBlock(String title, String val, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  void _showCreateProductDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final catController = TextEditingController();
    final costController = TextEditingController();
    final sellController = TextEditingController();
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Product to Catalog'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
                const SizedBox(height: 8),
                TextField(controller: skuController, decoration: const InputDecoration(labelText: 'SKU (e.g. QFY-SILK-100)')),
                const SizedBox(height: 8),
                TextField(controller: catController, decoration: const InputDecoration(labelText: 'Category/Sector')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: costController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost Price'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: sellController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Selling Price'))),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Opening Stock')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final cost = int.tryParse(costController.text) ?? 0;
                final sell = int.tryParse(sellController.text) ?? 0;
                final qty = int.tryParse(qtyController.text) ?? 0;
                final margin = sell > 0 ? (((sell - cost) / sell) * 100).round() : 0;
                
                final newProd = Product(
                  id: 'P${100 + DateTime.now().millisecond}',
                  name: nameController.text,
                  sku: skuController.text,
                  category: catController.text,
                  costPrice: cost,
                  sellingPrice: sell,
                  profitMargin: margin,
                  inventoryCount: qty,
                  supplierId: 'S200',
                  warehouseId: 'W101',
                );

                ref.read(productsProvider.notifier).save(newProd);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${newProd.name} added to catalog!')),
                );
              },
              child: const Text('SUBMIT'),
            ),
          ],
        );
      },
    );
  }

  void _showEditProductDialog(BuildContext context, Product prod, bool isDark) {
    final nameController = TextEditingController(text: prod.name);
    final costController = TextEditingController(text: '${prod.costPrice}');
    final sellController = TextEditingController(text: '${prod.sellingPrice}');
    final qtyController = TextEditingController(text: '${prod.inventoryCount}');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Catalog: ${prod.sku}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: costController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost Price'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: sellController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Selling Price'))),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Count')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final cost = int.tryParse(costController.text) ?? prod.costPrice;
                final sell = int.tryParse(sellController.text) ?? prod.sellingPrice;
                final qty = int.tryParse(qtyController.text) ?? prod.inventoryCount;
                final margin = sell > 0 ? (((sell - cost) / sell) * 100).round() : 0;
                
                final updated = prod.copyWith(
                  name: nameController.text,
                  costPrice: cost,
                  sellingPrice: sell,
                  profitMargin: margin,
                  inventoryCount: qty,
                );

                ref.read(productsProvider.notifier).save(updated);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Product catalog updated!')),
                );
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }
}
