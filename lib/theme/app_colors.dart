import 'package:flutter/material.dart';
import 'package:progresso/theme/settings_notifier.dart';

class AppColors {
  AppColors._();

  static bool get _isDark => settingsNotifier.themeMode == ThemeMode.dark;

  // Primary
  static Color get primary => const Color(0xFF5048E5);

  // Backgrounds
  static Color get backgroundLight => _isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F6F8);
  
  // Slate Scale (Flipped in dark mode)
  static Color get slate50 => _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  static Color get slate100 => _isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
  static Color get slate200 => _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  static Color get slate300 => _isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
  static Color get slate400 => _isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  static Color get slate500 => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color get slate600 => _isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
  static Color get slate700 => _isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
  static Color get slate800 => _isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
  static Color get slate900 => _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  // Static colors that don't change based on theme or retain their hue
  // Indigo Scale
  static Color get indigo50 => _isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF);
  static Color get indigo100 => _isDark ? const Color(0xFF312E81) : const Color(0xFFE0E7FF);
  static Color get indigo500 => const Color(0xFF6366F1);
  static Color get indigo600 => const Color(0xFF4F46E5);

  // Amber Scale
  static Color get amber50 => _isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB);
  static Color get amber100 => _isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
  static Color get amber500 => const Color(0xFFF59E0B);
  static Color get amber600 => const Color(0xFFD97706);

  // Blue Scale
  static Color get blue50 => _isDark ? const Color(0xFF172554) : const Color(0xFFEFF6FF);
  static Color get blue100 => _isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE);
  static Color get blue500 => const Color(0xFF3B82F6);

  // Emerald Scale
  static Color get emerald50 => _isDark ? const Color(0xFF022C22) : const Color(0xFFECFDF5);
  static Color get emerald100 => _isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
  static Color get emerald200 => _isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0);
  static Color get emerald300 => _isDark ? const Color(0xFF047857) : const Color(0xFF6EE7B7);
  static Color get emerald500 => const Color(0xFF10B981);
  static Color get emerald600 => const Color(0xFF059669);

  // Rose Scale
  static Color get rose50 => _isDark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2);
  static Color get rose100 => _isDark ? const Color(0xFF881337) : const Color(0xFFFFE4E6);
  static Color get rose500 => const Color(0xFFF43F5E);
  static Color get rose600 => const Color(0xFFE11D48);

  static Color get error => const Color(0xFFE11D48);
  static Color get success => const Color(0xFF059669);

  static Color get white => _isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
}
