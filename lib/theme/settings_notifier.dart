import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');
  int _firstDayOfWeek = 1; // 1 for Monday, 7 for Sunday (consistent with DateTime)

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  int get firstDayOfWeek => _firstDayOfWeek;

  SettingsNotifier() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Theme
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    
    // Locale
    final languageCode = prefs.getString('languageCode') ?? 'en';
    _locale = Locale(languageCode);
    
    // Week Start
    _firstDayOfWeek = prefs.getInt('firstDayOfWeek') ?? 1;
    
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', mode == ThemeMode.dark);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
  }

  Future<void> setFirstDayOfWeek(int day) async {
    _firstDayOfWeek = day;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('firstDayOfWeek', day);
  }
}

final settingsNotifier = SettingsNotifier();
