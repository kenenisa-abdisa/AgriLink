import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationProvider extends ChangeNotifier {
  String _locale = 'en';

  String get locale => _locale;

  LocalizationProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString('app_language') ?? 'en';
    notifyListeners();
  }

  Future<void> setLocale(String localeCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', localeCode);
    _locale = localeCode;
    notifyListeners();
  }

  String translate(String key) {
    if (_locale == 'en') return key;
    return _dictionary[_locale]?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _dictionary = {
    'am': {
      'Home': 'መነሻ',
      'Marketplace': 'ገበያ',
      'Farmers': 'አርሶ አደሮች',
      'Profile': 'ፕሮፋይል',
      'Messages': 'መልእክቶች',
      'Search products, farmers...': 'ምርቶችን፣ ገበሬዎችን ይፈልጉ...',
      'AgriLink Ethiopia': 'አግሪሊንክ ኢትዮጵያ',
      'Fresh · Local · Direct': 'ትኩስ · አካባቢያዊ · ቀጥታ',
      'Email': 'ኢሜይል',
      'Password': 'የይለፍ ቃል',
      'Sign In': 'ግባ',
      'Sign Up': 'ተመዝገብ',
      'Full Name': 'ሙሉ ስም',
      'Phone': 'ስልክ',
      'New to AgriLink? Sign Up': 'አዲስ ነዎት? ይመዝገቡ',
      'Already have an account? Sign In': 'ቀድሞውኑ መለያ አለዎት? ይግቡ',
      'Language': 'ቋንቋ',
      'How it Works': 'እንዴት እንደሚሰራ',
      'Direct from Farm': 'ቀጥታ ከአርሶ አደሩ',
      'Our platform connects you directly with local farmers, ensuring fresh products and fair prices.':
          'የእኛ መድረክ ትኩስ ምርቶችን እና ተመጣጣኝ ዋጋን በማረጋገጥ በቀጥታ ከአካባቢው ገበሬዎች ጋር ያገናኝዎታል።',
      'Welcome to AgriLink! 👋': 'እንኳን ወደ አግሪሊንክ በደህና መጡ! 👋',
      'Farmer Profile Created! 🌾': 'የገበሬ ፕሮፋይል ተፈጥሯል! 🌾',
      'Contact Farmer': 'ገበሬውን ያግኙ',
    },
    'or': {
      'Home': 'Mana',
      'Marketplace': 'Gabaa',
      'Farmers': 'Qotee Bulaa',
      'Profile': 'Profaayilii',
      'Messages': 'Ergaa',
      'Search products, farmers...': 'Oomishaa fi qotee bulaa barbaadi...',
      'AgriLink Ethiopia': 'AgriLink Itoophiyaa',
      'Fresh · Local · Direct': 'Haaraa · Naannoo · Kallattiin',
      'Email': 'Imeelii',
      'Password': 'Iccitii',
      'Sign In': 'Seeni',
      'Sign Up': 'Galmaahi',
      'Full Name': 'Maqaa Guutuu',
      'Phone': 'Bilbila',
      'New to AgriLink? Sign Up': 'Haaraadha? Galmaahi',
      'Already have an account? Sign In': 'Eenyummeessa qabdaa? Seeni',
      'Language': 'Afaan',
      'How it Works': 'Akkaataa itti hojjetu',
      'Direct from Farm': 'Kallattiin Qotee Bulaa irraa',
      'Our platform connects you directly with local farmers, ensuring fresh products and fair prices.':
          'Platformiin keenya kallattiin qotee bulaa naannoo waliin wal isin qunnamsiisa.',
      'Welcome to AgriLink! 👋': 'Baga gara AgriLink nagaan dhuftan! 👋',
      'Farmer Profile Created! 🌾': 'Profaayilii qotee bulaa uumameera! 🌾',
      'Contact Farmer': 'Qotee bulaa quunnamaa',
    },
  };
}
