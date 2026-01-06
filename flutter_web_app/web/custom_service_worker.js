/**
 * ==========================================
 * معيار 6: استراتيجيات التخزين المؤقت (06-caching-strategies.md)
 * معيار 10: تكوين Service Workers (10-service-workers.md)
 * ==========================================
 *
 * هذا الملف يطبق:
 * - Cache First للملفات الثابتة
 * - Network First للـ API
 * - Stale While Revalidate للأصول الديناميكية
 * - إدارة التحديثات
 * - صفحة Offline
 */

const CACHE_VERSION = 'v1.0.0';
const STATIC_CACHE = `static-${CACHE_VERSION}`;
const DYNAMIC_CACHE = `dynamic-${CACHE_VERSION}`;
const API_CACHE = `api-${CACHE_VERSION}`;

// الملفات الثابتة للتخزين المسبق
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/main.dart.js',
  '/flutter.js',
  '/manifest.json',
  '/favicon.png',
  '/offline.html',
];

// CanvasKit (إذا مستخدم)
const CANVASKIT_ASSETS = [
  '/canvaskit/canvaskit.js',
  '/canvaskit/canvaskit.wasm',
];

// ===== التثبيت =====
self.addEventListener('install', (event) => {
  console.log('[SW] Installing version:', CACHE_VERSION);

  event.waitUntil(
    Promise.all([
      // تخزين الملفات الثابتة
      caches.open(STATIC_CACHE).then((cache) => {
        console.log('[SW] Precaching static assets');
        return cache.addAll(STATIC_ASSETS);
      }),

      // تخزين CanvasKit (اختياري)
      caches.open(STATIC_CACHE).then((cache) => {
        return cache.addAll(CANVASKIT_ASSETS).catch(() => {
          console.log('[SW] CanvasKit not used, skipping');
        });
      }),
    ]).then(() => {
      console.log('[SW] Static assets cached successfully');
      return self.skipWaiting();
    })
  );
});

// ===== التفعيل =====
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating version:', CACHE_VERSION);

  event.waitUntil(
    // حذف الـ caches القديمة
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => {
            return (name.startsWith('static-') && name !== STATIC_CACHE) ||
                   (name.startsWith('dynamic-') && name !== DYNAMIC_CACHE) ||
                   (name.startsWith('api-') && name !== API_CACHE);
          })
          .map((name) => {
            console.log('[SW] Deleting old cache:', name);
            return caches.delete(name);
          })
      );
    }).then(() => {
      console.log('[SW] Old caches cleaned');
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
    event.respondWith(networkFirst(request, API_CACHE, 5 * 60 * 1000)); // 5 دقائق
  } else if (isDynamicAsset(url)) {
    event.respondWith(staleWhileRevalidate(request, DYNAMIC_CACHE));
  } else if (isNavigationRequest(request)) {
    event.respondWith(navigationHandler(request));
  } else {
    event.respondWith(networkFirst(request, DYNAMIC_CACHE, 60 * 60 * 1000)); // ساعة
  }
});

// ===== دوال التصنيف =====

function isStaticAsset(url) {
  const staticExtensions = ['.js', '.css', '.woff2', '.woff', '.ttf', '.wasm'];
  return staticExtensions.some(ext => url.pathname.endsWith(ext)) ||
         url.pathname.startsWith('/canvaskit/') ||
         STATIC_ASSETS.includes(url.pathname);
}

function isApiRequest(url) {
  return url.pathname.startsWith('/api/') ||
         url.hostname.includes('api.');
}

function isDynamicAsset(url) {
  const dynamicExtensions = ['.png', '.jpg', '.jpeg', '.webp', '.svg', '.gif', '.ico'];
  return dynamicExtensions.some(ext => url.pathname.endsWith(ext));
}

function isNavigationRequest(request) {
  return request.mode === 'navigate';
}

// ===== استراتيجيات التخزين =====

/**
 * Cache First - للملفات الثابتة
 * يبحث في الكاش أولاً، ثم الشبكة إذا لم يجد
 */
async function cacheFirst(request, cacheName) {
  const cachedResponse = await caches.match(request);
  if (cachedResponse) {
    console.log('[SW] Cache hit:', request.url);
    return cachedResponse;
  }

  console.log('[SW] Cache miss, fetching:', request.url);
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(cacheName);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    console.error('[SW] Fetch failed:', request.url, error);
    return new Response('Offline', {
      status: 503,
      statusText: 'Service Unavailable'
    });
  }
}

/**
 * Network First - للـ API
 * يحاول من الشبكة أولاً، ثم الكاش كاحتياط
 */
async function networkFirst(request, cacheName, maxAge = 5 * 60 * 1000) {
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(cacheName);
      // إضافة timestamp للتحقق من صلاحية الكاش
      const responseToCache = networkResponse.clone();
      cache.put(request, responseToCache);
    }
    return networkResponse;
  } catch (error) {
    console.log('[SW] Network failed, trying cache:', request.url);
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    return new Response(JSON.stringify({ error: 'Offline', message: 'لا يوجد اتصال بالإنترنت' }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

/**
 * Stale While Revalidate - للأصول الديناميكية
 * يرجع الكاش فوراً ويحدث في الخلفية
 */
async function staleWhileRevalidate(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cachedResponse = await cache.match(request);

  const fetchPromise = fetch(request).then((networkResponse) => {
    if (networkResponse.ok) {
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  }).catch((error) => {
    console.log('[SW] Background fetch failed:', request.url);
    return cachedResponse;
  });

  return cachedResponse || fetchPromise;
}

/**
 * Navigation Handler - للتنقل بين الصفحات
 * يعرض صفحة Offline إذا فشل الاتصال
 */
async function navigationHandler(request) {
  try {
    const response = await fetch(request);
    return response;
  } catch (error) {
    console.log('[SW] Navigation failed, showing offline page');
    const offlinePage = await caches.match('/offline.html');
    if (offlinePage) {
      return offlinePage;
    }
    return new Response('Offline', {
      status: 503,
      statusText: 'Service Unavailable'
    });
  }
}

// ===== إدارة التحديثات =====
self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') {
    console.log('[SW] Skip waiting requested');
    self.skipWaiting();
  }

  if (event.data === 'clearCache') {
    console.log('[SW] Clear cache requested');
    event.waitUntil(
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames.map((name) => caches.delete(name))
        );
      })
    );
  }

  if (event.data === 'getVersion') {
    event.ports[0].postMessage({ version: CACHE_VERSION });
  }
});

// ===== Background Sync (للطلبات الفاشلة) =====
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-api-requests') {
    console.log('[SW] Background sync triggered');
    event.waitUntil(syncPendingRequests());
  }
});

async function syncPendingRequests() {
  // يمكن تنفيذ منطق إعادة الطلبات الفاشلة هنا
  console.log('[SW] Syncing pending requests...');
}

// ===== Push Notifications =====
self.addEventListener('push', (event) => {
  const data = event.data?.json() ?? {};

  const options = {
    body: data.body || 'لديك إشعار جديد',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-72.png',
    vibrate: [100, 50, 100],
    data: {
      url: data.url || '/',
    },
    tag: data.tag || 'default',
    renotify: true,
  };

  event.waitUntil(
    self.registration.showNotification(data.title || 'Flutter Web App', options)
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const url = event.notification.data.url;

  event.waitUntil(
    clients.matchAll({ type: 'window' }).then((windowClients) => {
      for (const client of windowClients) {
        if (client.url === url && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(url);
      }
    })
  );
});

console.log('[SW] Service Worker loaded, version:', CACHE_VERSION);
