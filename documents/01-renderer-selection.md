# اختيار المحرك المناسب (Renderer Selection)

## المقدمة

اختيار المحرك المناسب هو **أهم قرار** يؤثر على أداء تطبيق Flutter Web. الاختيار الخاطئ يمكن أن يضيف 2-5 ثواني إلى وقت الإقلاع.

## المحركات المتاحة

### 1. HTML Renderer

```
┌─────────────────────────────────────────────────────────────────┐
│                        HTML Renderer                            │
├─────────────────────────────────────────────────────────────────┤
│  الآلية: يستخدم عناصر HTML/CSS/Canvas للرسم                     │
│  الحجم: ~400-600 KB إضافي                                       │
│  وقت التحميل: سريع                                              │
│  التوافق: ممتاز مع جميع المتصفحات                               │
│  جودة الرسم: جيدة (قد تختلف قليلاً عن Native)                   │
└─────────────────────────────────────────────────────────────────┘
```

**المميزات:**
- حجم أصغر بكثير
- تحميل أسرع
- SEO أفضل (محتوى قابل للقراءة)
- أداء جيد على الأجهزة الضعيفة
- لا يحتاج تحميل CanvasKit

**العيوب:**
- قد تكون هناك فروقات بصرية طفيفة
- بعض التأثيرات المتقدمة قد لا تعمل بشكل مثالي
- أداء أقل في الرسوميات المعقدة

### 2. CanvasKit Renderer

```
┌─────────────────────────────────────────────────────────────────┐
│                      CanvasKit Renderer                         │
├─────────────────────────────────────────────────────────────────┤
│  الآلية: يستخدم Skia/WebGL للرسم                                │
│  الحجم: ~1.5-2 MB إضافي                                         │
│  وقت التحميل: بطيء (يحمّل CanvasKit أولاً)                      │
│  التوافق: جيد (يحتاج WebGL)                                     │
│  جودة الرسم: ممتازة (مطابقة لـ Native)                          │
└─────────────────────────────────────────────────────────────────┘
```

**المميزات:**
- تطابق تام مع Native Flutter
- أداء ممتاز في الرسوميات والـ Animations
- دعم كامل لجميع ميزات Flutter
- نتائج متسقة عبر المتصفحات

**العيوب:**
- حجم كبير (~2 MB إضافي)
- وقت تحميل أولي طويل
- يستهلك موارد أكثر
- قد لا يعمل على متصفحات قديمة

### 3. Auto Renderer (الافتراضي)

```dart
// Flutter يختار تلقائياً بناءً على:
// - نوع الجهاز (Mobile vs Desktop)
// - دعم WebGL
// - حجم الشاشة
```

## جدول المقارنة الشامل

| المعيار | HTML | CanvasKit | Auto |
|---------|------|-----------|------|
| حجم التحميل | 🟢 صغير | 🔴 كبير | 🟡 متغير |
| سرعة الإقلاع | 🟢 سريع | 🔴 بطيء | 🟡 متغير |
| جودة الرسم | 🟡 جيدة | 🟢 ممتازة | 🟢 ممتازة |
| الـ Animations | 🟡 جيدة | 🟢 ممتازة | 🟢 ممتازة |
| Text Rendering | 🟢 ممتاز | 🟢 ممتاز | 🟢 ممتاز |
| SEO | 🟢 جيد | 🔴 ضعيف | 🟡 متغير |
| توافق المتصفحات | 🟢 ممتاز | 🟡 جيد | 🟢 ممتاز |
| استهلاك الذاكرة | 🟢 منخفض | 🔴 عالي | 🟡 متغير |
| الأجهزة الضعيفة | 🟢 جيد | 🔴 ضعيف | 🟡 متغير |

## معايير الاختيار

### اختر HTML Renderer إذا:

```yaml
المعايير:
  - التطبيق يركز على المحتوى النصي
  - الأولوية لسرعة التحميل
  - تحتاج SEO جيد
  - المستخدمون على أجهزة متنوعة (بما فيها الضعيفة)
  - التطبيق بسيط إلى متوسط التعقيد
  - لا تحتاج رسوميات معقدة أو animations ثقيلة

أمثلة التطبيقات:
  - مواقع المحتوى والمدونات
  - لوحات التحكم البسيطة
  - تطبيقات CRUD
  - صفحات الهبوط
  - تطبيقات التجارة الإلكترونية
  - تطبيقات النماذج والاستبيانات
```

### اختر CanvasKit Renderer إذا:

