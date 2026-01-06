# استراتيجيات التخزين المؤقت (Caching Strategies)

## المقدمة

التخزين المؤقت الفعال يمكن أن يقلل وقت التحميل للزيارات المتكررة بنسبة 70-90%. هذا الملف يغطي جميع استراتيجيات التخزين المؤقت لـ Flutter Web.

## أنواع التخزين المؤقت

```
┌─────────────────────────────────────────────────────────────────┐
│                   طبقات التخزين المؤقت                          │
├─────────────────────────────────────────────────────────────────┤
│  1. Browser Cache (HTTP Cache)                                  │
│     └── يُدار بواسطة رؤوس HTTP                                  │
│                                                                 │
│  2. Service Worker Cache                                        │
│     └── تحكم كامل في التخزين والتحديث                          │
│                                                                 │
│  3. Memory Cache (في التطبيق)                                   │
│     └── تخزين البيانات في الذاكرة                              │
│                                                                 │
│  4. IndexedDB / LocalStorage                                    │
│     └── تخزين دائم للبيانات                                    │
│                                                                 │
│  5. CDN Cache                                                   │
│     └── تخزين على مستوى الشبكة                                 │
└─────────────────────────────────────────────────────────────────┘
```

## HTTP Cache Headers

### 1. تكوين الخادم (Nginx)

```nginx
# /etc/nginx/sites-available/flutter-app.conf

server {
    listen 80;
    server_name example.com;
    root /var/www/flutter-app;
    
    # الملفات الثابتة - تخزين طويل المدى
    location ~* \.(js|css|woff2|woff|ttf|ico|png|jpg|jpeg|gif|svg|webp)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary "Accept-Encoding";
        
        # ضغط Gzip
        gzip on;
        gzip_types text/javascript application/javascript text/css;
    }
    
    # CanvasKit - تخزين طويل جداً
    location /canvaskit/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # main.dart.js - تخزين مع إعادة التحقق
    location = /main.dart.js {
        expires 7d;
        add_header Cache-Control "public, must-revalidate";
        etag on;
    }
    
    # index.html - لا تخزين (للتحديثات الفورية)
    location = /index.html {
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    # flutter.js و Service Worker - تخزين قصير
    location ~* (flutter\.js|flutter_service_worker\.js)$ {
        expires 1h;
        add_header Cache-Control "public, must-revalidate";
    }
    
    # الأصول مع versioning
    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 2. تكوين Apache

```apache
# .htaccess

<IfModule mod_expires.c>
    ExpiresActive On
    
    # الافتراضي
    ExpiresDefault "access plus 1 month"
    
    # HTML
    ExpiresByType text/html "access plus 0 seconds"
    
    # JavaScript
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType text/javascript "access plus 1 year"
    
    # CSS
    ExpiresByType text/css "access plus 1 year"
    
    # الصور
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/webp "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
    
    # الخطوط
    ExpiresByType font/woff2 "access plus 1 year"
    ExpiresByType font/woff "access plus 1 year"
</IfModule>

<IfModule mod_headers.c>
    # main.dart.js
    <FilesMatch "main\.dart\.js$">
        Header set Cache-Control "public, max-age=604800, must-revalidate"
    </FilesMatch>
    
    # index.html
    <FilesMatch "index\.html$">
        Header set Cache-Control "no-cache, no-store, must-revalidate"
        Header set Pragma "no-cache"
        Header set Expires "0"
    </FilesMatch>
</IfModule>
```

### 3. Firebase Hosting

```json
// firebase.json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      },
      {
        "source": "**/*.@(woff2|woff|ttf)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      },
      {
        "source": "**/*.@(png|jpg|jpeg|gif|webp|svg|ico)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      },
      {
        "source": "index.html",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "no-cache, no-store, must-revalidate"
          }
        ]
      },
      {
        "source": "main.dart.js",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=604800, must-revalidate"
          }
        ]
      }
    ]
  }
}
```

## Service Worker المُحسّن

### 1. تكوين Service Worker المخصص

```javascript
// web/custom_service_worker.js

const CACHE_VERSION = 'v1.0.0';
const STATIC_CACHE = `static-${CACHE_VERSION}`;
const DYNAMIC_CACHE = `dynamic-${CACHE_VERSION}`;
const API_CACHE = `api-${CACHE_VERSION}`;

// الملفات الثابتة للتخزين
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/main.dart.js',
  '/flutter.js',
  '/manifest.json',
  '/assets/fonts/Cairo-Regular.woff2',
  '/assets/fonts/Cairo-Bold.woff2',
  '/assets/images/logo.webp',
];

// CanvasKit (إذا مستخدم)
const CANVASKIT_ASSETS = [
  '/canvaskit/canvaskit.js',
  '/canvaskit/canvaskit.wasm',
];

