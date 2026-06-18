import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../providers/providers.dart';
import '../../../data/services/ai_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initDefaultApiSettings();
    // Premium Welcome message
    _messages.add(
      ChatMessage(
        text: "Pranam, Founder. I am Qaafiya AI, your secure business logistics advisor. I have mapped your local business node. Ask me about margin optimizations, warehouse stock warnings, delivery logistics diagnostics, or how to scale your sales.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _initDefaultApiSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('ai_provider') == null || prefs.getString('ai_provider') == 'grok') {
        await prefs.setString('ai_provider', 'gemini');
      }
      final currentKey = prefs.getString('ai_api_key');
      if (currentKey == null ||
          currentKey.isEmpty ||
          currentKey.startsWith('xai-') ||
          currentKey == 'AQ.Ab8RN6LwnVlrFq-RGVc6qZvLF-VoS5C4b7l_D9CoAeuEs5RwhQ' ||
          currentKey == 'AQ.Ab8RN6JnQtO2d2R1R_Ssb3BhiQgRp_ubTuJqYFoq2QWborVaMg') {
        await prefs.setString('ai_api_key', AiService.defaultGeminiKey);
      }
    } catch (e) {
      print("Error setting default Gemini API settings: $e");
    }
  }

  String _runLocalRAGQuery(String query) {
    final products = ref.read(productsProvider);
    final orders = ref.read(ordersProvider);
    final suppliers = ref.read(suppliersProvider);
    final warehouses = ref.read(warehousesProvider);
    final activeEntre = ref.read(currentEntrepreneurProvider);

    final cleanQuery = query.toLowerCase();

    // 1. QUERY: ORDERS / SALES / FINANCIALS
    if (cleanQuery.contains("order") || cleanQuery.contains("sale") || cleanQuery.contains("revenue") || cleanQuery.contains("profit") || cleanQuery.contains("earning")) {
      final entreOrders = orders.where((o) => o.entrepreneurId == activeEntre?.id).toList();
      final totalSales = entreOrders.fold(0, (sum, o) => sum + o.totalAmount);
      final pendingCount = entreOrders.where((o) => o.status == 'Pending').length;
      final deliveredCount = entreOrders.where((o) => o.status == 'Delivered').length;
      final returnedCount = entreOrders.where((o) => o.status == 'Returned' || o.status == 'RTO').length;
      final rtoRate = entreOrders.isNotEmpty ? (returnedCount / entreOrders.length * 100).toStringAsFixed(1) : "0";

      return "📊 **Financial & Sales Diagnostics (${activeEntre?.businessName ?? 'Your Business'}):**\n\n"
          "Here is the real-time sales overview from your local console:\n"
          "• **Gross Sales (Total):** ₹$totalSales\n"
          "• **Total Orders Registered:** ${entreOrders.length} orders\n"
          "• **Active Pending Dispatch:** $pendingCount orders\n"
          "• **Successful Deliveries:** $deliveredCount packages\n"
          "• **Returns / RTO Rate:** $returnedCount orders ($rtoRate% rate)\n"
          "• **Estimated Profit (based on ~45% markup):** ₹${(totalSales * 0.45).round()}\n\n"
          "💡 **Advisor Tip:** Your return rate is $rtoRate%. If this grows past 5%, we recommend running WhatsApp order confirmation before dispatch, and routing Tier-2 shipments via premium carriers like BlueDart to avoid transit cancellations.";
    }

    // 2. QUERY: PRODUCTS / INVENTORY / STOCK / MARGIN
    if (cleanQuery.contains("product") || cleanQuery.contains("stock") || cleanQuery.contains("inventory") || cleanQuery.contains("item") || cleanQuery.contains("margin")) {
      final lowStock = products.where((p) => p.inventoryCount < 50).toList();
      final avgMargin = products.isNotEmpty ? (products.fold(0, (sum, p) => sum + p.profitMargin) / products.length).toStringAsFixed(1) : "45";
      final topMarginProduct = products.isNotEmpty ? products.reduce((curr, next) => curr.profitMargin > next.profitMargin ? curr : next) : null;

      String lowStockText = lowStock.isEmpty
          ? "• All products have optimal stock levels (above 50 units)."
          : "• **Low Stock Warnings (${lowStock.length} items):**\n" +
              lowStock.take(3).map((p) => "   - ${p.name}: ${p.inventoryCount} units remaining (SKU: ${p.sku})").join("\n");

      return "📦 **Inventory Stock & Margin Analysis:**\n\n"
          "Scanning your current catalog:\n"
          "• **Total Active SKUs:** ${products.length} registered products\n"
          "• **Average Catalog Profit Margin:** $avgMargin%\n"
          "• **Top Profit Contributor:** ${topMarginProduct?.name ?? 'N/A'} (${topMarginProduct?.profitMargin ?? 0}% Margin)\n"
          "$lowStockText\n\n"
          "💡 **Advisor Tip:** Securing inventory replenishment for low-stock SKUs takes 5-8 business days from suppliers. Order soon to prevent stock-outs.";
    }

    // 3. QUERY: SUPPLIERS
    if (cleanQuery.contains("supplier") || cleanQuery.contains("rating") || cleanQuery.contains("vendor")) {
      final avgReliability = suppliers.isNotEmpty ? (suppliers.fold(0, (sum, s) => sum + s.reliabilityScore) / suppliers.length).toStringAsFixed(1) : "90";
      final activeSuppliers = suppliers.where((s) => s.status == 'Active').length;

      return "🏭 **Supply Chain Diagnostics:**\n\n"
          "Here is the status of your raw supply networks:\n"
          "• **Registered Suppliers:** ${suppliers.length} vendors ($activeSuppliers active)\n"
          "• **Average Supplier Reliability:** $avgReliability%\n"
          "• **Category Segments Covered:** ${suppliers.map((s) => s.category).toSet().join(', ')}\n\n"
          "💡 **Advisor Tip:** If a supplier's reliability falls below 85%, audit their lead time schedules to maintain standard dispatch SLA compliance.";
    }

    // 4. QUERY: WAREHOUSE / CAPACITY / LOGISTICS
    if (cleanQuery.contains("warehouse") || cleanQuery.contains("capacity") || cleanQuery.contains("location")) {
      final totalCapacity = warehouses.fold(0, (sum, w) => sum + w.capacity);
      final totalUsed = warehouses.fold(0, (sum, w) => sum + w.usedCapacity);
      final usageRate = totalCapacity > 0 ? (totalUsed / totalCapacity * 100).toStringAsFixed(1) : "0";

      return "🏢 **Fulfillment Nodes & Logistics Capacity:**\n\n"
          "Your storage network status:\n"
          "• **Active Warehouses:** ${warehouses.length} locations\n"
          "• **Net Capacity Utilization:** $totalUsed / $totalCapacity cubic units ($usageRate% capacity used)\n"
          "• **Fulfillment Hub Locations:** ${warehouses.map((w) => w.location).toSet().join(', ')}\n\n"
          "💡 **Advisor Tip:** The Bangalore Node is running close to capacity. We suggest routing newer shipments to regional warehouses to balance operations.";
    }

    // 5. QUERY: GENERAL GROWTH / SCALE / RTO REDUCTION
    if (cleanQuery.contains("grow") || cleanQuery.contains("marketing") || cleanQuery.contains("scale") || cleanQuery.contains("rto") || cleanQuery.contains("reduce") || cleanQuery.contains("business")) {
      return "📈 **Qaafiya Growth & RTO Strategy Guide:**\n\n"
          "To optimize conversions and scale your enterprise effectively, execute these key plays:\n"
          "• **Minimize COD Risk:** Offer a small incentive (e.g. ₹50 cashback or free shipping) for digital prepayments. Prepaid orders experience 85% fewer RTOs compared to COD.\n"
          "• **Automated Notifications:** Send dispatch tracking details via SMS/WhatsApp automatically. Customers notified within 1 hour are 40% less likely to reject packages.\n"
          "• **Fulfillment Operations:** Keep dispatch processing time under 24 hours. A fast dispatch score significantly boosts your Qaafiya Elite Score and overall rank.";
    }

    // 6. DEFAULT RETRIEVAL
    final totalSales = orders.where((o) => o.entrepreneurId == activeEntre?.id).fold(0, (sum, o) => sum + o.totalAmount);
    return "🤖 **Hello Founder, I am Qaafiya AI.**\n\n"
        "I have scanned your local database registries. Here is a summary of your entity:\n"
        "• **Entrepreneur Profile:** ${activeEntre?.name ?? 'Guest'} (Elite Rank #${activeEntre?.rank ?? 'N/A'})\n"
        "• **Business Brand:** ${activeEntre?.businessName ?? 'N/A'}\n"
        "• **Local Databases:** ${products.length} Products, ${orders.length} Orders, ${suppliers.length} Suppliers, ${warehouses.length} Warehouses.\n"
        "• **Overall Gross Revenue:** ₹$totalSales\n"
        "• **Low Stock Alerts:** ${products.where((p) => p.inventoryCount < 50).length} SKUs triggering alert.\n\n"
        "💬 **You can ask me specific questions like:**\n"
        "- *'Show my sales and revenue breakdown'*\n"
        "- *'How is my inventory stock level?'*\n"
        "- *'Give me advice on reducing RTO and scaling'*";
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    final localDataSummary = _runLocalRAGQuery(text);

    // Call central AI Service Layer
    final aiService = ref.read(aiServiceProvider);
    final finalResponse = await aiService.getCompletion(
      prompt: text,
      localContext: localDataSummary,
    );

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(text: finalResponse, isUser: false, timestamp: DateTime.now()));
    });
    _scrollToBottom();
  }

  void _showSettingsDialog(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    String activeProvider = prefs.getString('ai_provider') ?? 'local';
    final keyController = TextEditingController(text: prefs.getString('ai_api_key') ?? '');

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.settings_outlined, color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold),
                  const SizedBox(width: 8),
                  const Text('AI API SETTINGS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SELECT AI ENGINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButton<String>(
                      value: activeProvider,
                      isExpanded: true,
                      dropdownColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      items: const [
                        DropdownMenuItem(value: 'local', child: Text('Local Smart Advisor (No Key)')),
                        DropdownMenuItem(value: 'gemini', child: Text('Gemini API (Free Tier)')),
                        DropdownMenuItem(value: 'openai', child: Text('ChatGPT / OpenAI API')),
                        DropdownMenuItem(value: 'grok', child: Text('Grok / xAI API')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            activeProvider = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (activeProvider != 'local') ...[
                      const Text('PASTE API SECRET KEY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: keyController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Enter API key here...',
                          fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightSurfaceCard,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activeProvider == 'gemini'
                            ? 'Tip: You can get a free Gemini API Key from Google AI Studio.'
                            : 'Enter your API key to make live requests.',
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ] else ...[
                      Text(
                        'Uses local RAG diagnostic algorithms to analyze database metrics and supply general business consulting tips conversationally.',
                        style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final p = await SharedPreferences.getInstance();
                    await p.setString('ai_provider', activeProvider);
                    await p.setString('ai_api_key', keyController.text);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('AI Settings saved successfully!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkPrimaryGold,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('SAVE SETTINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('QAAFIYA AI ASSISTANT'),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold),
            onPressed: () => _showSettingsDialog(isDark),
            tooltip: "Configure API Key",
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat history list
            Expanded(
              child: _messages.isEmpty
                  ? const Center(child: Text("Initializing connections..."))
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return _buildChatBubble(msg, isDark);
                      },
                    ),
            ),
            
            // Typing Indicator
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(AppTheme.darkPrimaryGold)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Qaafiya AI is formulating advice...',
                      style: TextStyle(fontSize: 10, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            // Quick Diagnostic Prompt Chips
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPromptChip("Suggest Margin Optimization", isDark),
                  const SizedBox(width: 8),
                  _buildPromptChip("NDR & RTO Diagnosis", isDark),
                  const SizedBox(width: 8),
                  _buildPromptChip("Inventory Risk Alert", isDark),
                  const SizedBox(width: 8),
                  _buildPromptChip("Festive Scale Plan", isDark),
                ],
              ),
            ),
            
            // Text Entry Box
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: "Ask Qaafiya AI...",
                        fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                    radius: 24,
                    child: IconButton(
                      onPressed: () => _sendMessage(_controller.text),
                      icon: Icon(Icons.send_rounded, color: isDark ? AppTheme.darkBackground : Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip(String text, bool isDark) {
    return ActionChip(
      onPressed: () => _sendMessage(text),
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard,
      side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 0.5),
      label: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg, bool isDark) {
    final align = msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleBg = msg.isUser
        ? (isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceCard)
        : Colors.transparent;

    final bubbleBorder = msg.isUser
        ? Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1)
        : Border.all(color: AppTheme.darkPrimaryGold.withOpacity(0.4), width: 1);

    final textStyle = TextStyle(
      fontSize: 13,
      height: 1.5,
      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
    );

    return Column(
      crossAxisAlignment: align,
      children: [
        Row(
          mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isUser) ...[
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.darkPrimaryGold, width: 1)),
                child: const Text('⚡', style: TextStyle(fontSize: 12)),
              ),
            ],
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bubbleBg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: msg.isUser ? const Radius.circular(16) : Radius.zero,
                    bottomRight: msg.isUser ? Radius.zero : const Radius.circular(16),
                  ),
                  border: bubbleBorder,
                ),
                child: Text(
                  msg.text,
                  style: textStyle,
                ),
              ),
            ),
            if (msg.isUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.darkBorder, width: 1)),
                child: const Text('👤', style: TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
