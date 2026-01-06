/// ==========================================
/// سمة التطبيق المحسنة (07-rendering-optimization.md)
/// ==========================================
///
/// هذا الملف يطبق:
/// - معيار 7: تحسين الرسم والتصيير
/// - استخدام const حيثما أمكن
/// - ألوان محسوبة مسبقاً
/// - تجنب إعادة إنشاء الكائنات
library;

import 'package:flutter/material.dart';

/// سمة التطبيق
abstract class AppTheme {
  AppTheme._();

  // ===== الألوان الأساسية =====
  static const _primaryColor = Color(0xFF2196F3);
  static const _primaryDark = Color(0xFF1976D2);
  static const _primaryLight = Color(0xFF64B5F6);
  static const _accent = Color(0xFF03A9F4);

  // ===== السمة الفاتحة =====
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.all(8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    fontFamily: 'Cairo',
  );

  // ===== السمة المظلمة =====
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Color(0xFF1E1E1E),
    ),
    cardTheme: const CardThemeData(
      elevation: 4,
      margin: EdgeInsets.all(8),
      color: Color(0xFF1E1E1E),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    fontFamily: 'Cairo',
  );
}

/// ثوابت الواجهة المشتركة (const للأداء)
abstract class AppStyles {
  AppStyles._();

  // ===== المسافات =====
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  // ===== Padding =====
  static const screenPadding = EdgeInsets.all(16);
  static const cardPadding = EdgeInsets.all(12);
  static const listItemPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  // ===== Border Radius =====
  static const radiusSm = BorderRadius.all(Radius.circular(4));
  static const radiusMd = BorderRadius.all(Radius.circular(8));
  static const radiusLg = BorderRadius.all(Radius.circular(16));
  static const radiusXl = BorderRadius.all(Radius.circular(24));

  // ===== الظلال =====
  static const shadowSm = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const shadowMd = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const shadowLg = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}