// ===== التثبيت =====
self.addEventListener('install', (event) => {
  console.log('[SW] Installing...');
  
  event.waitUntil(
    Promise.all([
      // تخزين الملفات الثابتة
      caches.open(STATIC_CACHE).then((cache) => {
        return cache.addAll(STATIC_ASSETS);
      }),
      
      // تخزين CanvasKit (اختياري)
      caches.open(STATIC_CACHE).then((cache) => {
        return cache.addAll(CANVASKIT_ASSETS).catch(() => {
          console.log('[SW] CanvasKit not used');
        });
      }),
    ]).then(() => {
      console.log('[SW] Static assets cached');
      return self.skipWaiting();
    })
  );
});

// ===== التفعيل =====
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating...');
  
  event.waitUntil(
    // حذف الـ caches القديمة
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => {
            return name.startsWith('static-') && name !== STATIC_CACHE ||
                   name.startsWith('dynamic-') && name !== DYNAMIC_CACHE ||
                   name.startsWith('api-') && name !== API_CACHE;
          })
          .map((name) => {
            console.log('[SW] Deleting old cache:', name);
            return caches.delete(name);
          })
      );
    }).then(() => {
      return self.clients.claim();
    })
  );
});

// ===== استراتيجيات الـ Fetch =====
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // تجاهل طلبات غير HTTP
  if (!request.url.startsWith('http')) return;
  
  // استراتيجية حسب نوع المورد
  if (isStaticAsset(url)) {
    event.respondWith(cacheFirst(request, STATIC_CACHE));
  } else if (isApiRequest(url)) {
    event.respondWith(networkFirst(request, API_CACHE));
  } else if (isDynamicAsset(url)) {
    event.respondWith(staleWhileRevalidate(request, DYNAMIC_CACHE));
  } else {
    event.respondWith(networkFirst(request, DYNAMIC_CACHE));
  }
});

// ===== دوال المساعدة =====

function isStaticAsset(url) {
  const staticExtensions = ['.js', '.css', '.woff2', '.woff', '.ttf', '.wasm'];
  return staticExtensions.some(ext => url.pathname.endsWith(ext)) ||
         url.pathname.startsWith('/canvaskit/');
}

function isApiRequest(url) {
  return url.pathname.startsWith('/api/') ||
         url.hostname.includes('api.');
}

function isDynamicAsset(url) {
  const dynamicExtensions = ['.png', '.jpg', '.jpeg', '.webp', '.svg', '.gif'];
  return dynamicExtensions.some(ext => url.pathname.endsWith(ext));
}

// ===== استراتيجيات التخزين =====

// Cache First - للملفات الثابتة
async function cacheFirst(request, cacheName) {
  const cachedResponse = await caches.match(request);
  if (cachedResponse) {
    return cachedResponse;
  }
  
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(cacheName);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    return new Response('Offline', { status: 503 });
  }
}

// Network First - للـ API
async function networkFirst(request, cacheName) {
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(cacheName);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    return new Response(JSON.stringify({ error: 'Offline' }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// Stale While Revalidate - للأصول الديناميكية
async function staleWhileRevalidate(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cachedResponse = await cache.match(request);
  
  const fetchPromise = fetch(request).then((networkResponse) => {
    if (networkResponse.ok) {
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  }).catch(() => cachedResponse);
  
  return cachedResponse || fetchPromise;
}

// ===== إدارة التحديثات =====
self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
  }
  
  if (event.data === 'clearCache') {
    event.waitUntil(
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames.map((name) => caches.delete(name))
        );
      })
    );
  }
});
```

### 2. تكامل Service Worker مع Flutter

```html
<!-- web/index.html -->
<script>
  // تسجيل Service Worker مخصص
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', function() {
      navigator.serviceWorker.register('/custom_service_worker.js')
        .then(function(registration) {
          console.log('SW registered:', registration.scope);
          
          // فحص التحديثات
          registration.addEventListener('updatefound', function() {
            const newWorker = registration.installing;
            newWorker.addEventListener('statechange', function() {
              if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                // تحديث متاح
                showUpdateNotification();
              }
            });
          });
        })
        .catch(function(error) {
          console.log('SW registration failed:', error);
        });
    });
  }
  
  function showUpdateNotification() {
    // إظهار إشعار للمستخدم
    if (confirm('تحديث جديد متاح. هل تريد التحديث الآن؟')) {
      navigator.serviceWorker.controller.postMessage('skipWaiting');
      window.location.reload();
    }
  }
</script>
```

### 3. إدارة التحديثات في Flutter

```dart
// lib/core/services/update_service.dart
import 'dart:html' as html;

class UpdateService {
  /// فحص وجود تحديثات
  static Future<bool> checkForUpdates() async {
    final registration = await html.window.navigator.serviceWorker?.ready;
    if (registration == null) return false;
    
    await registration.update();
    return registration.waiting != null;
  }
  
