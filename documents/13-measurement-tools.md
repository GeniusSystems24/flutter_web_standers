# أدوات القياس والمراقبة (Measurement Tools)

## المقدمة

"ما لا يمكن قياسه لا يمكن تحسينه" - هذا المبدأ أساسي في تحسين الأداء. هذا الملف يغطي أدوات وتقنيات قياس أداء Flutter Web.

## Core Web Vitals

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Core Web Vitals المستهدفة                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  LCP (Largest Contentful Paint)                                            │
│  ├── جيد: < 2.5s                                                           │
│  ├── يحتاج تحسين: 2.5s - 4s                                                │
│  └── ضعيف: > 4s                                                            │
│                                                                             │
│  FID (First Input Delay)                                                   │
│  ├── جيد: < 100ms                                                          │
│  ├── يحتاج تحسين: 100ms - 300ms                                            │
│  └── ضعيف: > 300ms                                                         │
│                                                                             │
│  CLS (Cumulative Layout Shift)                                             │
│  ├── جيد: < 0.1                                                            │
│  ├── يحتاج تحسين: 0.1 - 0.25                                               │
│  └── ضعيف: > 0.25                                                          │
│                                                                             │
│  INP (Interaction to Next Paint) - جديد                                    │
│  ├── جيد: < 200ms                                                          │
│  ├── يحتاج تحسين: 200ms - 500ms                                            │
│  └── ضعيف: > 500ms                                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Lighthouse

### التشغيل من سطر الأوامر

```bash
# تثبيت Lighthouse
npm install -g lighthouse

# تشغيل تحليل كامل
lighthouse https://myapp.com --output html --output-path ./report.html

# تشغيل للأداء فقط
lighthouse https://myapp.com --only-categories=performance

# محاكاة جوال بطيء
lighthouse https://myapp.com \
  --throttling-method=simulate \
  --throttling.cpuSlowdownMultiplier=4

# مع إعدادات مخصصة
lighthouse https://myapp.com \
  --chrome-flags="--headless" \
  --preset=desktop \
  --output json \
  --output-path ./lighthouse-report.json
```

### تشغيل برمجياً

```javascript
// lighthouse-runner.js
const lighthouse = require('lighthouse');
const chromeLauncher = require('chrome-launcher');
const fs = require('fs');

async function runLighthouse(url) {
  const chrome = await chromeLauncher.launch({
    chromeFlags: ['--headless']
  });

  const options = {
    logLevel: 'info',
    output: 'json',
    port: chrome.port,
    onlyCategories: ['performance'],
  };

  const runnerResult = await lighthouse(url, options);
  
  // حفظ التقرير
  fs.writeFileSync(
    'lighthouse-report.json',
    JSON.stringify(runnerResult.lhr, null, 2)
  );

  // طباعة النتائج
  console.log('Performance score:', runnerResult.lhr.categories.performance.score * 100);
  console.log('FCP:', runnerResult.lhr.audits['first-contentful-paint'].displayValue);
  console.log('LCP:', runnerResult.lhr.audits['largest-contentful-paint'].displayValue);
  console.log('TTI:', runnerResult.lhr.audits['interactive'].displayValue);
  console.log('TBT:', runnerResult.lhr.audits['total-blocking-time'].displayValue);
  console.log('CLS:', runnerResult.lhr.audits['cumulative-layout-shift'].displayValue);

  await chrome.kill();
}

runLighthouse('https://myapp.com');
```

### CI/CD Integration

```yaml
# .github/workflows/lighthouse.yml
name: Lighthouse CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build
        run: flutter build web --release
      
      - name: Run Lighthouse
        uses: treosh/lighthouse-ci-action@v10
        with:
          urls: |
            https://myapp.com
            https://myapp.com/products
          budgetPath: ./lighthouse-budget.json
          uploadArtifacts: true
          temporaryPublicStorage: true
      
      - name: Check scores
        run: |
          if [ $(cat .lighthouseci/lhr-*.json | jq '.categories.performance.score') -lt 0.9 ]; then
            echo "Performance score below 90%"
            exit 1
          fi
```

### Lighthouse Budget

```json
// lighthouse-budget.json
[
  {
    "path": "/*",
    "timings": [
      {
        "metric": "interactive",
        "budget": 3000
      },
      {
        "metric": "first-contentful-paint",
        "budget": 1800
      },
      {
        "metric": "largest-contentful-paint",
        "budget": 2500
      }
    ],
    "resourceSizes": [
      {
        "resourceType": "script",
        "budget": 500
      },
      {
        "resourceType": "total",
        "budget": 2000
      },
      {
        "resourceType": "image",
        "budget": 500
      }
    ],
    "resourceCounts": [
      {
        "resourceType": "third-party",
        "budget": 5
      }
    ]
  }
]
```

