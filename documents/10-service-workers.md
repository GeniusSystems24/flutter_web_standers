# تكوين Service Workers

## المقدمة

Service Workers هي نصوص JavaScript تعمل في الخلفية وتتحكم في طلبات الشبكة. في Flutter Web، تلعب دوراً حاسماً في التخزين المؤقت وتمكين العمل بدون اتصال وتحسين الأداء.

## فهم Service Workers في Flutter Web

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    كيف يعمل Service Worker                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   المتصفح ◄──────► Service Worker ◄──────► الشبكة                           │
│      │                   │                    │                             │
│      │                   ▼                    │                             │
│      │              ┌─────────┐               │                             │
│      │              │  Cache  │               │                             │
│      │              └─────────┘               │                             │
│      │                   │                    │                             │
│      ▼                   ▼                    ▼                             │
│  ┌────────┐        ┌──────────┐        ┌──────────┐                         │
│  │ العرض  │◄───────│ الاستجابة│◄───────│ الخادم  │                         │
│  └────────┘        └──────────┘        └──────────┘                         │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  الاستراتيجيات:                                                              │
│  • Cache First: الكاش أولاً، ثم الشبكة إذا لزم                               │
│  • Network First: الشبكة أولاً، ثم الكاش كاحتياط                             │
│  • Stale While Revalidate: الكاش فوراً + تحديث في الخلفية                   │
│  • Network Only: الشبكة فقط                                                 │
│  • Cache Only: الكاش فقط                                                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Service Worker الافتراضي في Flutter

### الملف الافتراضي

```javascript
// web/flutter_service_worker.js (يُنشأ تلقائياً)
// هذا الملف يُدار بواسطة Flutter ولا يُعدل مباشرة
```

### تفعيل في index.html

```html
<!-- web/index.html -->
<script>
  var serviceWorkerVersion = '{{flutter_service_worker_version}}';
</script>
<script src="flutter.js" defer></script>
<script>
  window.addEventListener('load', function(ev) {
    _flutter.loader.loadEntrypoint({
      serviceWorker: {
        serviceWorkerVersion: serviceWorkerVersion,
      },
      onEntrypointLoaded: function(engineInitializer) {
        engineInitializer.initializeEngine().then(function(appRunner) {
          appRunner.runApp();
        });
      }
    });
  });
</script>
```

## Service Worker مخصص

### التكوين الأساسي

```javascript
// web/custom_service_worker.js
const CACHE_NAME = 'my-app-cache-v1';
const RUNTIME_CACHE = 'my-app-runtime-v1';

// الملفات الأساسية للتخزين المؤقت
const PRECACHE_URLS = [
  '/',
  '/index.html',
  '/main.dart.js',
  '/flutter.js',
  '/manifest.json',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/assets/AssetManifest.json',
  '/assets/FontManifest.json',
];

// تثبيت Service Worker
self.addEventListener('install', (event) => {
  console.log('[SW] Installing...');
  
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('[SW] Precaching app shell');
        return cache.addAll(PRECACHE_URLS);
      })
      .then(() => {
        // التفعيل الفوري بدون انتظار
        return self.skipWaiting();
      })
  );
});

// تفعيل Service Worker
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating...');
  
  event.waitUntil(
    Promise.all([
      // حذف الكاش القديم
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((name) => name !== CACHE_NAME && name !== RUNTIME_CACHE)
            .map((name) => {
              console.log('[SW] Deleting old cache:', name);
              return caches.delete(name);
            })
        );
      }),
      // السيطرة على جميع العملاء فوراً
      self.clients.claim(),
    ])
  );
});

// اعتراض الطلبات
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  
  // تجاهل طلبات غير HTTP
  if (!event.request.url.startsWith('http')) {
    return;
  }
  
  // استراتيجية مختلفة حسب نوع المورد
  if (isPrecachedResource(url)) {
    event.respondWith(cacheFirst(event.request));
  } else if (isApiRequest(url)) {
    event.respondWith(networkFirst(event.request));
  } else if (isStaticAsset(url)) {
    event.respondWith(staleWhileRevalidate(event.request));
  } else {
    event.respondWith(networkFirst(event.request));
  }
});

// === استراتيجيات التخزين المؤقت ===

// Cache First: الكاش أولاً
async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) {
    return cached;
  }
  
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    return new Response('Offline', { status: 503 });
  }
}

// Network First: الشبكة أولاً
async function networkFirst(request) {
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(RUNTIME_CACHE);
      cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    const cached = await caches.match(request);
    if (cached) {
      return cached;
    }
    return new Response('Offline', { status: 503 });
  }
}

// Stale While Revalidate
async function staleWhileRevalidate(request) {
  const cache = await caches.open(RUNTIME_CACHE);
  const cached = await cache.match(request);
  
  const fetchPromise = fetch(request).then((response) => {
    if (response.ok) {
      cache.put(request, response.clone());
    }
    return response;
  });
  
  return cached || fetchPromise;
}

// === وظائف مساعدة ===

function isPrecachedResource(url) {
  return PRECACHE_URLS.some((path) => url.pathname === path || url.pathname.endsWith(path));
}

function isApiRequest(url) {
  return url.pathname.startsWith('/api/') || url.host.includes('api.');
}

function isStaticAsset(url) {
  return /\.(png|jpg|jpeg|gif|webp|svg|woff2|woff|ttf|css|js)$/i.test(url.pathname);
}
```

