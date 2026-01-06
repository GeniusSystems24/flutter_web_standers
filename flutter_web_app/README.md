# Flutter Web Optimized

مشروع Flutter Web محسن وفق أفضل معايير الأداء. يوضح هذا المشروع كيفية تطبيق 14+ معيار لتحسين أداء تطبيقات Flutter Web.

## المعايير المُطبقة

### 1. اختيار المحرك الذكي (Renderer Selection)
**الملف:** `web/index.html`

```javascript
// اختيار تلقائي بناءً على إمكانيات الجهاز
function selectOptimalRenderer() {
  const isMobile = /Android|iPhone|iPad/i.test(navigator.userAgent);
  const hasWeakCPU = navigator.hardwareConcurrency <= 2;
  const isSlowConnection = navigator.connection?.effectiveType === '2g';

  if (isMobile || hasWeakCPU || isSlowConnection) {
    return 'html';  // خفيف وسريع
  }
  return 'canvaskit';  // رسومات غنية
}
```

**كيف يعمل:**
- يفحص نوع الجهاز (موبايل/ديسكتوب)
- يفحص قوة المعالج (عدد الأنوية)
- يفحص سرعة الاتصال
- يفحص دعم WebGL
- يختار HTML للأجهزة الضعيفة و CanvasKit للقوية

---

### 2. تحسين حجم الحزمة (Bundle Optimization)
**الملفات:** `pubspec.yaml`, `analysis_options.yaml`

```yaml
# pubspec.yaml - استيراد Dependencies خفيفة فقط
dependencies:
  http: ^1.1.0        # بدلاً من dio
  provider: ^6.1.0    # خفيف وفعال
```

```yaml
# analysis_options.yaml - قواعد لتقليل الحجم
linter:
  rules:
    - avoid_unnecessary_containers
    - prefer_const_constructors
    - unreachable_from_main
```

**الممارسات:**
- استخدام Dependencies خفيفة
- تجنب barrel files
- استيراد محدد بدلاً من استيراد كامل

---

### 3. التحميل المؤجل (Deferred Loading)
**الملف:** `lib/core/router/app_router.dart`

```dart
// استيراد مؤجل
import 'screens/dashboard_screen.dart' deferred as dashboard;

// تحميل عند الحاجة فقط
_buildDeferredRoute(
  () => dashboard.loadLibrary(),
  () => dashboard.DashboardScreen(),
  routeSettings,
);
```

**كيف يعمل:**
- الصفحات الثانوية تُحمّل عند التنقل إليها
- يقلل حجم الحزمة الأولية
- يُسرّع First Contentful Paint

---

### 4. تحسين الأصول والصور
**الملف:** `lib/core/widgets/optimized_image.dart`

```dart
class OptimizedNetworkImage extends StatelessWidget {
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    return Image.network(
      url,
      // تحديد حجم الكاش بناءً على كثافة البكسل
      cacheWidth: (width * pixelRatio).toInt(),
      cacheHeight: (height * pixelRatio).toInt(),
    );
  }
}
```

**الممارسات:**
- استخدام WebP/AVIF بدلاً من PNG/JPG
- تحديد cacheWidth/cacheHeight
- Lazy loading للصور
- Placeholder أثناء التحميل

---

### 5. تحسين الخطوط
**الملف:** `pubspec.yaml`

```yaml
fonts:
  - family: Cairo
    fonts:
      # الأوزان المستخدمة فقط
      - asset: assets/fonts/Cairo-Regular.woff2
        weight: 400
      - asset: assets/fonts/Cairo-Bold.woff2
        weight: 700
```

**الممارسات:**
- استخدام WOFF2 (أصغر 30%)
- تحميل الأوزان المستخدمة فقط
- Preload للخطوط الحرجة
- font-display: swap

---

### 6. استراتيجيات التخزين المؤقت
**الملفات:** `web/custom_service_worker.js`, `lib/core/cache/memory_cache.dart`

```javascript
// Service Worker - استراتيجيات متعددة
if (isStaticAsset(url)) {
  event.respondWith(cacheFirst(request, STATIC_CACHE));
} else if (isApiRequest(url)) {
  event.respondWith(networkFirst(request, API_CACHE));
} else if (isDynamicAsset(url)) {
  event.respondWith(staleWhileRevalidate(request, DYNAMIC_CACHE));
}
```

```dart
// Memory Cache للـ API
class MemoryCache<T> {
  Future<T> getOrLoad(String key, Future<T> Function() loader) async {
    final cached = get(key);
    if (cached != null) return cached;
    final value = await loader();
    set(key, value);
    return value;
  }
}
```

**الاستراتيجيات:**
| نوع المورد | الاستراتيجية | المدة |
|------------|--------------|-------|
| index.html | No Cache | 0 |
| main.dart.js | Revalidate | 7 أيام |
| الأصول | Immutable | سنة |
| API | Network First | 5 دقائق |
| الصور | Stale While Revalidate | يوم |