  /// تطبيق التحديث
  static void applyUpdate() {
    html.window.navigator.serviceWorker?.controller?.postMessage('skipWaiting');
    html.window.location.reload();
  }
  
  /// مسح الـ Cache
  static void clearCache() {
    html.window.navigator.serviceWorker?.controller?.postMessage('clearCache');
  }
}
```

## تخزين البيانات في التطبيق

### 1. Memory Cache للـ API

```dart
// lib/core/cache/memory_cache.dart
import 'dart:async';

class MemoryCache<T> {
  final Duration defaultExpiry;
  final int maxSize;
  final Map<String, _CacheEntry<T>> _cache = {};
  
  MemoryCache({
    this.defaultExpiry = const Duration(minutes: 5),
    this.maxSize = 100,
  });
  
  /// تخزين قيمة
  void set(String key, T value, {Duration? expiry}) {
    _ensureCapacity();
    _cache[key] = _CacheEntry(
      value: value,
      expiry: DateTime.now().add(expiry ?? defaultExpiry),
    );
  }
  
  /// الحصول على قيمة
  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value;
  }
  
  /// الحصول أو التحميل
  Future<T> getOrLoad(
    String key,
    Future<T> Function() loader, {
    Duration? expiry,
  }) async {
    final cached = get(key);
    if (cached != null) return cached;
    
    final value = await loader();
    set(key, value, expiry: expiry);
    return value;
  }
  
  /// حذف قيمة
  void remove(String key) => _cache.remove(key);
  
  /// مسح كل الـ cache
  void clear() => _cache.clear();
  
  /// التأكد من السعة
  void _ensureCapacity() {
    if (_cache.length >= maxSize) {
      // حذف أقدم العناصر
      final sortedKeys = _cache.keys.toList()
        ..sort((a, b) => _cache[a]!.expiry.compareTo(_cache[b]!.expiry));
      
      for (var i = 0; i < maxSize ~/ 4; i++) {
        _cache.remove(sortedKeys[i]);
      }
    }
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiry;
  
  _CacheEntry({required this.value, required this.expiry});
  
  bool get isExpired => DateTime.now().isAfter(expiry);
}
```

### 2. استخدام Memory Cache مع API

```dart
// lib/core/services/api_service.dart
import 'package:dio/dio.dart';
import '../cache/memory_cache.dart';

class ApiService {
  final Dio _dio;
  final MemoryCache<dynamic> _cache = MemoryCache(
    defaultExpiry: const Duration(minutes: 5),
    maxSize: 50,
  );
  
  ApiService(this._dio);
  
  /// GET مع تخزين مؤقت
  Future<T> getCached<T>(
    String path, {
    Duration? cacheExpiry,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'GET:$path';
    
    if (!forceRefresh) {
      final cached = _cache.get(cacheKey);
      if (cached != null) return cached as T;
    }
    
    final response = await _dio.get(path);
    _cache.set(cacheKey, response.data, expiry: cacheExpiry);
    
    return response.data as T;
  }
  
  /// POST يُبطل الـ cache
  Future<T> post<T>(String path, dynamic data) async {
    final response = await _dio.post(path, data: data);
    
    // إبطال الـ cache المرتبط
    _invalidateRelatedCache(path);
    
    return response.data as T;
  }
  
  void _invalidateRelatedCache(String path) {
    // إبطال الـ cache للـ GET المرتبط
    _cache.remove('GET:$path');
    _cache.remove('GET:${path.split('/').take(2).join('/')}');
  }
}
```

### 3. IndexedDB للتخزين الدائم

```dart
// lib/core/cache/indexed_db_cache.dart
import 'dart:html' as html;
import 'dart:indexed_db' as idb;
import 'dart:convert';

class IndexedDBCache {
  static const String _dbName = 'flutter_cache';
  static const String _storeName = 'cache_store';
  static const int _dbVersion = 1;
  
  idb.Database? _db;
  
  Future<void> init() async {
    _db = await html.window.indexedDB!.open(
      _dbName,
      version: _dbVersion,
      onUpgradeNeeded: (event) {
        final db = event.target.result as idb.Database;
        if (!db.objectStoreNames!.contains(_storeName)) {
          db.createObjectStore(_storeName, keyPath: 'key');
        }
      },
    );
  }
  
  Future<void> set(String key, dynamic value, {Duration? expiry}) async {
    final store = _db!.transaction(_storeName, 'readwrite').objectStore(_storeName);
    
    await store.put({
      'key': key,
      'value': jsonEncode(value),
      'expiry': expiry != null 
          ? DateTime.now().add(expiry).millisecondsSinceEpoch
          : null,
    });
  }
  
