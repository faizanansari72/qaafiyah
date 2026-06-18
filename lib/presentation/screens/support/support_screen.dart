import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/premium_dialog.dart';
import '../../providers/providers.dart';
import '../../../domain/models/domain_models.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeEntre = ref.watch(currentEntrepreneurProvider);
    final tickets = ref.watch(supportTicketsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    if (activeEntre == null) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.darkPrimaryGold)),
      );
    }

    // Filter tickets belonging to active entrepreneur
    final entreTickets = tickets.where((t) => t.entrepreneurId == activeEntre.id).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('QAAFIYA SUPPORT DESK'),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
          labelColor: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
          unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "Tickets"),
            Tab(text: "FAQs"),
            Tab(text: "Direct Contacts"),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Ticket CRUD
            _buildTicketsTab(entreTickets, activeEntre, isDark),
            
            // Tab 2: FAQ accordion
            _buildFaqTab(isDark),
            
            // Tab 3: Contact directory
            _buildContactTab(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsTab(List<SupportTicket> list, Entrepreneur activeEntre, bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR ACTIVE SERVICE TICKETS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateTicketDialog(context, activeEntre),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('RAISE TICKET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                  foregroundColor: isDark ? AppTheme.darkBackground : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text("You have no active support tickets."))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final ticket = list[index];
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
                                Text(
                                  ticket.id,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Courier'),
                                ),
                                _buildPriorityBadge(ticket.priority),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ticket.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Category: ${ticket.category}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ticket.description,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text('STATUS: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    _buildStatusBadge(ticket.status),
                                  ],
                                ),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        PremiumDialog.show(
                                          context: context,
                                          title: "Delete Support Ticket?",
                                          icon: Icons.delete_forever_rounded,
                                          iconColor: AppTheme.colorError,
                                          content: Text(
                                            "Are you sure you want to permanently delete support ticket '${ticket.title}'?",
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
                                                ref.read(supportTicketsProvider.notifier).delete(ticket.id);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Ticket deleted successfully.')),
                                                );
                                              },
                                              child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                            ),
                                          ],
                                        );
                                      },
                                      child: const Text('DELETE', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    if (ticket.status != 'Resolved') ...[
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          ref.read(supportTicketsProvider.notifier).save(
                                            ticket.copyWith(status: 'Resolved'),
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Ticket marked as Resolved.')),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.colorSuccess,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        ),
                                        child: const Text('RESOLVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ]
                                  ],
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
    );
  }

  Widget _buildPriorityBadge(String prio) {
    Color color = Colors.orange;
    if (prio == 'High') color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        prio.toUpperCase(),
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppTheme.colorWarning;
    if (status == 'Resolved') color = AppTheme.colorSuccess;
    if (status == 'In-Progress') color = AppTheme.colorInfo;
    return Text(
      status.toUpperCase(),
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
    );
  }

  Widget _buildFaqTab(bool isDark) {
    final faqs = [
      {
        'q': 'What is the daily cutoff for warehouse dispatches?',
        'a': 'All orders placed and marked as Processing before 1:00 PM IST are guaranteed to be dispatched via Delhivery/BlueDart on the same working day. Orders past 1:00 PM are dispatched next morning.'
      },
      {
        'q': 'How quickly are COD collections settled in bank accounts?',
        'a': 'Qaafiya One settles collected cash in T+2 rolling settlement cycles. You can monitor cycles in detail inside the COD Clearing House module.'
      },
      {
        'q': 'How are RTOs calculated and when are they flagged?',
        'a': 'If a parcel fails delivery 3 times, courier systems trigger an RTO (Return to Origin) alert in the Shipment center. NDR re-attempts can be scheduled manually.'
      },
      {
        'q': 'How do I replenish warehouse inventories?',
        'a': 'Draft a supplier order inside the Product console, linking it to the respective Warehouse. Suppliers will receive alerts to pack and dispatch stock nodes.'
      }
    ];

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        final item = faqs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              title: Text(item['q']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              expandedAlignment: Alignment.topLeft,
              children: [
                Text(
                  item['a']!,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactTab(bool isDark) {
    final contacts = [
      {'name': 'Mr. Arvind Swamy', 'role': 'National Warehouse Lead', 'node': 'Delhi Fulfillment Node', 'phone': '+91 99000 11223'},
      {'name': 'Ms. Divya Nair', 'role': 'Regional Accounts Head', 'node': 'COD Finance Clearing', 'phone': '+91 98000 22334'},
      {'name': 'Mr. Sharan Reddy', 'role': 'Courier SLA Manager', 'node': 'Logistics & NDR Node', 'phone': '+91 97000 33445'},
    ];

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final card = contacts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? AppTheme.darkBorder : AppTheme.lightSurfaceCard),
                  child: const Icon(Icons.person_outline_rounded, color: AppTheme.darkPrimaryGold),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(card['role']!, style: const TextStyle(fontSize: 11, color: AppTheme.darkPrimaryGold, fontWeight: FontWeight.w600)),
                      Text(
                        card['node']!,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Call phone number simulation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling ${card['name']} at ${card['phone']}...')),
                    );
                  },
                  icon: const Icon(Icons.phone_enabled_rounded, color: AppTheme.colorSuccess),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateTicketDialog(BuildContext context, Entrepreneur activeEntre) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    
    String selectedCategory = "Warehouse Operations";
    final cats = ["Warehouse Operations", "COD Finance", "Shipment & NDR", "Account & Settings"];
    
    String selectedPriority = "Medium";
    final priorities = ["Low", "Medium", "High"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Raise Support Ticket'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Short Subject Title')),
                    const SizedBox(height: 8),
                    TextField(controller: descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Elaborate issue description...')),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Node Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          items: cats.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => selectedCategory = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Set Priority Level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButton<String>(
                          value: selectedPriority,
                          isExpanded: true,
                          items: priorities.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => selectedPriority = val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty || descController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill out all fields.')),
                      );
                      return;
                    }

                    final newTicket = SupportTicket(
                      id: 'T-${800 + DateTime.now().millisecond}',
                      entrepreneurId: activeEntre.id,
                      businessName: activeEntre.businessName,
                      title: titleController.text,
                      description: descController.text,
                      category: selectedCategory,
                      priority: selectedPriority,
                      status: 'Open',
                      createdAt: DateTime.now().toIso8601String(),
                    );

                    ref.read(supportTicketsProvider.notifier).save(newTicket);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Raised ticket ${newTicket.id} successfully!')),
                    );
                  },
                  child: const Text('SUBMIT'),
                )
              ],
            );
          },
        );
      },
    );
  }
}

// Extension to support labels on drop downs in old flutter or simplify layout
extension DropdownExtension on DropdownButton {
  Widget labelText(Widget label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        label,
        const SizedBox(height: 4),
        this,
      ],
    );
  }
}