---

### 7. تحسين الرسم والتصيير
**الملفات:** `lib/features/home/presentation/screens/home_screen.dart`, `lib/core/constants/app_constants.dart`

```dart
// const widgets قابلة لإعادة الاستخدام
abstract class AppConstants {
  static const smallGap = SizedBox(height: 8);
  static const loadingIndicator = Center(
    child: CircularProgressIndicator(),
  );
}

// تجزئة Widgets
class HomeScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          // Widget منفصل - يُعاد بناؤه بشكل مستقل
          const _ThemeToggleButton(),
        ],
      ),
      body: const RepaintBoundary(
        child: _HomeBody(),  // عزل منطقة الرسم
      ),
    );
  }
}
```

**الممارسات:**
- استخدام `const` حيثما أمكن
- تجزئة Widgets الكبيرة
- استخدام `RepaintBoundary` للعزل
- استخدام `ListView.builder` للقوائم
- تجنب `Opacity` واستخدام `Color.withOpacity`

---

### 8. Tree Shaking
**الملفات:** `analysis_options.yaml`, `scripts/build.sh`

```bash
# أمر البناء المحسن
flutter build web \
  --release \
  --tree-shake-icons \
  --dart-define=ENVIRONMENT=production
```

```dart
// استخدام Icons constants مباشرة (يمكّن tree shaking)
abstract class AppIcons {
  static const home = Icons.home_outlined;
  static const settings = Icons.settings_outlined;
}
```

**الممارسات:**
- تفعيل `--tree-shake-icons`
- تجنب `dynamic` types
- تجنب reflection
- استيراد محدد

---

### 9. تحسين التحميل الأولي
**الملفات:** `web/index.html`, `lib/core/services/initialization_service.dart`

```html
<!-- شاشة انتظار HTML (تظهر فوراً) -->
<div id="splash" class="splash-screen">
  <svg class="splash-logo">...</svg>
  <div class="splash-loader">
    <div id="loader-bar" class="splash-loader-bar"></div>
  </div>
  <p id="splash-status">جاري تحميل التطبيق...</p>
</div>
```

```dart
// تهيئة مرحلية
class InitializationService {
  // المرحلة 1: الحرجة فقط (~200ms)
  static Future<void> initCritical() async {
    await Future.wait([
      _initLocalization(),
      _initTheme(),
      _initAuthState(),
    ]);
  }

  // المرحلة 2: بعد الشاشة الأولى
  static Future<void> initImportant() async { ... }

  // المرحلة 3: في وقت الفراغ
  static Future<void> initBackground() async { ... }
}
```

**الممارسات:**
- شاشة HTML splash (قبل Flutter)
- تهيئة مرحلية (3 مراحل)
- تأجيل التهيئات غير الضرورية
- Preconnect/Preload للموارد

---

### 10. Service Workers
**الملف:** `web/custom_service_worker.js`

```javascript
// تثبيت مع التخزين المسبق
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => {
      return cache.addAll(STATIC_ASSETS);
    })
  );
});

// اعتراض الطلبات
self.addEventListener('fetch', (event) => {
  if (isStaticAsset(url)) {
    event.respondWith(cacheFirst(request, STATIC_CACHE));
  } else if (isApiRequest(url)) {
    event.respondWith(networkFirst(request, API_CACHE));
  }
});
```

**الميزات:**
- تخزين مسبق للملفات الأساسية
- استراتيجيات متعددة للتخزين
- إدارة التحديثات
- صفحة Offline

---

### 11. تحسين الشبكة
**الملف:** `lib/core/services/network_service.dart`

```dart
class OptimizedHttpClient {
  // Circuit Breaker لحماية النظام
  final _circuitBreaker = CircuitBreaker();

  Future<Response> get(String url) async {
    // فحص الكاش أولاً
    final cached = _cache.get('GET:$url');
    if (cached != null) return cached;

    // فحص Circuit Breaker
    if (!_circuitBreaker.canRequest) {
      throw Exception('Circuit breaker is open');
    }

    // الطلب مع إعادة المحاولة
    return _requestWithRetry(() => _client.get(Uri.parse(url)));
  }
}
```

**الميزات:**
- Connection Pooling
- Request Batching
- Circuit Breaker Pattern
- Retry with Exponential Backoff
- تخزين مؤقت للاستجابات

---

### 12. إدارة الحالة المحسنة
**الملفات:** `lib/main.dart`, `lib/features/home/presentation/screens/home_screen.dart`