## Chrome DevTools

### Performance Panel

```dart
// قياس أداء Widget معين
class ProfiledWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // في DevTools: Performance > Record
    // ابحث عن هذا الـ widget في الـ flamechart
    
    Timeline.startSync('ProfiledWidget.build');
    
    final result = _buildContent(context);
    
    Timeline.finishSync();
    
    return result;
  }

  Widget _buildContent(BuildContext context) {
    return Container(/* ... */);
  }
}
```

### Memory Panel

```dart
// تتبع استخدام الذاكرة
import 'dart:developer';

class MemoryTracker {
  static void takeSnapshot(String label) {
    // يظهر في DevTools > Memory
    debugPrint('Memory snapshot: $label');
    
    // طلب GC
    if (kDebugMode) {
      // Note: لا يمكن طلب GC برمجياً في Flutter Web
      // استخدم DevTools للقياس
    }
  }

  static void trackAllocation(String objectType, int count) {
    Timeline.instantSync('Allocation: $objectType x $count');
  }
}
```

### Network Panel

```javascript
// web/js/network_monitor.js
class NetworkMonitor {
  constructor() {
    this.requests = [];
    this.intercept();
  }

  intercept() {
    const originalFetch = window.fetch;
    
    window.fetch = async (...args) => {
      const start = performance.now();
      const url = args[0];
      
      try {
        const response = await originalFetch(...args);
        
        this.requests.push({
          url,
          duration: performance.now() - start,
          status: response.status,
          size: response.headers.get('content-length'),
        });
        
        return response;
      } catch (error) {
        this.requests.push({
          url,
          duration: performance.now() - start,
          error: error.message,
        });
        throw error;
      }
    };
  }

  getReport() {
    return {
      totalRequests: this.requests.length,
      totalTime: this.requests.reduce((sum, r) => sum + r.duration, 0),
      averageTime: this.requests.reduce((sum, r) => sum + r.duration, 0) / this.requests.length,
      slowestRequests: [...this.requests]
        .sort((a, b) => b.duration - a.duration)
        .slice(0, 5),
    };
  }
}

window.networkMonitor = new NetworkMonitor();
```

## Flutter DevTools

### Performance View

```dart
// تمكين Performance Overlay
MaterialApp(
  showPerformanceOverlay: kDebugMode, // فقط في التطوير
  home: const HomeScreen(),
)

// أو برمجياً
import 'package:flutter/rendering.dart';

void togglePerformanceOverlay() {
  debugPaintSizeEnabled = !debugPaintSizeEnabled;
  debugPaintBaselinesEnabled = !debugPaintBaselinesEnabled;
  debugPaintLayerBordersEnabled = !debugPaintLayerBordersEnabled;
  debugRepaintRainbowEnabled = !debugRepaintRainbowEnabled;
}
```

### Widget Inspector

```dart
// تتبع rebuilds
class RebuildTracker extends StatefulWidget {
  final Widget child;
  final String name;

  const RebuildTracker({
    super.key,
    required this.child,
    required this.name,
  });

  @override
  State<RebuildTracker> createState() => _RebuildTrackerState();
}

class _RebuildTrackerState extends State<RebuildTracker> {
  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    
    if (kDebugMode) {
      debugPrint('${widget.name} rebuilt: $_buildCount times');
    }

    return widget.child;
  }
}
```

## Web Vitals Measurement

### قياس في المتصفح

```javascript
// web/js/web_vitals.js
import { getCLS, getFID, getLCP, getFCP, getTTFB, getINP } from 'web-vitals';

function sendToAnalytics(metric) {
  const body = JSON.stringify({
    name: metric.name,
    value: metric.value,
    rating: metric.rating,
    delta: metric.delta,
    id: metric.id,
    navigationType: metric.navigationType,
  });

  // إرسال للتحليلات
  if (navigator.sendBeacon) {
    navigator.sendBeacon('/analytics/vitals', body);
  } else {
    fetch('/analytics/vitals', { body, method: 'POST', keepalive: true });
  }
  
  // طباعة للتصحيح
  console.log(`[Web Vital] ${metric.name}:`, metric.value, metric.rating);
}

// قياس كل المقاييس
getCLS(sendToAnalytics);
getFID(sendToAnalytics);
getLCP(sendToAnalytics);
getFCP(sendToAnalytics);
getTTFB(sendToAnalytics);
getINP(sendToAnalytics);

// تصدير للاستخدام من Flutter
window.getWebVitals = () => {
  return new Promise((resolve) => {
    const vitals = {};
    let remaining = 6;
    
    const collect = (metric) => {
      vitals[metric.name] = {
        value: metric.value,
        rating: metric.rating,
      };
      remaining--;
      if (remaining === 0) resolve(vitals);
    };
    
    getCLS(collect);
    getFID(collect);
    getLCP(collect);
    getFCP(collect);
    getTTFB(collect);
    getINP(collect);
    
    // Timeout بعد 10 ثواني
    setTimeout(() => resolve(vitals), 10000);
  });
};
```