### تسجيل Service Worker المخصص

```html
<!-- web/index.html -->
<script>
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', async () => {
      try {
        const registration = await navigator.serviceWorker.register(
          '/custom_service_worker.js',
          { scope: '/' }
        );
        
        console.log('SW registered:', registration.scope);
        
        // التحقق من التحديثات
        registration.addEventListener('updatefound', () => {
          const newWorker = registration.installing;
          newWorker.addEventListener('statechange', () => {
            if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
              // تحديث متاح
              showUpdateNotification();
            }
          });
        });
      } catch (error) {
        console.error('SW registration failed:', error);
      }
    });
  }
  
  function showUpdateNotification() {
    // عرض إشعار للمستخدم
    if (confirm('تحديث جديد متاح. هل تريد التحديث الآن؟')) {
      window.location.reload();
    }
  }
</script>
```

## Workbox لإدارة Service Worker

### تثبيت Workbox

```bash
npm install workbox-cli --save-dev
```

### تكوين Workbox

```javascript
// workbox-config.js
module.exports = {
  globDirectory: 'build/web/',
  globPatterns: [
    '**/*.{js,css,html,png,jpg,jpeg,gif,webp,svg,woff2,woff,ttf,json}'
  ],
  globIgnores: [
    '**/flutter_service_worker.js',
    '**/version.json'
  ],
  swDest: 'build/web/sw.js',
  swSrc: 'web/sw-src.js',
  maximumFileSizeToCacheInBytes: 5 * 1024 * 1024, // 5MB
};
```

### Service Worker مع Workbox