```dart
// استخدام Selector لقراءة قيمة واحدة
return Selector<ThemeProvider, ThemeMode>(
  selector: (_, provider) => provider.themeMode,
  builder: (context, themeMode, _) {
    return IconButton(
      icon: Icon(themeMode == ThemeMode.dark
          ? Icons.light_mode
          : Icons.dark_mode),
      onPressed: () => context.read<ThemeProvider>().toggleTheme(),
    );
  },
);
```

**الممارسات:**
- استخدام `Selector` بدلاً من `Consumer`
- فصل الـ Providers حسب النطاق
- تجنب إعادة البناء غير الضرورية

---

### 13. أدوات القياس
**الملف:** `lib/core/utils/performance_utils.dart`

```dart
class StartupMetrics {
  static void mark(String name) {
    _timestamps[name] = DateTime.now();
  }

  static void logAll() {
    print('=== Startup Metrics ===');
    _timestamps.forEach((name, time) {
      final duration = time.difference(_timestamps['app_start']!);
      print('$name: ${duration.inMilliseconds}ms');
    });
  }
}

// أهداف Core Web Vitals
abstract class WebVitalsTargets {
  static const lcpGood = Duration(milliseconds: 2500);
  static const fidGood = Duration(milliseconds: 100);
  static const clsGood = 0.1;
}
```

---

### 14. إعدادات البناء المثلى
**الملفات:** `lib/core/config/app_config.dart`, `scripts/build.sh`, `firebase.json`

```dart
// التكوين عبر dart-define
abstract class AppConfig {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static String get apiBaseUrl => switch (environment) {
    'production' => 'https://api.example.com',
    'staging' => 'https://staging-api.example.com',
    _ => 'https://dev-api.example.com',
  };
}
```

```bash
# البناء المحسن
flutter build web \
  --release \
  --web-renderer auto \
  --tree-shake-icons \
  --dart-define=ENVIRONMENT=production
```

---

## هيكل المشروع

```
flutter_web_app/
├── lib/
│   ├── main.dart                 # نقطة الدخول
│   ├── core/
│   │   ├── cache/
│   │   │   └── memory_cache.dart # التخزين المؤقت
│   │   ├── config/
│   │   │   └── app_config.dart   # التكوين
│   │   ├── constants/
│   │   │   └── app_constants.dart # الثوابت
│   │   ├── router/
│   │   │   └── app_router.dart   # التوجيه المؤجل
│   │   ├── services/
│   │   │   ├── initialization_service.dart
│   │   │   ├── network_service.dart
│   │   │   └── update_service.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart    # السمة
│   │   ├── utils/
│   │   │   └── performance_utils.dart
│   │   └── widgets/
│   │       └── optimized_image.dart
│   └── features/
│       ├── home/
│       ├── dashboard/            # تحميل مؤجل
│       └── settings/             # تحميل مؤجل
├── web/
│   ├── index.html               # اختيار المحرك + Splash
│   ├── custom_service_worker.js # التخزين المؤقت
│   ├── manifest.json            # PWA
│   └── offline.html             # صفحة Offline
├── scripts/
│   └── build.sh                 # سكربت البناء
├── firebase.json                # إعدادات الاستضافة
├── analysis_options.yaml        # قواعد التحليل
└── pubspec.yaml                 # Dependencies
```

---

## أوامر البناء

```bash
# تطوير
flutter run -d chrome

# إنتاج (HTML renderer)
./scripts/build.sh html production

# إنتاج (CanvasKit)
./scripts/build.sh canvaskit production

# إنتاج (Auto)
./scripts/build.sh auto production
```

---

## أهداف الأداء

| المقياس | الهدف | الحد الأقصى |
|---------|-------|-------------|
| LCP | < 2.5s | < 4s |
| FID | < 100ms | < 300ms |
| CLS | < 0.1 | < 0.25 |
| Bundle Size | < 1.5MB | < 2MB |
| TTI | < 3.8s | < 7.3s |
| TTFB | < 800ms | < 1.8s |

---

## المراجع

- [01-renderer-selection.md](../documents/01-renderer-selection.md)
- [02-bundle-optimization.md](../documents/02-bundle-optimization.md)
- [03-deferred-loading.md](../documents/03-deferred-loading.md)
- [04-assets-optimization.md](../documents/04-assets-optimization.md)
- [05-fonts-optimization.md](../documents/05-fonts-optimization.md)
- [06-caching-strategies.md](../documents/06-caching-strategies.md)
- [07-rendering-optimization.md](../documents/07-rendering-optimization.md)
- [08-tree-shaking.md](../documents/08-tree-shaking.md)
- [09-initial-load.md](../documents/09-initial-load.md)
- [10-service-workers.md](../documents/10-service-workers.md)
- [11-network-optimization.md](../documents/11-network-optimization.md)
- [12-state-management.md](../documents/12-state-management.md)
- [13-measurement-tools.md](../documents/13-measurement-tools.md)
- [14-build-configuration.md](../documents/14-build-configuration.md)