### قياس من Flutter

```dart
// lib/core/analytics/web_vitals_service.dart
import 'dart:js' as js;

class WebVitalsService {
  /// جلب Web Vitals الحالية
  static Future<Map<String, dynamic>> getVitals() async {
    try {
      final result = await js.context.callMethod('getWebVitals');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {};
    }
  }

  /// إرسال للتحليلات
  static void reportVitals() {
    getVitals().then((vitals) {
      for (final entry in vitals.entries) {
        Analytics.logEvent(
          name: 'web_vital',
          parameters: {
            'metric': entry.key,
            'value': entry.value['value'],
            'rating': entry.value['rating'],
          },
        );
      }
    });
  }
}
```

## Bundle Size Analysis

### Flutter Analyze Size

```bash
# تحليل حجم الحزمة
flutter build web --release --source-maps

# تحليل تفصيلي
flutter build web --analyze-size

# النتيجة تظهر في DevTools
```

### Source Map Explorer

```bash
# تثبيت
npm install -g source-map-explorer

# تحليل
source-map-explorer build/web/main.dart.js.map

# مع HTML report
source-map-explorer build/web/main.dart.js.map --html report.html
```

### Webpack Bundle Analyzer

```bash
# إذا كنت تستخدم build مخصص
npm install -g webpack-bundle-analyzer

webpack-bundle-analyzer build/web/stats.json
```

### تحليل مخصص

```dart
// tools/analyze_bundle.dart
import 'dart:io';
import 'dart:convert';

void main() async {
  final webDir = Directory('build/web');
  
  final files = await webDir
      .list(recursive: true)
      .where((e) => e is File)
      .cast<File>()
      .toList();

  final analysis = <String, int>{};
  int totalSize = 0;

  for (final file in files) {
    final size = await file.length();
    final ext = file.path.split('.').last;
    
    analysis[ext] = (analysis[ext] ?? 0) + size;
    totalSize += size;
  }

  print('=== Bundle Analysis ===');
  print('Total size: ${_formatSize(totalSize)}');
  print('\nBy extension:');
  
  final sorted = analysis.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  for (final entry in sorted) {
    final percent = (entry.value / totalSize * 100).toStringAsFixed(1);
    print('  .${entry.key}: ${_formatSize(entry.value)} ($percent%)');
  }

  // أكبر الملفات
  print('\nLargest files:');
  final largeFiles = files.toList()
    ..sort((a, b) => b.lengthSync().compareTo(a.lengthSync()));
  
  for (final file in largeFiles.take(10)) {
    final size = await file.length();
    print('  ${file.path}: ${_formatSize(size)}');
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
}
```

## Custom Performance Metrics

### Performance Observer

```dart
// lib/core/performance/performance_observer.dart
import 'dart:html' as html;

class PerformanceObserverService {
  static void init() {
    // مراقبة Long Tasks
    _observeLongTasks();
    
    // مراقبة Paint Timing
    _observePaintTiming();
    
    // مراقبة Resource Timing
    _observeResourceTiming();
  }

  static void _observeLongTasks() {
    final observer = html.PerformanceObserver((list, _) {
      for (final entry in list.getEntries()) {
        if (entry.duration > 50) {
          print('Long task detected: ${entry.duration}ms');
          Analytics.logEvent(
            name: 'long_task',
            parameters: {'duration': entry.duration},
          );
        }
      }
    });
    
    observer.observe(entryTypes: ['longtask']);
  }

  static void _observePaintTiming() {
    final observer = html.PerformanceObserver((list, _) {
      for (final entry in list.getEntries()) {
        print('Paint: ${entry.name} at ${entry.startTime}ms');
        
        if (entry.name == 'first-contentful-paint') {
          Analytics.logEvent(
            name: 'fcp',
            parameters: {'value': entry.startTime},
          );
        }
      }
    });
    
    observer.observe(entryTypes: ['paint']);
  }

  static void _observeResourceTiming() {
    final observer = html.PerformanceObserver((list, _) {
      for (final entry in list.getEntries()) {
        final resource = entry as html.PerformanceResourceTiming;
        
        if (resource.duration > 1000) {
          print('Slow resource: ${resource.name} (${resource.duration}ms)');
        }
      }
    });
    
    observer.observe(entryTypes: ['resource']);
  }
}
```