```javascript
// web/sw-src.js
import { precacheAndRoute, cleanupOutdatedCaches } from 'workbox-precaching';
import { registerRoute, setDefaultHandler } from 'workbox-routing';
import { 
  CacheFirst, 
  NetworkFirst, 
  StaleWhileRevalidate 
} from 'workbox-strategies';
import { ExpirationPlugin } from 'workbox-expiration';
import { CacheableResponsePlugin } from 'workbox-cacheable-response';

// تنظيف الكاش القديم
cleanupOutdatedCaches();

// التخزين المسبق للملفات الأساسية
precacheAndRoute(self.__WB_MANIFEST);

// === استراتيجيات التوجيه ===

// الصور: Cache First مع انتهاء صلاحية
registerRoute(
  ({ request }) => request.destination === 'image',
  new CacheFirst({
    cacheName: 'images-cache',
    plugins: [
      new CacheableResponsePlugin({
        statuses: [0, 200],
      }),
      new ExpirationPlugin({
        maxEntries: 100,
        maxAgeSeconds: 30 * 24 * 60 * 60, // 30 يوم
      }),
    ],
  })
);

// الخطوط: Cache First مع انتهاء صلاحية طويلة
registerRoute(
  ({ request }) => request.destination === 'font',
  new CacheFirst({
    cacheName: 'fonts-cache',
    plugins: [
      new CacheableResponsePlugin({
        statuses: [0, 200],
      }),
      new ExpirationPlugin({
        maxEntries: 20,
        maxAgeSeconds: 365 * 24 * 60 * 60, // سنة
      }),
    ],
  })
);

// JavaScript و CSS: Stale While Revalidate
registerRoute(
  ({ request }) => 
    request.destination === 'script' || 
    request.destination === 'style',
  new StaleWhileRevalidate({
    cacheName: 'static-resources',
    plugins: [
      new CacheableResponsePlugin({
        statuses: [0, 200],
      }),
    ],
  })
);

// طلبات API: Network First
registerRoute(
  ({ url }) => url.pathname.startsWith('/api/'),
  new NetworkFirst({
    cacheName: 'api-cache',
    networkTimeoutSeconds: 10,
    plugins: [
      new CacheableResponsePlugin({
        statuses: [0, 200],
      }),
      new ExpirationPlugin({
        maxEntries: 50,
        maxAgeSeconds: 5 * 60, // 5 دقائق
      }),
    ],
  })
);

// الافتراضي: Network First
setDefaultHandler(
  new NetworkFirst({
    cacheName: 'default-cache',
    networkTimeoutSeconds: 10,
  })
);

// معالجة الطلبات الفاشلة
self.addEventListener('fetch', (event) => {
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() => {
        return caches.match('/offline.html');
      })
    );
  }
});

// رسائل من التطبيق
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});
```

### بناء مع Workbox

```bash
# بعد بناء Flutter
flutter build web --release

# إنشاء Service Worker
npx workbox generateSW workbox-config.js
```

## إدارة التحديثات

### التحقق من التحديثات في Flutter

```dart
// lib/core/services/update_service.dart
import 'dart:html' as html;
import 'dart:js' as js;

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  bool _updateAvailable = false;
  Function()? _onUpdateAvailable;

  bool get updateAvailable => _updateAvailable;

  void init({Function()? onUpdateAvailable}) {
    _onUpdateAvailable = onUpdateAvailable;
    _setupUpdateListener();
  }

  void _setupUpdateListener() {
    final serviceWorker = html.window.navigator.serviceWorker;
    if (serviceWorker == null) return;

    serviceWorker.ready.then((registration) {
      // التحقق من التحديثات بشكل دوري
      _checkForUpdates(registration);
      
      // كل 5 دقائق
      html.window.setInterval(() {
        _checkForUpdates(registration);
      }, 5 * 60 * 1000);
    });
  }

  void _checkForUpdates(html.ServiceWorkerRegistration registration) {
    registration.update().then((_) {
      if (registration.waiting != null) {
        _updateAvailable = true;
        _onUpdateAvailable?.call();
      }
    });
  }

  void applyUpdate() {
    final serviceWorker = html.window.navigator.serviceWorker;
    if (serviceWorker == null) return;

    serviceWorker.ready.then((registration) {
      if (registration.waiting != null) {
        // إرسال رسالة للـ Service Worker الجديد
        registration.waiting!.postMessage({'type': 'SKIP_WAITING'});
      }
    });

    // إعادة التحميل عند تفعيل العامل الجديد
    serviceWorker.onControllerChange.listen((_) {
      html.window.location.reload();
    });
  }
}
```

### واجهة إشعار التحديث

```dart
// lib/shared/widgets/update_banner.dart
import 'package:flutter/material.dart';

class UpdateBanner extends StatelessWidget {
  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  const UpdateBanner({
    super.key,
    required this.onUpdate,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: const Text('تحديث جديد متاح للتطبيق'),
      leading: const Icon(Icons.system_update, color: Colors.blue),
      backgroundColor: Colors.blue.shade50,
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('لاحقاً'),
        ),
        FilledButton(
          onPressed: onUpdate,
          child: const Text('تحديث الآن'),
        ),
      ],
    );
  }
}

// الاستخدام في التطبيق
class AppShell extends StatefulWidget {
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _showUpdateBanner = false;

  @override
  void initState() {
    super.initState();
    UpdateService().init(
      onUpdateAvailable: () {
        setState(() => _showUpdateBanner = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_showUpdateBanner)
            UpdateBanner(
              onUpdate: () {
                UpdateService().applyUpdate();
              },
              onDismiss: () {
                setState(() => _showUpdateBanner = false);
              },
            ),
          Expanded(child: /* محتوى التطبيق */),
        ],
      ),
    );
  }
}
```