```yaml
المعايير:
  - التطبيق يحتاج رسوميات معقدة
  - تحتاج animations سلسة ومعقدة
  - التطابق التام مع Native مهم
  - المستخدمون على أجهزة قوية
  - التطبيق يستخدم Custom Painting كثيراً
  - تحتاج تأثيرات بصرية متقدمة

أمثلة التطبيقات:
  - تطبيقات الرسم والتصميم
  - الألعاب والتطبيقات التفاعلية
  - تطبيقات الـ Data Visualization المعقدة
  - تطبيقات الـ 3D أو شبه 3D
  - تطبيقات تحرير الصور/الفيديو
```

## طرق التكوين

### الطريقة 1: عبر Build Command

```bash
# استخدام HTML Renderer
flutter build web --web-renderer html

# استخدام CanvasKit Renderer
flutter build web --web-renderer canvaskit

# الاختيار التلقائي (الافتراضي)
flutter build web --web-renderer auto
```

### الطريقة 2: عبر index.html

```html
<!-- web/index.html -->
<!DOCTYPE html>
<html>
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My App</title>
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <script src="flutter.js" defer></script>
  <script>
    window.addEventListener('load', function(ev) {
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: serviceWorkerVersion,
        },
        onEntrypointLoaded: function(engineInitializer) {
          engineInitializer.initializeEngine({
            // تحديد المحرك هنا
            renderer: 'html', // أو 'canvaskit' أو 'auto'
          }).then(function(appRunner) {
            appRunner.runApp();
          });
        }
      });
    });
  </script>
</body>
</html>
```

### الطريقة 3: الاختيار الديناميكي حسب الجهاز

```html
<!-- web/index.html -->
<script>
  window.addEventListener('load', function(ev) {
    // اختيار ذكي بناءً على الجهاز
    function selectRenderer() {
      const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
      const hasWeakGPU = navigator.hardwareConcurrency <= 2;
      const isSlowConnection = navigator.connection && 
                               (navigator.connection.effectiveType === '2g' || 
                                navigator.connection.effectiveType === 'slow-2g');
      
      // استخدم HTML للأجهزة الضعيفة أو الاتصال البطيء
      if (isMobile || hasWeakGPU || isSlowConnection) {
        return 'html';
      }
      return 'canvaskit';
    }

    _flutter.loader.loadEntrypoint({
      serviceWorker: {
        serviceWorkerVersion: serviceWorkerVersion,
      },
      onEntrypointLoaded: function(engineInitializer) {
        engineInitializer.initializeEngine({
          renderer: selectRenderer(),
        }).then(function(appRunner) {
          appRunner.runApp();
        });
      }
    });
  });
</script>
```

### الطريقة 4: اختيار متقدم مع Fallback

```html
<script>
  window.addEventListener('load', function(ev) {
    async function initializeFlutter() {
      const config = await determineOptimalConfig();
      
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: serviceWorkerVersion,
        },
        onEntrypointLoaded: async function(engineInitializer) {
          try {
            const engine = await engineInitializer.initializeEngine({
              renderer: config.renderer,
            });
            await engine.runApp();
          } catch (e) {
            // Fallback إلى HTML إذا فشل CanvasKit
            console.warn('Falling back to HTML renderer:', e);
            const engine = await engineInitializer.initializeEngine({
              renderer: 'html',
            });
            await engine.runApp();
          }
        }
      });
    }

    async function determineOptimalConfig() {
      const config = { renderer: 'html' };
      
      // فحص دعم WebGL
      const canvas = document.createElement('canvas');
      const gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
      
      if (gl) {
        const debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
        if (debugInfo) {
          const renderer = gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL);
          // تجنب CanvasKit على GPUs الضعيفة
          const weakGPUs = ['Intel HD Graphics', 'Mali-4', 'Adreno 3'];
          const isWeakGPU = weakGPUs.some(gpu => renderer.includes(gpu));
          
          if (!isWeakGPU) {
            config.renderer = 'canvaskit';
          }
        }
      }
      
      // فحص سرعة الاتصال
      if (navigator.connection) {
        const { effectiveType, downlink } = navigator.connection;
        if (effectiveType === '4g' && downlink > 5) {
          // اتصال سريع - يمكن استخدام CanvasKit
        } else {
          config.renderer = 'html';
        }
      }
      
      return config;
    }

    initializeFlutter();
  });
</script>
```

## تحسين CanvasKit للسرعة

إذا كنت مضطراً لاستخدام CanvasKit، إليك طرق تسريعه:

### 1. تحميل CanvasKit مسبقاً

```html
<!-- في <head> قبل أي scripts -->
<link rel="preload" href="canvaskit/canvaskit.wasm" as="fetch" crossorigin>
<link rel="preload" href="canvaskit/canvaskit.js" as="script">
```

### 2. استخدام CDN لـ CanvasKit

```html
<script>
  window.addEventListener('load', function(ev) {
    _flutter.loader.loadEntrypoint({
      onEntrypointLoaded: function(engineInitializer) {
        engineInitializer.initializeEngine({
          renderer: 'canvaskit',
          canvasKitBaseUrl: 'https://unpkg.com/canvaskit-wasm@0.39.1/bin/',
        }).then(function(appRunner) {
          appRunner.runApp();
        });
      }
    });
  });
</script>
```