  Future<T?> get<T>(String key) async {
    final store = _db!.transaction(_storeName, 'readonly').objectStore(_storeName);
    final result = await store.getObject(key);
    
    if (result == null) return null;
    
    final data = result as Map;
    final expiryMs = data['expiry'] as int?;
    
    if (expiryMs != null && DateTime.now().millisecondsSinceEpoch > expiryMs) {
      await remove(key);
      return null;
    }
    
    return jsonDecode(data['value'] as String) as T;
  }
  
  Future<void> remove(String key) async {
    final store = _db!.transaction(_storeName, 'readwrite').objectStore(_storeName);
    await store.delete(key);
  }
  
  Future<void> clear() async {
    final store = _db!.transaction(_storeName, 'readwrite').objectStore(_storeName);
    await store.clear();
  }
}
```

## استراتيجيات التخزين المؤقت

### 1. جدول الاستراتيجيات

| نوع المورد | الاستراتيجية | مدة التخزين | السبب |
|------------|--------------|-------------|-------|
| index.html | No Cache | 0 | للتحديثات الفورية |
| main.dart.js | Revalidate | 7 أيام | تغييرات متكررة |
| *.part.js | Immutable | 1 سنة | versioned |
| الأصول | Immutable | 1 سنة | نادراً تتغير |
| الخطوط | Immutable | 1 سنة | ثابتة |
| API | Network First | 5 دقائق | بيانات حية |
| الصور | Stale While Revalidate | 1 يوم | توازن |

### 2. تنفيذ الاستراتيجيات

```dart
// lib/core/cache/cache_strategy.dart

enum CacheStrategy {
  /// Cache First - للملفات الثابتة
  cacheFirst,
  
  /// Network First - للـ API
  networkFirst,
  
  /// Stale While Revalidate - للصور
  staleWhileRevalidate,
  
  /// Network Only - للبيانات الحساسة
  networkOnly,
  
  /// Cache Only - للوضع Offline
  cacheOnly,
}

class CacheConfig {
  final CacheStrategy strategy;
  final Duration? expiry;
  final bool persistToDisk;
  
  const CacheConfig({
    required this.strategy,
    this.expiry,
    this.persistToDisk = false,
  });
  
  // تكوينات مُعدة مسبقاً
  static const api = CacheConfig(
    strategy: CacheStrategy.networkFirst,
    expiry: Duration(minutes: 5),
  );
  
  static const images = CacheConfig(
    strategy: CacheStrategy.staleWhileRevalidate,
    expiry: Duration(days: 1),
    persistToDisk: true,
  );
  
  static const staticAssets = CacheConfig(
    strategy: CacheStrategy.cacheFirst,
    expiry: Duration(days: 365),
    persistToDisk: true,
  );
}
```

## قياس فعالية التخزين المؤقت

```dart
// lib/core/utils/cache_metrics.dart
import 'dart:html' as html;

class CacheMetrics {
  static int _hits = 0;
  static int _misses = 0;
  
  static void recordHit() => _hits++;
  static void recordMiss() => _misses++;
  
  static double get hitRate => 
      _hits + _misses > 0 ? _hits / (_hits + _misses) : 0;
  
  static Map<String, dynamic> getStorageInfo() {
    return {
      'cacheHits': _hits,
      'cacheMisses': _misses,
      'hitRate': '${(hitRate * 100).toStringAsFixed(1)}%',
      'localStorage': _getStorageSize('localStorage'),
      'sessionStorage': _getStorageSize('sessionStorage'),
    };
  }
  
  static int _getStorageSize(String type) {
    try {
      final storage = type == 'localStorage' 
          ? html.window.localStorage 
          : html.window.sessionStorage;
      
      int totalSize = 0;
      storage.forEach((key, value) {
        totalSize += key.length + value.length;
      });
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
  
  static void printMetrics() {
    final info = getStorageInfo();
    print('=== Cache Metrics ===');
    info.forEach((key, value) {
      print('$key: $value');
    });
  }
}
```

## قائمة المراجعة

```markdown
## Caching Checklist

### HTTP Cache
- [ ] تكوين Cache-Control headers
- [ ] index.html بدون تخزين
- [ ] الأصول الثابتة: immutable, 1 year
- [ ] main.dart.js: revalidate

### Service Worker
- [ ] تخصيص Service Worker
- [ ] استراتيجية Cache First للثابت
- [ ] استراتيجية Network First للـ API
- [ ] إدارة التحديثات

### Application Cache
- [ ] Memory Cache للـ API
- [ ] IndexedDB للبيانات الكبيرة
- [ ] تنظيف الـ Cache المنتهي

### القياس
- [ ] قياس Cache Hit Rate
- [ ] مراقبة حجم التخزين
- [ ] اختبار الوضع Offline
```

---

**المرجع السابق:** [05-fonts-optimization.md](./05-fonts-optimization.md)
**المرجع التالي:** [07-rendering-optimization.md](./07-rendering-optimization.md)