## صفحة Offline

### إنشاء صفحة Offline

```html
<!-- web/offline.html -->
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>غير متصل</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
      color: white;
      text-align: center;
      padding: 20px;
    }
    
    .container {
      max-width: 400px;
    }
    
    .icon {
      width: 120px;
      height: 120px;
      margin-bottom: 24px;
    }
    
    h1 {
      font-size: 28px;
      margin-bottom: 16px;
    }
    
    p {
      font-size: 16px;
      opacity: 0.9;
      margin-bottom: 32px;
      line-height: 1.6;
    }
    
    button {
      background: white;
      color: #667eea;
      border: none;
      padding: 16px 32px;
      font-size: 16px;
      font-weight: 600;
      border-radius: 30px;
      cursor: pointer;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    
    button:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0,0,0,0.2);
    }
    
    button:active {
      transform: translateY(0);
    }
  </style>
</head>
<body>
  <div class="container">
    <svg class="icon" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <circle cx="50" cy="50" r="45" fill="rgba(255,255,255,0.2)"/>
      <path d="M30 50 L45 65 L70 35" stroke="white" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round" opacity="0.3"/>
      <line x1="25" y1="25" x2="75" y2="75" stroke="white" stroke-width="4" stroke-linecap="round"/>
    </svg>
    
    <h1>أنت غير متصل</h1>
    <p>يبدو أنك فقدت الاتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى.</p>
    
    <button onclick="window.location.reload()">
      إعادة المحاولة
    </button>
  </div>
  
  <script>
    // التحقق من الاتصال تلقائياً
    window.addEventListener('online', () => {
      window.location.reload();
    });
  </script>
</body>
</html>
```

## Background Sync

### تزامن الخلفية للطلبات الفاشلة

```javascript
// في Service Worker
import { BackgroundSyncPlugin } from 'workbox-background-sync';

const bgSyncPlugin = new BackgroundSyncPlugin('api-queue', {
  maxRetentionTime: 24 * 60, // 24 ساعة بالدقائق
  onSync: async ({ queue }) => {
    console.log('[SW] Background sync triggered');
    let entry;
    while ((entry = await queue.shiftRequest())) {
      try {
        await fetch(entry.request);
        console.log('[SW] Request replayed:', entry.request.url);
      } catch (error) {
        console.error('[SW] Request failed:', error);
        await queue.unshiftRequest(entry);
        throw error;
      }
    }
  },
});

// طلبات POST للـ API
registerRoute(
  ({ url, request }) => 
    url.pathname.startsWith('/api/') && 
    request.method === 'POST',
  new NetworkOnly({
    plugins: [bgSyncPlugin],
  }),
  'POST'
);
```

### التكامل مع Flutter

```dart
// lib/core/services/offline_queue.dart
import 'dart:html' as html;
import 'dart:convert';
import 'package:idb_shim/idb_browser.dart';

class OfflineQueue {
  static const _dbName = 'offline-queue';
  static const _storeName = 'requests';
  
  late Database _db;

  Future<void> init() async {
    final factory = getIdbFactory()!;
    _db = await factory.open(_dbName, version: 1, onUpgradeNeeded: (e) {
      final db = e.database;
      if (!db.objectStoreNames.contains(_storeName)) {
        db.createObjectStore(_storeName, autoIncrement: true);
      }
    });
  }

  /// إضافة طلب للقائمة
  Future<void> enqueue(String url, String method, Map<String, dynamic> body) async {
    final txn = _db.transaction(_storeName, 'readwrite');
    final store = txn.objectStore(_storeName);
    
    await store.add({
      'url': url,
      'method': method,
      'body': jsonEncode(body),
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await txn.completed;
    
    // طلب مزامنة الخلفية
    _requestBackgroundSync();
  }

  /// محاولة المزامنة
  Future<void> sync() async {
    final txn = _db.transaction(_storeName, 'readwrite');
    final store = txn.objectStore(_storeName);
    
    final requests = await store.getAll();
    
    for (final request in requests) {
      try {
        // إرسال الطلب
        final response = await html.HttpRequest.request(
          request['url'],
          method: request['method'],
          sendData: request['body'],
          requestHeaders: {'Content-Type': 'application/json'},
        );
        
        if (response.status == 200 || response.status == 201) {
          // حذف الطلب الناجح
          await store.delete(request.key);
        }
      } catch (e) {
        print('Failed to sync request: $e');
      }
    }
    
    await txn.completed;
  }

  void _requestBackgroundSync() {
    final serviceWorker = html.window.navigator.serviceWorker;
    serviceWorker?.ready.then((registration) {
      // طلب مزامنة الخلفية
      js.context.callMethod('eval', ['''
        navigator.serviceWorker.ready.then(reg => {
          return reg.sync.register('api-queue');
        });
      ''']);
    });
  }
}
```

