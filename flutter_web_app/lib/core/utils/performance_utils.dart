/// ==========================================
/// أدوات قياس الأداء (13-measurement-tools.md)
/// ==========================================
///
/// هذا الملف يطبق:
/// - معيار 13: أدوات القياس
/// - قياس Web Vitals
/// - مراقبة أداء التطبيق
library;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

/// مقاييس بدء التشغيل
class StartupMetrics {
  StartupMetrics._();

  static final _timestamps = <String, DateTime>{};

  /// تسجيل نقطة زمنية
  static void mark(String name) {
    _timestamps[name] = DateTime.now();
    if (kDebugMode) {
      print('[Metrics] $name: ${DateTime.now().toIso8601String()}');
    }
  }

  /// الحصول على المدة بين نقطتين
  static Duration? getDuration(String from, String to) {
    final start = _timestamps[from];
    final end = _timestamps[to];
    if (start == null || end == null) return null;
    return end.difference(start);
  }

  /// طباعة جميع المقاييس
  static void logAll() {
    if (!kDebugMode) return;

    print('\n=== Startup Metrics ===');

    final appStart = _timestamps['app_start'];
    if (appStart == null) {
      print('No metrics recorded');
      return;
    }

    _timestamps.forEach((name, time) {
      if (name != 'app_start') {
        final duration = time.difference(appStart).inMilliseconds;
        print('$name: ${duration}ms');
      }
    });

    print('=========================\n');
  }

  /// تصدير المقاييس كـ JSON
  static Map<String, int> toJson() {
    final appStart = _timestamps['app_start'];
    if (appStart == null) return {};

    return _timestamps.map((name, time) {
      return MapEntry(name, time.difference(appStart).inMilliseconds);
    });
  }

  /// مسح المقاييس
  static void clear() => _timestamps.clear();
}

/// مراقب أداء الإطارات
class FrameMetrics {
  FrameMetrics._();

  static final _frameTimes = <int>[];
  static const _maxSamples = 120; // آخر 120 إطار (ثانيتين على 60fps)

  /// تسجيل وقت الإطار (بالميكروثانية)
  static void recordFrame(int microseconds) {
    _frameTimes.add(microseconds);
    if (_frameTimes.length > _maxSamples) {
      _frameTimes.removeAt(0);
    }
  }

  /// متوسط وقت الإطار
  static double get averageFrameTime {
    if (_frameTimes.isEmpty) return 0;
    return _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
  }

  /// معدل الإطارات (FPS)
  static double get fps {
    final avg = averageFrameTime;
    return avg > 0 ? 1000000 / avg : 0;
  }

  /// نسبة الإطارات المتأخرة (Jank)
  static double get jankRate {
    if (_frameTimes.isEmpty) return 0;
    const threshold = 16667; // 16.67ms للحصول على 60fps
    final jankFrames = _frameTimes.where((t) => t > threshold).length;
    return jankFrames / _frameTimes.length;
  }

  /// إحصائيات الأداء
  static Map<String, dynamic> get stats => {
        'fps': fps.toStringAsFixed(1),
        'averageFrameTime': '${(averageFrameTime / 1000).toStringAsFixed(2)}ms',
        'jankRate': '${(jankRate * 100).toStringAsFixed(1)}%',
        'samples': _frameTimes.length,
      };
}

/// أهداف Core Web Vitals
abstract class WebVitalsTargets {
  WebVitalsTargets._();

  /// LCP - Largest Contentful Paint
  static const lcpGood = Duration(milliseconds: 2500);
  static const lcpNeedsImprovement = Duration(milliseconds: 4000);

  /// FID - First Input Delay
  static const fidGood = Duration(milliseconds: 100);
  static const fidNeedsImprovement = Duration(milliseconds: 300);

  /// CLS - Cumulative Layout Shift
  static const clsGood = 0.1;
  static const clsNeedsImprovement = 0.25;

  /// FCP - First Contentful Paint
  static const fcpGood = Duration(milliseconds: 1800);
  static const fcpNeedsImprovement = Duration(milliseconds: 3000);

  /// TTI - Time to Interactive
  static const ttiGood = Duration(milliseconds: 3800);
  static const ttiNeedsImprovement = Duration(milliseconds: 7300);

  /// TTFB - Time to First Byte
  static const ttfbGood = Duration(milliseconds: 800);
  static const ttfbNeedsImprovement = Duration(milliseconds: 1800);
}

/// تقييم الأداء
enum PerformanceRating { good, needsImprovement, poor }

/// مساعد تقييم الأداء
class PerformanceEvaluator {
  PerformanceEvaluator._();

  /// تقييم LCP
  static PerformanceRating evaluateLCP(Duration duration) {
    if (duration <= WebVitalsTargets.lcpGood) return PerformanceRating.good;
    if (duration <= WebVitalsTargets.lcpNeedsImprovement) {
      return PerformanceRating.needsImprovement;
    }
    return PerformanceRating.poor;
  }

  /// تقييم FID
  static PerformanceRating evaluateFID(Duration duration) {
    if (duration <= WebVitalsTargets.fidGood) return PerformanceRating.good;
    if (duration <= WebVitalsTargets.fidNeedsImprovement) {
      return PerformanceRating.needsImprovement;
    }
    return PerformanceRating.poor;
  }

  /// تقييم CLS
  static PerformanceRating evaluateCLS(double score) {
    if (score <= WebVitalsTargets.clsGood) return PerformanceRating.good;
    if (score <= WebVitalsTargets.clsNeedsImprovement) {
      return PerformanceRating.needsImprovement;
    }
    return PerformanceRating.poor;
  }

  /// لون التقييم
  static String ratingColor(PerformanceRating rating) {
    return switch (rating) {
      PerformanceRating.good => 'green',
      PerformanceRating.needsImprovement => 'orange',
      PerformanceRating.poor => 'red',
    };
  }
}

/// سجل الأداء
class PerformanceLogger {
  PerformanceLogger._();

  static bool _enabled = kDebugMode;

  /// تفعيل/تعطيل التسجيل
  static set enabled(bool value) => _enabled = value;

  /// تسجيل حدث
  static void log(String category, String event, [Map<String, dynamic>? data]) {
    if (!_enabled) return;
    print('[Performance][$category] $event ${data != null ? ': $data' : ''}');
  }

  /// تسجيل خطأ أداء
  static void logError(String category, String error, [StackTrace? stack]) {
    if (!_enabled) return;
    print('[Performance Error][$category] $error');
    if (stack != null) print(stack);
  }

  /// قياس مدة عملية
  static Future<T> measure<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      log('Measure', name, {'duration': '${stopwatch.elapsedMilliseconds}ms'});
      return result;
    } catch (e) {
      stopwatch.stop();
      logError('Measure', '$name failed after ${stopwatch.elapsedMilliseconds}ms');
      rethrow;
    }
  }
}
