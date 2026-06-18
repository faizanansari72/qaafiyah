import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../providers/providers.dart';
import '../../../domain/models/domain_models.dart';

class WarehousesScreen extends ConsumerStatefulWidget {
  const WarehousesScreen({super.key});

  @override
  ConsumerState<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends ConsumerState<WarehousesScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final warehouses = ref.watch(warehousesProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final filteredWarehouses = warehouses.where((w) {
      return w.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          w.location.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('WAREHOUSE CONSOLE'),
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
                  hintText: "Search warehouse node name or city...",
                  fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                ),
              ),
            ),

            // Alerts Panel: Any warehouse > 85% capacity gets flagged
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: warehouses.where((w) {
                  final pct = w.capacity > 0 ? (w.usedCapacity / w.capacity) * 100 : 0;
                  return pct > 85;
                }).map((w) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.colorError.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.colorError.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppTheme.colorError, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ALERT: ${w.name} is near capacity (${((w.usedCapacity / w.capacity) * 100).round()}%). Re-route freight dispatches.',
                            style: const TextStyle(color: AppTheme.colorError, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Warehouses List
            Expanded(
              child: filteredWarehouses.isEmpty
                  ? const Center(child: Text("No warehouse nodes registered."))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredWarehouses.length,
                      itemBuilder: (context, index) {
                        final w = filteredWarehouses[index];
                        final capacityPct = w.capacity > 0 ? (w.usedCapacity / w.capacity) * 100 : 0.0;
                        final isCritical = capacityPct > 85;
                        final isMaint = w.status == 'Maintenance';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        w.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isMaint ? AppTheme.colorWarning : AppTheme.colorSuccess).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        w.status.toUpperCase(),
                                        style: TextStyle(
                                          color: isMaint ? AppTheme.colorWarning : AppTheme.colorSuccess,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Location: ${w.location} • Manager: ${w.managerName}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  ),
                                ),
                                const Divider(height: 20),
                                
                                // Capacity Usage progress
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Capacity: ${w.usedCapacity} / ${w.capacity} Units',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '${capacityPct.round()}% Used',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isCritical ? AppTheme.colorError : AppTheme.darkPrimaryGold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: capacityPct / 100,
                                    minHeight: 6,
                                    backgroundColor: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isCritical ? AppTheme.colorError : AppTheme.darkPrimaryGold,
                                    ),
                                  ),
                                ),
                                const Divider(height: 24),
                                
                                // Operations Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        ref.read(warehousesProvider.notifier).delete(w.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Warehouse successfully deleted.')),
                                        );
                                      },
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
                                      label: const Text('DELETE', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _showEditWarehouseDialog(context, w, isDark),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard,
                                        foregroundColor: isDark ? Colors.white : Colors.black,
                                        side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                                      ),
                                      child: const Text('EDIT RECORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    )
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
        onPressed: () => _showCreateWarehouseDialog(context, isDark),
        backgroundColor: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
        foregroundColor: isDark ? AppTheme.darkBackground : Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showCreateWarehouseDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final locController = TextEditingController();
    final capController = TextEditingController();
    final usedController = TextEditingController();
    final managerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Register Warehouse Node'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Warehouse Name')),
                const SizedBox(height: 8),
                TextField(controller: locController, decoration: const InputDecoration(labelText: 'Location/City')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: capController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Capacity'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: usedController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Used Capacity'))),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: managerController, decoration: const InputDecoration(labelText: 'Manager Name')),
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
                final cap = int.tryParse(capController.text) ?? 5000;
                final used = int.tryParse(usedController.text) ?? 0;

                final newWarehouse = Warehouse(
                  id: 'W${100 + DateTime.now().millisecond}',
                  name: nameController.text,
                  location: locController.text,
                  capacity: cap,
                  usedCapacity: used,
                  status: 'Active',
                  managerName: managerController.text,
                  contactPhone: '+91 99887 00000',
                );

                ref.read(warehousesProvider.notifier).save(newWarehouse);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Registered warehouse node: ${newWarehouse.name}')),
                );
              },
              child: const Text('REGISTER'),
            ),
          ],
        );
      },
    );
  }

  void _showEditWarehouseDialog(BuildContext context, Warehouse w, bool isDark) {
    final nameController = TextEditingController(text: w.name);
    final locController = TextEditingController(text: w.location);
    final capController = TextEditingController(text: '${w.capacity}');
    final usedController = TextEditingController(text: '${w.usedCapacity}');
    final managerController = TextEditingController(text: w.managerName);
    String status = w.status;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Record: ${w.id}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Warehouse Name')),
                    const SizedBox(height: 8),
                    TextField(controller: locController, decoration: const InputDecoration(labelText: 'Location/City')),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: capController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Capacity'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: usedController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Used Capacity'))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: managerController, decoration: const InputDecoration(labelText: 'Manager Name')),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      value: status,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Active', child: Text('Active')),
                        DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
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
                    final cap = int.tryParse(capController.text) ?? w.capacity;
                    final used = int.tryParse(usedController.text) ?? w.usedCapacity;

                    final updated = w.copyWith(
                      name: nameController.text,
                      location: locController.text,
                      capacity: cap,
                      usedCapacity: used,
                      managerName: managerController.text,
                      status: status,
                    );

                    ref.read(warehousesProvider.notifier).save(updated);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Warehouse node details updated.')),
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