## Push Notifications

### تكوين الإشعارات

```javascript
// في Service Worker
self.addEventListener('push', (event) => {
  const data = event.data?.json() ?? {};
  
  const options = {
    body: data.body || 'لديك إشعار جديد',
    icon: '/icons/Icon-192.png',
    badge: '/icons/badge-72.png',
    vibrate: [100, 50, 100],
    data: {
      url: data.url || '/',
    },
    actions: data.actions || [],
    tag: data.tag || 'default',
    renotify: true,
  };
  
  event.waitUntil(
    self.registration.showNotification(data.title || 'تطبيقي', options)
  );
});

// عند النقر على الإشعار
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  
  const url = event.notification.data.url;
  
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then((windowClients) => {
      // البحث عن نافذة مفتوحة
      for (const client of windowClients) {
        if (client.url === url && 'focus' in client) {
          return client.focus();
        }
      }
      // فتح نافذة جديدة
      if (clients.openWindow) {
        return clients.openWindow(url);
      }
    })
  );
});
```

### طلب إذن الإشعارات في Flutter

```dart
// lib/core/services/notification_service.dart
import 'dart:html' as html;
import 'dart:js' as js;

class WebNotificationService {
  static Future<bool> requestPermission() async {
    final permission = await html.Notification.requestPermission();
    return permission == 'granted';
  }

  static Future<String?> getToken() async {
    final serviceWorker = html.window.navigator.serviceWorker;
    if (serviceWorker == null) return null;

    final registration = await serviceWorker.ready;
    
    // استخدام Web Push API
    final subscription = await js.context.callMethod('eval', ['''
      (async () => {
        const reg = await navigator.serviceWorker.ready;
        const sub = await reg.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: 'YOUR_VAPID_PUBLIC_KEY'
        });
        return JSON.stringify(sub.toJSON());
      })()
    ''']);
    
    return subscription;
  }
}
```

## تحسين الأداء

### Precaching الذكي

```javascript
// web/sw-optimized.js
const CORE_CACHE = 'core-v1';
const ASSETS_CACHE = 'assets-v1';
const RUNTIME_CACHE = 'runtime-v1';

// الملفات الأساسية فقط
const CORE_FILES = [
  '/',
  '/index.html',
  '/main.dart.js',
  '/flutter.js',
];

// الأصول يمكن تحميلها لاحقاً
const ASSET_FILES = [
  '/assets/fonts/main.woff2',
  '/icons/Icon-192.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    Promise.all([
      // تحميل الأساسيات فوراً
      caches.open(CORE_CACHE).then(cache => cache.addAll(CORE_FILES)),
      // تحميل الأصول في الخلفية
      caches.open(ASSETS_CACHE).then(cache => {
        // لا ننتظر
        cache.addAll(ASSET_FILES).catch(() => {});
      }),
    ]).then(() => self.skipWaiting())
  );
});

// استراتيجية ذكية حسب نوع المورد
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  
  // main.dart.js: Network First مع timeout قصير
  if (url.pathname.endsWith('main.dart.js')) {
    event.respondWith(
      Promise.race([
        fetch(event.request)
          .then(response => {
            if (response.ok) {
              const cache = caches.open(CORE_CACHE);
              cache.then(c => c.put(event.request, response.clone()));
            }
            return response;
          }),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error('timeout')), 3000)
        ),
      ]).catch(() => caches.match(event.request))
    );
    return;
  }
  
  // الأصول الثابتة: Cache First
  if (isStaticAsset(url)) {
    event.respondWith(
      caches.match(event.request).then(cached => {
        return cached || fetch(event.request).then(response => {
          if (response.ok) {
            caches.open(ASSETS_CACHE)
              .then(cache => cache.put(event.request, response.clone()));
          }
          return response;
        });
      })
    );
    return;
  }
  
  // الافتراضي: Network First
  event.respondWith(
    fetch(event.request)
      .then(response => {
        if (response.ok) {
          caches.open(RUNTIME_CACHE)
            .then(cache => cache.put(event.request, response.clone()));
        }
        return response;
      })
      .catch(() => caches.match(event.request))
  );
});

function isStaticAsset(url) {
  return /\.(png|jpg|jpeg|gif|webp|svg|woff2|woff|ttf|css)$/i.test(url.pathname);
}
```