### 3. تخزين CanvasKit محلياً

```javascript
// في Service Worker
const CANVASKIT_CACHE = 'canvaskit-cache-v1';
const CANVASKIT_URLS = [
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CANVASKIT_CACHE).then((cache) => {
      return cache.addAll(CANVASKIT_URLS);
    })
  );
});

self.addEventListener('fetch', (event) => {
  if (CANVASKIT_URLS.some(url => event.request.url.includes(url))) {
    event.respondWith(
      caches.match(event.request).then((response) => {
        return response || fetch(event.request);
      })
    );
  }
});
```

## قياس تأثير المحرك

### سكريبت القياس

```dart
// lib/utils/performance_metrics.dart
import 'dart:html' as html;

class RendererPerformanceMetrics {
  static void measureStartupTime() {
    final performance = html.window.performance;
    final timing = performance.timing;
    
    // وقت التحميل الكلي
    final loadTime = timing.loadEventEnd - timing.navigationStart;
    
    // وقت أول رسم
    final entries = performance.getEntriesByType('paint');
    final fcp = entries.firstWhere(
      (e) => e.name == 'first-contentful-paint',
      orElse: () => null,
    );
    
    print('=== Performance Metrics ===');
    print('Total Load Time: ${loadTime}ms');
    print('First Contentful Paint: ${fcp?.startTime ?? 'N/A'}ms');
    print('Renderer: ${_detectRenderer()}');
  }
  
  static String _detectRenderer() {
    // فحص نوع المحرك المستخدم
    final canvas = html.document.querySelector('flt-glass-pane');
    if (canvas != null) {
      final shadowRoot = canvas.shadowRoot;
      if (shadowRoot != null) {
        final canvasElement = shadowRoot.querySelector('canvas');
        if (canvasElement != null) {
          return 'CanvasKit';
        }
      }
    }
    return 'HTML';
  }
}
```

### جدول نتائج القياس المتوقعة

| السيناريو | HTML | CanvasKit | الفرق |
|-----------|------|-----------|-------|
| التحميل الأولي (3G) | 2.5s | 5.8s | +132% |
| التحميل الأولي (4G) | 1.2s | 3.2s | +167% |
| التحميل الأولي (WiFi) | 0.8s | 2.1s | +163% |
| الزيارة المتكررة (cached) | 0.4s | 0.9s | +125% |
| استهلاك الذاكرة | 45MB | 120MB | +167% |

## أفضل الممارسات

### 1. للتطبيقات التجارية

```yaml
التوصية: HTML Renderer
السبب: الأولوية لسرعة التحميل وتجربة المستخدم
الاستثناء: إذا كان التطبيق يحتاج رسوميات معقدة
```

### 2. للتطبيقات الداخلية

```yaml
التوصية: CanvasKit Renderer
السبب: المستخدمون على شبكة سريعة وأجهزة معروفة
الميزة: تطابق تام مع تطبيقات Mobile
```

### 3. للتطبيقات الهجينة

```yaml
التوصية: Auto مع تحسينات
السبب: دعم مجموعة متنوعة من المستخدمين
التنفيذ: استخدام الاختيار الديناميكي (الطريقة 3)
```

## الأخطاء الشائعة

### ❌ خطأ: استخدام CanvasKit لتطبيق بسيط

```dart
// لا تفعل هذا لتطبيق CRUD بسيط
flutter build web --web-renderer canvaskit
```

### ✅ صحيح: استخدام HTML للتطبيقات البسيطة

```bash
flutter build web --web-renderer html
```

### ❌ خطأ: تجاهل الـ Fallback

```html
<!-- لا تفعل هذا -->
<script>
  engineInitializer.initializeEngine({
    renderer: 'canvaskit', // قد يفشل بدون fallback
  });
</script>
```

### ✅ صحيح: إضافة Fallback

```html
<script>
  try {
    await engineInitializer.initializeEngine({ renderer: 'canvaskit' });
  } catch (e) {
    await engineInitializer.initializeEngine({ renderer: 'html' });
  }
</script>
```

## الخلاصة

| الحالة | التوصية |
|--------|---------|
| 90% من التطبيقات | HTML Renderer |
| تطبيقات الرسوميات | CanvasKit |
| غير متأكد | Auto مع قياس |

**القاعدة الذهبية:** ابدأ بـ HTML، وانتقل إلى CanvasKit فقط إذا كنت تحتاج ميزاته فعلاً.

---

**المرجع السابق:** [00-overview.md](./00-overview.md)
**المرجع التالي:** [02-bundle-optimization.md](./02-bundle-optimization.md)
