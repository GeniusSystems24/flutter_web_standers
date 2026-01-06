/// ==========================================
/// تكوين التطبيق (14-build-configuration.md)
/// ==========================================
///
/// هذا الملف يطبق:
/// - معيار 14: إعدادات البناء المثلى
/// - استخدام dart-define للتكوين
/// - فصل البيئات (dev, staging, prod)
library;

import 'package:flutter/foundation.dart' show kReleaseMode;

/// تكوين التطبيق الرئيسي
abstract class AppConfig {
  AppConfig._();

  /// اسم التطبيق
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Flutter Web Optimized',
  );

  /// إصدار التطبيق
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  /// البيئة الحالية
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// عنوان API
  static String get apiBaseUrl {
    const url = String.fromEnvironment('API_BASE_URL');
    if (url.isNotEmpty) return url;

    // URLs حسب البيئة
    return switch (environment) {
      'production' => 'https://api.example.com',
      'staging' => 'https://staging-api.example.com',
      _ => 'https://dev-api.example.com',
    };
  }

  /// هل نحن في الإنتاج؟
  static bool get isProduction => environment == 'production' || kReleaseMode;

  /// هل التحليلات مفعلة؟
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  /// هل تقارير الأعطال مفعلة؟
  static const bool enableCrashReporting = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: true,
  );

  /// مهلة الشبكة (بالثواني)
  static const int networkTimeout = int.fromEnvironment(
    'NETWORK_TIMEOUT',
    defaultValue: 30,
  );

  /// حجم الـ Cache الأقصى (بالميغابايت)
  static const int maxCacheSize = int.fromEnvironment(
    'MAX_CACHE_SIZE',
    defaultValue: 50,
  );
}

/// ميزات التطبيق (Feature Flags)
/// تُستخدم لتفعيل/تعطيل ميزات في وقت البناء
abstract class FeatureFlags {
  FeatureFlags._();

  /// ميزة الوضع المظلم
  static const bool enableDarkMode = bool.fromEnvironment(
    'ENABLE_DARK_MODE',
    defaultValue: true,
  );

  /// ميزة الإشعارات
  static const bool enableNotifications = bool.fromEnvironment(
    'ENABLE_NOTIFICATIONS',
    defaultValue: true,
  );

  /// ميزة التخزين المؤقت
  static const bool enableCaching = bool.fromEnvironment(
    'ENABLE_CACHING',
    defaultValue: true,
  );

  /// ميزة العمل بدون اتصال
  static const bool enableOfflineMode = bool.fromEnvironment(
    'ENABLE_OFFLINE_MODE',
    defaultValue: true,
  );

  /// ميزات تجريبية
  static const bool enableExperiments = bool.fromEnvironment(
    'ENABLE_EXPERIMENTS',
    defaultValue: false,
  );
}