## أدوات التشخيص

### تسجيل أحداث Service Worker

```javascript
// في Service Worker
const DEBUG = true;

function log(...args) {
  if (DEBUG) {
    console.log('[SW]', new Date().toISOString(), ...args);
  }
}

self.addEventListener('install', (event) => {
  log('Installing...');
});

self.addEventListener('activate', (event) => {
  log('Activating...');
});

self.addEventListener('fetch', (event) => {
  log('Fetch:', event.request.method, event.request.url);
});
```

### فحص من Flutter

```dart
// lib/core/utils/sw_diagnostics.dart
import 'dart:html' as html;

class ServiceWorkerDiagnostics {
  static Future<Map<String, dynamic>> getStatus() async {
    final sw = html.window.navigator.serviceWorker;
    if (sw == null) {
      return {'supported': false};
    }

    final registration = await sw.ready;
    
    return {
      'supported': true,
      'controller': sw.controller?.state,
      'scope': registration.scope,
      'installing': registration.installing?.state,
      'waiting': registration.waiting?.state,
      'active': registration.active?.state,
    };
  }

  static Future<List<String>> getCacheNames() async {
    final cacheNames = await html.window.caches!.keys();
    return cacheNames.toList();
  }

  static Future<int> getCacheSize(String cacheName) async {
    final cache = await html.window.caches!.open(cacheName);
    final keys = await cache.keys();
    
    int totalSize = 0;
    for (final request in keys) {
      final response = await cache.match(request);
      if (response != null) {
        final blob = await response.blob();
        totalSize += blob.size;
      }
    }
    
    return totalSize;
  }
}
```

## قائمة المراجعة

### الإعداد الأساسي
- [ ] تفعيل Service Worker في index.html
- [ ] تحديد الملفات للتخزين المسبق
- [ ] اختيار استراتيجيات التخزين المناسبة
- [ ] إنشاء صفحة offline.html

### إدارة التحديثات
- [ ] آلية اكتشاف التحديثات
- [ ] إشعار المستخدم بالتحديثات
- [ ] تحديث سلس بدون فقدان البيانات
- [ ] تنظيف الكاش القديم

### الوظائف المتقدمة
- [ ] Background Sync للطلبات الفاشلة
- [ ] Push Notifications (إذا لزم)
- [ ] تخزين مؤقت ذكي حسب النوع
- [ ] أدوات تشخيص وتصحيح

## الأخطاء الشائعة

| الخطأ | المشكلة | الحل |
|-------|---------|------|
| تخزين كل شيء | استهلاك مساحة كبيرة | تحديد ما يُخزن |
| عدم تحديث الكاش | محتوى قديم | إصدارات للكاش |
| لا صفحة offline | خطأ عند انقطاع الاتصال | إنشاء offline.html |
| تجاهل التحديثات | المستخدم لا يرى الجديد | آلية تحديث واضحة |

---

**المرجع السابق:** [09-initial-load.md](./09-initial-load.md) - تحسين التحميل الأولي
**المرجع التالي:** [11-network-optimization.md](./11-network-optimization.md) - تحسين الشبكة
