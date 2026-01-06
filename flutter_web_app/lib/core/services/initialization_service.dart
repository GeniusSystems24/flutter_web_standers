/// ==========================================
/// خدمة التهيئة المرحلية (09-initial-load.md)
/// ==========================================
///
/// هذا الملف يطبق:
/// - معيار 9: تحسين التحميل الأولي
/// - التهيئة على 3 مراحل
/// - تأجيل التهيئات غير الضرورية
library;

import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;

/// مراحل التهيئة
enum InitPhase { critical, important, background }

/// خدمة التهيئة المرحلية
class InitializationService {
  InitializationService._();

  static final _phaseCompleters = <InitPhase, Completer<void>>{};
  static final _timestamps = <String, DateTime>{};

  /// المرحلة 1: التهيئات الحرجة (قبل عرض أي شيء)
  /// ~200ms كحد أقصى
  static Future<void> initCritical() async {
    _mark('critical_start');

    await Future.wait([
      _initLocalization(),
      _initTheme(),
      _initAuthState(),
    ]);

    _mark('critical_end');
    _completePhase(InitPhase.critical);

    if (kDebugMode) {
      _logDuration('Critical init', 'critical_start', 'critical_end');
    }
  }

  /// المرحلة 2: التهيئات المهمة (بعد الشاشة الأولى)
  /// تعمل في الخلفية بدون حجب UI
  static Future<void> initImportant() async {
    _mark('important_start');

    await Future.wait([
      _initAnalytics(),
      _initNotifications(),
      _initDeepLinks(),
    ]);

    _mark('important_end');
    _completePhase(InitPhase.important);

    if (kDebugMode) {
      _logDuration('Important init', 'important_start', 'important_end');
    }
  }

  /// المرحلة 3: التهيئات الخلفية (في وقت الفراغ)
  /// تعمل عندما يكون التطبيق خاملاً
  static Future<void> initBackground() async {
    _mark('background_start');

    await Future.wait([
      _initCrashReporting(),
      _initRemoteConfig(),
      _prefetchCommonData(),
    ]);

    _mark('background_end');
    _completePhase(InitPhase.background);

    if (kDebugMode) {
      _logDuration('Background init', 'background_start', 'background_end');
      _printAllTimings();
    }
  }

  /// انتظار اكتمال مرحلة معينة
  static Future<void> waitForPhase(InitPhase phase) {
    _phaseCompleters[phase] ??= Completer<void>();
    return _phaseCompleters[phase]!.future;
  }

  /// هل اكتملت مرحلة معينة؟
  static bool isPhaseComplete(InitPhase phase) {
    return _phaseCompleters[phase]?.isCompleted ?? false;
  }

  // ===== التهيئات الفردية =====

  static Future<void> _initLocalization() async {
    // تحميل اللغة من التخزين المحلي
    await Future.delayed(const Duration(milliseconds: 50));
    if (kDebugMode) print('[Init] Localization ready');
  }

  static Future<void> _initTheme() async {
    // تحميل السمة المحفوظة
    await Future.delayed(const Duration(milliseconds: 30));
    if (kDebugMode) print('[Init] Theme ready');
  }

  static Future<void> _initAuthState() async {
    // التحقق من حالة تسجيل الدخول
    await Future.delayed(const Duration(milliseconds: 100));
    if (kDebugMode) print('[Init] Auth state ready');
  }

  static Future<void> _initAnalytics() async {
    // تهيئة التحليلات
    await Future.delayed(const Duration(milliseconds: 200));
    if (kDebugMode) print('[Init] Analytics ready');
  }

  static Future<void> _initNotifications() async {
    // تهيئة الإشعارات
    await Future.delayed(const Duration(milliseconds: 150));
    if (kDebugMode) print('[Init] Notifications ready');
  }

  static Future<void> _initDeepLinks() async {
    // تهيئة الروابط العميقة
    await Future.delayed(const Duration(milliseconds: 50));
    if (kDebugMode) print('[Init] Deep links ready');
  }

  static Future<void> _initCrashReporting() async {
    // تهيئة تقارير الأعطال
    await Future.delayed(const Duration(milliseconds: 300));
    if (kDebugMode) print('[Init] Crash reporting ready');
  }

  static Future<void> _initRemoteConfig() async {
    // جلب الإعدادات عن بعد
    await Future.delayed(const Duration(milliseconds: 500));
    if (kDebugMode) print('[Init] Remote config ready');
  }

  static Future<void> _prefetchCommonData() async {
    // جلب البيانات الشائعة مسبقاً
    await Future.delayed(const Duration(milliseconds: 300));
    if (kDebugMode) print('[Init] Common data prefetched');
  }

  // ===== أدوات القياس =====

  static void _mark(String name) {
    _timestamps[name] = DateTime.now();
  }

  static void _completePhase(InitPhase phase) {
    _phaseCompleters[phase] ??= Completer<void>();
    if (!_phaseCompleters[phase]!.isCompleted) {
      _phaseCompleters[phase]!.complete();
    }
  }

  static void _logDuration(String label, String start, String end) {
    final startTime = _timestamps[start];
    final endTime = _timestamps[end];
    if (startTime != null && endTime != null) {
      final duration = endTime.difference(startTime).inMilliseconds;
      print('[Performance] $label: ${duration}ms');
    }
  }

  static void _printAllTimings() {
    print('\n=== Initialization Timings ===');
    final sortedKeys = _timestamps.keys.toList()..sort();
    final firstTime = _timestamps[sortedKeys.first]!;

    for (final key in sortedKeys) {
      final offset = _timestamps[key]!.difference(firstTime).inMilliseconds;
      print('  $key: +${offset}ms');
    }
    print('==============================\n');
  }
}