### Custom Timing Marks

```dart
// lib/core/performance/timing_service.dart
import 'dart:html' as html;

class TimingService {
  static final _marks = <String, double>{};

  /// بدء قياس
  static void mark(String name) {
    html.window.performance.mark(name);
    _marks[name] = html.window.performance.now();
  }

  /// إنهاء قياس
  static double measure(String name, String startMark) {
    final endMark = '${name}_end';
    html.window.performance.mark(endMark);
    
    html.window.performance.measure(name, startMark, endMark);
    
    final duration = html.window.performance.now() - (_marks[startMark] ?? 0);
    
    return duration;
  }

  /// قياس عملية
  static Future<T> measureAsync<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    mark('${name}_start');
    
    try {
      return await operation();
    } finally {
      final duration = measure(name, '${name}_start');
      print('$name: ${duration.toStringAsFixed(2)}ms');
      
      Analytics.logEvent(
        name: 'timing',
        parameters: {
          'operation': name,
          'duration': duration,
        },
      );
    }
  }

  /// مسح القياسات
  static void clear() {
    html.window.performance.clearMarks();
    html.window.performance.clearMeasures();
    _marks.clear();
  }

  /// تقرير كامل
  static Map<String, dynamic> getReport() {
    final entries = html.window.performance.getEntriesByType('measure');
    
    return {
      'measures': entries.map((e) => {
        return {
          'name': e.name,
          'duration': e.duration,
          'startTime': e.startTime,
        };
      }).toList(),
      'navigation': _getNavigationTiming(),
    };
  }

  static Map<String, dynamic> _getNavigationTiming() {
    final nav = html.window.performance.getEntriesByType('navigation').first
        as html.PerformanceNavigationTiming;
    
    return {
      'dns': nav.domainLookupEnd - nav.domainLookupStart,
      'tcp': nav.connectEnd - nav.connectStart,
      'ttfb': nav.responseStart - nav.requestStart,
      'download': nav.responseEnd - nav.responseStart,
      'domInteractive': nav.domInteractive,
      'domComplete': nav.domComplete,
      'loadComplete': nav.loadEventEnd,
    };
  }
}
```

## Real User Monitoring (RUM)

### جمع البيانات

```dart
// lib/core/monitoring/rum_service.dart
class RUMService {
  static final _metrics = <Map<String, dynamic>>[];
  static Timer? _flushTimer;

  static void init() {
    // إرسال كل 30 ثانية
    _flushTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => flush(),
    );

    // إرسال عند إغلاق الصفحة
    html.window.onBeforeUnload.listen((_) => flush());
  }

  static void recordMetric({
    required String name,
    required double value,
    Map<String, dynamic>? attributes,
  }) {
    _metrics.add({
      'name': name,
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
      'url': html.window.location.href,
      'userAgent': html.window.navigator.userAgent,
      ...?attributes,
    });
  }

  static void recordNavigation(String routeName, Duration loadTime) {
    recordMetric(
      name: 'navigation',
      value: loadTime.inMilliseconds.toDouble(),
      attributes: {'route': routeName},
    );
  }

  static void recordInteraction(String element, Duration responseTime) {
    recordMetric(
      name: 'interaction',
      value: responseTime.inMilliseconds.toDouble(),
      attributes: {'element': element},
    );
  }

  static void recordError(String error, String? stackTrace) {
    recordMetric(
      name: 'error',
      value: 1,
      attributes: {
        'error': error,
        'stackTrace': stackTrace,
      },
    );
  }

  static Future<void> flush() async {
    if (_metrics.isEmpty) return;

    final batch = List<Map<String, dynamic>>.from(_metrics);
    _metrics.clear();

    try {
      await http.post(
        Uri.parse('/api/rum'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(batch),
      );
    } catch (e) {
      // إعادة المحاولة لاحقاً
      _metrics.addAll(batch);
    }
  }

  static void dispose() {
    _flushTimer?.cancel();
    flush();
  }
}
```

### Dashboard للمراقبة

