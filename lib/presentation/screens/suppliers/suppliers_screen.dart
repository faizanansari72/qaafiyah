import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../providers/providers.dart';
import '../../../domain/models/domain_models.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(suppliersProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final filteredSuppliers = suppliers.where((s) {
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('SUPPLIER DIRECTORY'),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.darkPrimaryGold),
                  hintText: "Search supplier name or category...",
                  fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                ),
              ),
            ),

            // Suppliers List
            Expanded(
              child: filteredSuppliers.isEmpty
                  ? const Center(child: Text("No suppliers found."))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredSuppliers.length,
                      itemBuilder: (context, index) {
                        final supp = filteredSuppliers[index];
                        final isActive = supp.status == 'Active';

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
                                          'assets/images/supplier_placeholder.jpg',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.business_rounded),
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
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  supp.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: (isActive ? AppTheme.colorSuccess : AppTheme.colorError).withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  supp.status.toUpperCase(),
                                                  style: TextStyle(
                                                    color: isActive ? AppTheme.colorSuccess : AppTheme.colorError,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Sector: ${supp.category} • Contact: ${supp.contactPerson}',
                                            style: TextStyle(
                                              fontSize: 11,
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
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildScorecardStat("Rating", "${supp.rating} ⭐"),
                                    _buildScorecardStat("Lead Time", "${supp.leadTime} Days"),
                                    _buildScorecardStat("Reliability", "${supp.reliabilityScore}%"),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        ref.read(suppliersProvider.notifier).delete(supp.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Supplier successfully deleted.')),
                                        );
                                      },
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
                                      label: const Text('DELETE', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _showEditSupplierDialog(context, supp, isDark),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard,
                                        foregroundColor: isDark ? Colors.white : Colors.black,
                                        side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                                      ),
                                      child: const Text('EDIT RECORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
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
        onPressed: () => _showCreateSupplierDialog(context, isDark),
        backgroundColor: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
        foregroundColor: isDark ? AppTheme.darkBackground : Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildScorecardStat(String label, String val) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  void _showCreateSupplierDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final categoryController = TextEditingController();
    final leadController = TextEditingController();
    final ratingController = TextEditingController();
    final relController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Register New Supplier'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Supplier Name')),
                const SizedBox(height: 8),
                TextField(controller: contactController, decoration: const InputDecoration(labelText: 'Contact Person')),
                const SizedBox(height: 8),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Sector/Category')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: leadController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Avg Lead Time (Days)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: ratingController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial Rating (1-5)'))),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: relController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reliability Index (0-100)')),
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
                final lead = int.tryParse(leadController.text) ?? 5;
                final rating = double.tryParse(ratingController.text) ?? 4.0;
                final rel = int.tryParse(relController.text) ?? 85;

                final newSupplier = Supplier(
                  id: 'S${200 + DateTime.now().millisecond}',
                  name: nameController.text,
                  contactPerson: contactController.text,
                  email: 'contact@${nameController.text.toLowerCase().replaceAll(' ', '')}.com',
                  phone: '+91 97700 00000',
                  rating: rating,
                  leadTime: lead,
                  status: 'Active',
                  category: categoryController.text,
                  reliabilityScore: rel,
                );

                ref.read(suppliersProvider.notifier).save(newSupplier);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Registered supplier node: ${newSupplier.name}')),
                );
              },
              child: const Text('REGISTER'),
            ),
          ],
        );
      },
    );
  }

  void _showEditSupplierDialog(BuildContext context, Supplier supp, bool isDark) {
    final nameController = TextEditingController(text: supp.name);
    final contactController = TextEditingController(text: supp.contactPerson);
    final leadController = TextEditingController(text: '${supp.leadTime}');
    final relController = TextEditingController(text: '${supp.reliabilityScore}');
    String status = supp.status;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Record: ${supp.id}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Supplier Name')),
                    const SizedBox(height: 8),
                    TextField(controller: contactController, decoration: const InputDecoration(labelText: 'Contact Person')),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: leadController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Avg Lead Time'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: relController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reliability Index'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      value: status,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Active', child: Text('Active')),
                        DropdownMenuItem(value: 'Suspended', child: Text('Suspended')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            status = val;
                          });
                        }
                      },
                    )
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
                    final lead = int.tryParse(leadController.text) ?? supp.leadTime;
                    final rel = int.tryParse(relController.text) ?? supp.reliabilityScore;

                    final updated = supp.copyWith(
                      name: nameController.text,
                      contactPerson: contactController.text,
                      leadTime: lead,
                      reliabilityScore: rel,
                      status: status,
                    );

                    ref.read(suppliersProvider.notifier).save(updated);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Supplier record updated successfully.')),
                    );
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
