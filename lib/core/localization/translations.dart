import '../../presentation/providers/providers.dart';

class Translations {
  static const Map<String, Map<AppLanguage, String>> _keys = {
    // Nav / Sidebar / Titles
    'dashboard': {
      AppLanguage.english: 'Dashboard',
      AppLanguage.hindi: 'डैशबोर्ड',
    },
    'score': {
      AppLanguage.english: 'Elite Score',
      AppLanguage.hindi: 'एलीट स्कोर',
    },
    'orders_tab': {
      AppLanguage.english: 'Order Registry',
      AppLanguage.hindi: 'ऑर्डर रजिस्ट्री',
    },
    'products_tab': {
      AppLanguage.english: 'Product Catalog',
      AppLanguage.hindi: 'उत्पाद कैटलॉग',
    },
    'suppliers_tab': {
      AppLanguage.english: 'Suppliers Directory',
      AppLanguage.hindi: 'आपूर्तिकर्ता डायरेक्टरी',
    },
    'warehouses_tab': {
      AppLanguage.english: 'Warehouses',
      AppLanguage.hindi: 'गोदाम',
    },
    'cod_tab': {
      AppLanguage.english: 'COD Settlements',
      AppLanguage.hindi: 'सीओडी भुगतान',
    },
    'shipments_tab': {
      AppLanguage.english: 'Shipment Tracker',
      AppLanguage.hindi: 'शिपमेंट ट्रैकर',
    },
    'analytics_tab': {
      AppLanguage.english: 'Analytics',
      AppLanguage.hindi: 'विश्लेषण',
    },
    'ai_tab': {
      AppLanguage.english: 'Qaafiya AI',
      AppLanguage.hindi: 'क़ाफ़िया एआई',
    },
    'community_tab': {
      AppLanguage.english: 'Community',
      AppLanguage.hindi: 'कम्युनिटी',
    },
    'support_tab': {
      AppLanguage.english: 'Support Tickets',
      AppLanguage.hindi: 'सहायता टिकट',
    },

    // Metrics
    'revenue': {
      AppLanguage.english: 'Revenue',
      AppLanguage.hindi: 'राजस्व (कमाई)',
    },
    'net_profit': {
      AppLanguage.english: 'Net Profit',
      AppLanguage.hindi: 'शुद्ध लाभ',
    },
    'total_orders': {
      AppLanguage.english: 'Total Orders',
      AppLanguage.hindi: 'कुल ऑर्डर',
    },
    'pending_orders': {
      AppLanguage.english: 'Pending Orders',
      AppLanguage.hindi: 'लंबित ऑर्डर',
    },
    'today': {
      AppLanguage.english: 'Today',
      AppLanguage.hindi: 'आज',
    },
    'weekly': {
      AppLanguage.english: 'Weekly',
      AppLanguage.hindi: 'साप्ताहिक',
    },
    'monthly': {
      AppLanguage.english: 'Monthly',
      AppLanguage.hindi: 'मासिक',
    },
    'score_cap': {
      AppLanguage.english: 'SCORE',
      AppLanguage.hindi: 'स्कोर',
    },

    // Switch Profile UI
    'switch_profile': {
      AppLanguage.english: 'Switch profile (Founder-demo mode)',
      AppLanguage.hindi: 'प्रोफ़ाइल बदलें (डेमो फ़ाउंडर मोड)',
    },
    'select_demo_profile': {
      AppLanguage.english: 'Select Demo Founder Profile',
      AppLanguage.hindi: 'डेमो फ़ाउंडर प्रोफ़ाइल चुनें',
    },
    'profile_switch_desc': {
      AppLanguage.english: 'Switch between different pre-loaded entrepreneur profiles to visualize app state transitions across various growth ranks.',
      AppLanguage.hindi: 'विभिन्न विकास श्रेणियों में ऐप स्थिति परिवर्तनों को देखने के लिए अलग-अलग प्री-लोडेड उद्यमी प्रोफ़ाइलों के बीच स्विच करें।',
    },

    // Console Guide Dialog
    'console_guide': {
      AppLanguage.english: 'Console Guide',
      AppLanguage.hindi: 'कंसोल गाइड',
    },
    'role_usage_guide': {
      AppLanguage.english: 'Current Role Usage Guide',
      AppLanguage.hindi: 'वर्तमान भूमिका उपयोग गाइड',
    },
    'role_description_title': {
      AppLanguage.english: 'You are viewing the app as:',
      AppLanguage.hindi: 'आप ऐप को इस रूप में देख रहे हैं:',
    },
    'got_it': {
      AppLanguage.english: 'Got It, Let\'s Go!',
      AppLanguage.hindi: 'समझ गया, आगे बढ़ें!',
    },

    // AI Chat
    'ai_assistant_title': {
      AppLanguage.english: 'Qaafiya AI Assistant (RAG Engine)',
      AppLanguage.hindi: 'क़ाफ़िया एआई सहायक (रैग इंजन)',
    },
    'ai_placeholder': {
      AppLanguage.english: 'Ask anything about your products, sales, margins, warehouses, or stock levels...',
      AppLanguage.hindi: 'अपने उत्पादों, बिक्री, मार्जिन, गोदामों या स्टॉक के बारे में कुछ भी पूछें...',
    },

    // Invoice UI
    'download_invoice': {
      AppLanguage.english: 'Download Invoice',
      AppLanguage.hindi: 'इनवॉइस डाउनलोड करें',
    },
    'share_invoice': {
      AppLanguage.english: 'Share Invoice',
      AppLanguage.hindi: 'इनवॉइस साझा करें',
    },
    'invoice_tax_summary': {
      AppLanguage.english: 'GST & Tax Summary',
      AppLanguage.hindi: 'जीएसटी और टैक्स विवरण',
    },
    'subtotal': {
      AppLanguage.english: 'Subtotal',
      AppLanguage.hindi: 'उप-योग',
    },
    'tax_gst': {
      AppLanguage.english: 'GST Tax (18%)',
      AppLanguage.hindi: 'जीएसटी टैक्स (18%)',
    },
    'grand_total': {
      AppLanguage.english: 'Grand Total',
      AppLanguage.hindi: 'कुल देय राशि',
    },
  };

  static String translate(String key, AppLanguage lang) {
    final keyMap = _keys[key];
    if (keyMap == null) return key;
    return keyMap[lang] ?? keyMap[AppLanguage.english] ?? key;
  }
}