```dart
// lib/features/admin/presentation/screens/performance_dashboard.dart
class PerformanceDashboard extends StatelessWidget {
  const PerformanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performance Dashboard')),
      body: FutureBuilder<PerformanceData>(
        future: _fetchPerformanceData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWebVitalsCard(data.webVitals),
                const SizedBox(height: 16),
                _buildLoadTimesChart(data.loadTimes),
                const SizedBox(height: 16),
                _buildErrorsCard(data.errors),
                const SizedBox(height: 16),
                _buildSlowPagesTable(data.slowPages),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebVitalsCard(WebVitals vitals) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Core Web Vitals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildVitalIndicator('LCP', vitals.lcp, 2500, 4000),
                _buildVitalIndicator('FID', vitals.fid, 100, 300),
                _buildVitalIndicator('CLS', vitals.cls * 1000, 100, 250),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalIndicator(
    String name,
    double value,
    double good,
    double poor,
  ) {
    Color color;
    String rating;
    
    if (value <= good) {
      color = Colors.green;
      rating = 'جيد';
    } else if (value <= poor) {
      color = Colors.orange;
      rating = 'متوسط';
    } else {
      color = Colors.red;
      rating = 'ضعيف';
    }

    return Column(
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        CircularProgressIndicator(
          value: (value / poor).clamp(0, 1),
          color: color,
        ),
        const SizedBox(height: 8),
        Text('${value.toStringAsFixed(0)}ms'),
        Text(rating, style: TextStyle(color: color)),
      ],
    );
  }
}
```

## Automated Testing

### Performance Tests

```dart
// test/performance/startup_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App startup time', (tester) async {
    final stopwatch = Stopwatch()..start();
    
    await tester.pumpWidget(const MyApp());
    
    // انتظار الشاشة الأولى
    await tester.pumpAndSettle();
    
    stopwatch.stop();
    
    // التحقق من الوقت
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(3000),
      reason: 'Startup should be under 3 seconds',
    );
    
    // تسجيل للتقارير
    binding.reportData = <String, dynamic>{
      'startup_time': stopwatch.elapsedMilliseconds,
    };
  });

  testWidgets('Navigation performance', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final stopwatch = Stopwatch()..start();
    
    // التنقل
    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();
    
    stopwatch.stop();

    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(500),
      reason: 'Navigation should be under 500ms',
    );
  });

  testWidgets('Scroll performance', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // التمرير
    final listFinder = find.byType(ListView);
    
    for (int i = 0; i < 10; i++) {
      await tester.fling(listFinder, const Offset(0, -500), 1000);
      await tester.pumpAndSettle();
    }

    // التحقق من عدم وجود jank
    // (يتم قياسه تلقائياً بواسطة Flutter)
  });
}
```

### Benchmark Tests

```dart
// test/benchmark/widget_benchmark.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget Benchmarks', () {
    testWidgets('ProductCard build time', (tester) async {
      final times = <int>[];
      
      for (int i = 0; i < 100; i++) {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          MaterialApp(
            home: ProductCard(
              product: Product(
                id: 'test',
                name: 'Test Product',
                price: 99.99,
              ),
            ),
          ),
        );
        
        stopwatch.stop();
        times.add(stopwatch.elapsedMicroseconds);
        
        await tester.pumpWidget(const SizedBox.shrink());
      }

      final average = times.reduce((a, b) => a + b) / times.length;
      final max = times.reduce((a, b) => a > b ? a : b);
      
      print('ProductCard build: avg=${average}μs, max=${max}μs');
      
      expect(average, lessThan(1000)); // أقل من 1ms
    });
  });
}
```

## قائمة المراجعة

### القياس الأولي
- [ ] قياس Lighthouse score
- [ ] قياس Core Web Vitals
- [ ] تحليل حجم الحزمة
- [ ] قياس وقت التحميل الأولي

### المراقبة المستمرة
- [ ] RUM للمستخدمين الحقيقيين
- [ ] تنبيهات للأداء المنخفض
- [ ] Dashboard للمراقبة
- [ ] تقارير دورية

### الاختبار
- [ ] اختبارات أداء تلقائية
- [ ] CI/CD مع حدود للأداء
- [ ] Benchmark tests للـ widgets

### التحليل
- [ ] تحديد عنق الزجاجة
- [ ] مقارنة قبل/بعد
- [ ] تتبع التحسن بمرور الوقت

## الأدوات الموصى بها

| الأداة | الغرض | الرابط |
|--------|-------|--------|
| Lighthouse | قياس شامل | مدمج في Chrome |
| PageSpeed Insights | قياس عام | web.dev/measure |
| WebPageTest | تحليل معمق | webpagetest.org |
| GTmetrix | تقارير مفصلة | gtmetrix.com |
| source-map-explorer | تحليل الحزمة | npm |
| Flutter DevTools | تصحيح Flutter | مدمج |

---

**المرجع السابق:** [12-state-management.md](./12-state-management.md) - تحسين إدارة الحالة
**المرجع التالي:** [14-build-configuration.md](./14-build-configuration.md) - إعدادات البناء المثلى
