# إعدادات البناء للأداء الأمثل

## نظرة عامة

```
┌─────────────────────────────────────────────────────────────────┐
│                    Build Configuration                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │   Compiler   │───▶│  Optimizer   │───▶│   Output     │     │
│  │    Flags     │    │   Settings   │    │   Config     │     │
│  └──────────────┘    └──────────────┘    └──────────────┘     │
│         │                   │                   │              │
│         ▼                   ▼                   ▼              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │ dart2js opts │    │ Tree Shaking │    │ Source Maps  │     │
│  │ -O4 level    │    │ Minification │    │ Split Chunks │     │
│  │ CSP mode     │    │ Dead Code    │    │ Hash Names   │     │
│  └──────────────┘    └──────────────┘    └──────────────┘     │
│                                                                 │
│  النتيجة: حزمة محسنة بأقصى أداء                                │
└─────────────────────────────────────────────────────────────────┘
```

## أوامر البناء الأساسية

### 1. بناء الإنتاج الأساسي

```bash
# البناء الأساسي للإنتاج
flutter build web --release

# مع renderer محدد
flutter build web --release --web-renderer html
flutter build web --release --web-renderer canvaskit
flutter build web --release --web-renderer auto

# مع Tree Shaking للأيقونات
flutter build web --release --tree-shake-icons
```

### 2. بناء محسن بالكامل

```bash
#!/bin/bash
# build-optimized.sh

set -e

echo "🚀 بدء البناء المحسن..."

# تنظيف البناء السابق
flutter clean
rm -rf build/

# تحديث الحزم
flutter pub get

# البناء مع جميع التحسينات
flutter build web \
  --release \
  --web-renderer auto \
  --tree-shake-icons \
  --dart-define=FLUTTER_WEB_USE_SKIA=true \
  --dart-define=FLUTTER_WEB_AUTO_DETECT=true \
  --source-maps \
  --pwa-strategy=offline-first

echo "✅ اكتمل البناء!"
echo "📦 حجم الحزمة:"
du -sh build/web/
```

## إعدادات dart2js المتقدمة

### 1. مستويات التحسين

```bash
# O0: بدون تحسين (للتطوير)
flutter build web --release --dart2js-optimization=O0

# O1: تحسين أساسي
flutter build web --release --dart2js-optimization=O1

# O2: تحسين قياسي (افتراضي)
flutter build web --release --dart2js-optimization=O2

# O3: تحسين عالي
flutter build web --release --dart2js-optimization=O3

# O4: تحسين أقصى (أطول وقت بناء، أفضل أداء)
flutter build web --release --dart2js-optimization=O4
```

### 2. إعدادات dart2js المخصصة

```yaml
# analysis_options.yaml
analyzer:
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false
  
  language:
    strict-casts: true
    strict-raw-types: true

# يساعد dart2js في تحسين الكود
```

### 3. فلاتر dart2js

```bash
# تجاهل تحذيرات محددة
flutter build web --release \
  --extra-gen-snapshot-options=--dwarf-stack-traces

# تعطيل الـ assertions
flutter build web --release \
  --dart-define=dart.vm.product=true
```

## متغيرات التعريف (Dart Defines)

### 1. المتغيرات الأساسية

```bash
flutter build web --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_URL=https://api.example.com \
  --dart-define=ENABLE_LOGGING=false \
  --dart-define=ENABLE_ANALYTICS=true \
  --dart-define=APP_VERSION=1.0.0
```

### 2. استخدام المتغيرات في الكود

```dart
// config/environment.dart

class Environment {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );
  
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );
  
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  );
  
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.0.0',
  );
  
  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
}
```

### 3. ملف التكوين للمتغيرات

```dart
// config/build_config.dart

class BuildConfig {
  // Flutter Web Specific
  static const bool useSkia = bool.fromEnvironment(
    'FLUTTER_WEB_USE_SKIA',
    defaultValue: false,
  );
  
  static const bool autoDetectRenderer = bool.fromEnvironment(
    'FLUTTER_WEB_AUTO_DETECT',
    defaultValue: true,
  );
  
  // Performance Flags
  static const bool enablePrefetch = bool.fromEnvironment(
    'ENABLE_PREFETCH',
    defaultValue: true,
  );
  
  static const bool enableCaching = bool.fromEnvironment(
    'ENABLE_CACHING',
    defaultValue: true,
  );
  
  static const int cacheMaxAge = int.fromEnvironment(
    'CACHE_MAX_AGE',
    defaultValue: 86400, // 24 hours
  );
  
  // Feature Flags
  static const bool enableNewFeature = bool.fromEnvironment(
    'ENABLE_NEW_FEATURE',
    defaultValue: false,
  );
  
  // Debug Flags (يتم تعطيلها تلقائياً في production)
  static const bool showDebugBanner = bool.fromEnvironment(
    'SHOW_DEBUG_BANNER',
    defaultValue: false,
  );
  
  static const bool enablePerformanceOverlay = bool.fromEnvironment(
    'ENABLE_PERFORMANCE_OVERLAY',
    defaultValue: false,
  );
}
```

## إعدادات الـ Web Renderer

### 1. تكوين الـ Renderer

```html
<!-- web/index.html -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>My App</title>
  
  <script>
    // تحديد الـ renderer بناءً على الجهاز
    (function() {
      // اكتشاف الجهاز
      const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
      const isLowEndDevice = navigator.hardwareConcurrency <= 2 || navigator.deviceMemory <= 2;
      const hasWeakGPU = !window.WebGLRenderingContext;
      
      // تحديد الـ renderer الأمثل
      let renderer;
      if (isMobile || isLowEndDevice || hasWeakGPU) {
        renderer = 'html';
      } else {
        renderer = 'canvaskit';
      }
      
      // تخزين للاستخدام لاحقاً
      window.flutterWebRenderer = renderer;
      
      console.log('Selected renderer:', renderer);
    })();
  </script>
</head>
<body>
  <script src="flutter.js" defer></script>
  <script>
    window.addEventListener('load', function() {
      _flutter.loader.loadEntrypoint({
        onEntrypointLoaded: async function(engineInitializer) {
          let appRunner = await engineInitializer.initializeEngine({
            renderer: window.flutterWebRenderer,
          });
          await appRunner.runApp();
        }
      });
    });
  </script>
</body>
</html>
```

### 2. تكوين CanvasKit المتقدم

```html
<script>
  window.addEventListener('load', function() {
    _flutter.loader.loadEntrypoint({
      onEntrypointLoaded: async function(engineInitializer) {
        let appRunner = await engineInitializer.initializeEngine({
          renderer: 'canvaskit',
          // تخصيص مسار CanvasKit
          canvasKitBaseUrl: '/canvaskit/',
          // تفعيل WebGL2
          useColorEmoji: true,
        });
        await appRunner.runApp();
      }
    });
  });
</script>
```

### 3. استضافة CanvasKit محلياً

```bash
#!/bin/bash
# download-canvaskit.sh

# تحميل CanvasKit للاستضافة المحلية
CANVASKIT_VERSION="0.39.1"
CANVASKIT_URL="https://unpkg.com/canvaskit-wasm@${CANVASKIT_VERSION}/bin"

mkdir -p web/canvaskit

# تحميل الملفات المطلوبة
curl -o web/canvaskit/canvaskit.js "${CANVASKIT_URL}/canvaskit.js"
curl -o web/canvaskit/canvaskit.wasm "${CANVASKIT_URL}/canvaskit.wasm"

echo "✅ تم تحميل CanvasKit ${CANVASKIT_VERSION}"
```

## إعدادات الـ PWA

### 1. استراتيجيات PWA

```bash
# offline-first: تحميل من الكاش أولاً
flutter build web --release --pwa-strategy=offline-first

# none: بدون PWA
flutter build web --release --pwa-strategy=none
```

### 2. تخصيص manifest.json

```json
{
  "name": "اسم التطبيق الكامل",
  "short_name": "التطبيق",
  "description": "وصف التطبيق",
  "start_url": "/",
  "display": "standalone",
  "orientation": "portrait-primary",
  "background_color": "#ffffff",
  "theme_color": "#2196F3",
  "prefer_related_applications": false,
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "icons/Icon-maskable-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "icons/Icon-maskable-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ],
  "screenshots": [
    {
      "src": "screenshots/desktop.png",
      "sizes": "1280x720",
      "type": "image/png",
      "form_factor": "wide"
    },
    {
      "src": "screenshots/mobile.png",
      "sizes": "375x667",
      "type": "image/png",
      "form_factor": "narrow"
    }
  ],
  "categories": ["productivity", "utilities"],
  "shortcuts": [
    {
      "name": "لوحة التحكم",
      "short_name": "لوحة",
      "url": "/dashboard",
      "icons": [{ "src": "icons/shortcut-dashboard.png", "sizes": "96x96" }]
    }
  ],
  "share_target": {
    "action": "/share",
    "method": "POST",
    "enctype": "multipart/form-data",
    "params": {
      "title": "title",
      "text": "text",
      "url": "url",
      "files": [
        {
          "name": "files",
          "accept": ["image/*", "application/pdf"]
        }
      ]
    }
  }
}
```

## Source Maps

### 1. تكوين Source Maps

```bash
# تفعيل Source Maps
flutter build web --release --source-maps

# مع رموز الـ stack trace
flutter build web --release \
  --source-maps \
  --extra-gen-snapshot-options=--dwarf-stack-traces
```

### 2. إعداد Sentry مع Source Maps

```bash
#!/bin/bash
# upload-sourcemaps.sh

# متغيرات Sentry
SENTRY_ORG="your-org"
SENTRY_PROJECT="your-project"
SENTRY_AUTH_TOKEN="your-token"
VERSION=$(cat pubspec.yaml | grep 'version:' | awk '{print $2}')

# بناء مع source maps
flutter build web --release --source-maps

# رفع Source Maps إلى Sentry
sentry-cli releases new "$VERSION"
sentry-cli releases files "$VERSION" upload-sourcemaps build/web/ \
  --url-prefix '~/' \
  --rewrite

sentry-cli releases finalize "$VERSION"

echo "✅ تم رفع Source Maps للإصدار $VERSION"
```

### 3. حذف Source Maps من الإنتاج

```bash
#!/bin/bash
# remove-sourcemaps.sh

# بعد رفعها إلى Sentry، احذفها من الإنتاج
find build/web -name "*.map" -delete

echo "✅ تم حذف Source Maps من مجلد البناء"
```

## تقسيم الكود (Code Splitting)

### 1. Deferred Loading

```dart
// استخدام deferred loading
import 'package:myapp/features/analytics/analytics.dart' deferred as analytics;
import 'package:myapp/features/admin/admin.dart' deferred as admin;
import 'package:myapp/features/reports/reports.dart' deferred as reports;

class FeatureLoader {
  static Future<void> loadAnalytics() async {
    await analytics.loadLibrary();
  }
  
  static Future<void> loadAdmin() async {
    await admin.loadLibrary();
  }
  
  static Future<void> loadReports() async {
    await reports.loadLibrary();
  }
}
```

### 2. تكوين التقسيم

```yaml
# pubspec.yaml
flutter:
  # تفعيل deferred components
  deferred-components:
    - name: analytics_component
      libraries:
        - package:myapp/features/analytics/analytics.dart
    - name: admin_component
      libraries:
        - package:myapp/features/admin/admin.dart
```

## إعدادات الخادم

### 1. Nginx للإنتاج

```nginx
# /etc/nginx/sites-available/flutter-app

server {
    listen 80;
    listen [::]:80;
    server_name example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com;
    
    # SSL
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    
    # المجلد الجذر
    root /var/www/flutter-app/build/web;
    index index.html;
    
    # الضغط
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml
        application/wasm
        font/woff2;
    
    # Brotli (يتطلب nginx-brotli module)
    brotli on;
    brotli_comp_level 6;
    brotli_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml
        application/wasm
        font/woff2;
    
    # التخزين المؤقت للملفات الثابتة
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|wasm)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary "Accept-Encoding";
        access_log off;
    }
    
    # main.dart.js - تخزين قصير لتحديثات التطبيق
    location ~* main\.dart\.js$ {
        expires 1h;
        add_header Cache-Control "public, must-revalidate";
    }
    
    # Service Worker
    location = /flutter_service_worker.js {
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    # index.html
    location = /index.html {
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    # SPA fallback
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()" always;
    
    # CSP للأمان
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self' https://api.example.com wss://ws.example.com; frame-ancestors 'self';" always;
}
```

### 2. Firebase Hosting

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "headers": [
      {
        "source": "**/*.@(js|css|wasm)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      },
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp|avif|ico)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      },
      {
        "source": "**/*.@(woff|woff2|ttf|eot)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      },
      {
        "source": "flutter_service_worker.js",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "no-cache, no-store, must-revalidate"
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
        "source": "**",
        "headers": [
          {
            "key": "X-Frame-Options",
            "value": "SAMEORIGIN"
          },
          {
            "key": "X-Content-Type-Options",
            "value": "nosniff"
          },
          {
            "key": "X-XSS-Protection",
            "value": "1; mode=block"
          }
        ]
      }
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "cleanUrls": true,
    "trailingSlash": false
  }
}
```

### 3. Vercel

```json
{
  "version": 2,
  "builds": [
    {
      "src": "build/web/**",
      "use": "@vercel/static"
    }
  ],
  "routes": [
    {
      "src": "/flutter_service_worker.js",
      "headers": {
        "Cache-Control": "no-cache, no-store, must-revalidate"
      },
      "dest": "/build/web/flutter_service_worker.js"
    },
    {
      "src": "/index.html",
      "headers": {
        "Cache-Control": "no-cache, no-store, must-revalidate"
      },
      "dest": "/build/web/index.html"
    },
    {
      "src": "/(.*\\.(js|css|wasm|woff2?|ttf|eot|png|jpg|jpeg|gif|svg|webp|avif|ico))",
      "headers": {
        "Cache-Control": "public, max-age=31536000, immutable"
      },
      "dest": "/build/web/$1"
    },
    {
      "src": "/(.*)",
      "dest": "/build/web/index.html"
    }
  ]
}
```

## سكريبتات البناء الآلي

### 1. سكريبت البناء الشامل

```bash
#!/bin/bash
# scripts/build-production.sh

set -e

# الألوان
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# المتغيرات
BUILD_DIR="build/web"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)

echo -e "${YELLOW}🚀 بدء بناء الإنتاج - الإصدار $VERSION${NC}"

# 1. التنظيف
echo -e "${YELLOW}📦 تنظيف البناء السابق...${NC}"
flutter clean
rm -rf build/

# 2. تحديث الحزم
echo -e "${YELLOW}📥 تحديث الحزم...${NC}"
flutter pub get

# 3. التحقق من الكود
echo -e "${YELLOW}🔍 تحليل الكود...${NC}"
flutter analyze --no-fatal-infos || true

# 4. تشغيل الاختبارات
echo -e "${YELLOW}🧪 تشغيل الاختبارات...${NC}"
flutter test --coverage || {
    echo -e "${RED}❌ فشلت الاختبارات${NC}"
    exit 1
}

# 5. البناء
echo -e "${YELLOW}🔨 البناء للإنتاج...${NC}"
flutter build web \
    --release \
    --web-renderer auto \
    --tree-shake-icons \
    --dart-define=ENVIRONMENT=production \
    --dart-define=APP_VERSION=$VERSION \
    --dart-define=BUILD_TIMESTAMP=$TIMESTAMP \
    --source-maps

# 6. تحسين الصور
echo -e "${YELLOW}🖼️ تحسين الصور...${NC}"
if command -v optipng &> /dev/null; then
    find $BUILD_DIR -name "*.png" -exec optipng -o7 {} \;
fi

# 7. ضغط الملفات
echo -e "${YELLOW}📦 ضغط الملفات...${NC}"
if command -v gzip &> /dev/null; then
    find $BUILD_DIR -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" -o -name "*.json" -o -name "*.wasm" \) \
        -exec gzip -9 -k {} \;
fi

if command -v brotli &> /dev/null; then
    find $BUILD_DIR -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" -o -name "*.json" -o -name "*.wasm" \) \
        -exec brotli -q 11 -k {} \;
fi

# 8. إحصائيات البناء
echo -e "${GREEN}✅ اكتمل البناء بنجاح!${NC}"
echo ""
echo "📊 إحصائيات البناء:"
echo "===================="
echo "الإصدار: $VERSION"
echo "الوقت: $TIMESTAMP"
echo ""
echo "أحجام الملفات:"
echo "--------------"
ls -lh $BUILD_DIR/*.js 2>/dev/null || true
echo ""
echo "الحجم الإجمالي:"
du -sh $BUILD_DIR

# 9. حفظ معلومات البناء
cat > $BUILD_DIR/build-info.json << EOF
{
  "version": "$VERSION",
  "timestamp": "$TIMESTAMP",
  "environment": "production",
  "renderer": "auto",
  "git_commit": "$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')",
  "git_branch": "$(git branch --show-current 2>/dev/null || echo 'unknown')"
}
EOF

echo -e "${GREEN}🎉 جاهز للنشر!${NC}"
```

### 2. سكريبت البناء المتعدد البيئات

```bash
#!/bin/bash
# scripts/build-env.sh

set -e

ENV=${1:-production}
VALID_ENVS="development staging production"

if [[ ! " $VALID_ENVS " =~ " $ENV " ]]; then
    echo "❌ بيئة غير صالحة: $ENV"
    echo "البيئات المتاحة: $VALID_ENVS"
    exit 1
fi

echo "🔧 البناء لبيئة: $ENV"

# تحميل متغيرات البيئة
if [ -f ".env.$ENV" ]; then
    source ".env.$ENV"
fi

# إعدادات حسب البيئة
case $ENV in
    development)
        RENDERER="html"
        OPTIMIZATION="O1"
        SOURCE_MAPS="--source-maps"
        DEFINES="--dart-define=ENVIRONMENT=development --dart-define=ENABLE_LOGGING=true"
        ;;
    staging)
        RENDERER="auto"
        OPTIMIZATION="O3"
        SOURCE_MAPS="--source-maps"
        DEFINES="--dart-define=ENVIRONMENT=staging --dart-define=ENABLE_LOGGING=true"
        ;;
    production)
        RENDERER="auto"
        OPTIMIZATION="O4"
        SOURCE_MAPS=""
        DEFINES="--dart-define=ENVIRONMENT=production --dart-define=ENABLE_LOGGING=false"
        ;;
esac

# البناء
flutter build web \
    --release \
    --web-renderer $RENDERER \
    --dart2js-optimization=$OPTIMIZATION \
    --tree-shake-icons \
    $SOURCE_MAPS \
    $DEFINES \
    --dart-define=API_URL=${API_URL:-https://api.example.com}

echo "✅ اكتمل البناء لـ $ENV"
```

### 3. GitHub Actions

```yaml
# .github/workflows/build-deploy.yml

name: Build and Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  FLUTTER_VERSION: '3.24.0'

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Analyze
        run: flutter analyze --no-fatal-infos
      
      - name: Check formatting
        run: dart format --set-exit-if-changed .

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info

  build:
    needs: [analyze, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build web
        run: |
          flutter build web \
            --release \
            --web-renderer auto \
            --tree-shake-icons \
            --dart-define=ENVIRONMENT=production \
            --dart-define=API_URL=${{ secrets.API_URL }}
      
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: web-build
          path: build/web

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      
      - name: Download artifact
        uses: actions/download-artifact@v4
        with:
          name: web-build
          path: build/web
      
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: your-project-id

  lighthouse:
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Lighthouse CI
        uses: treosh/lighthouse-ci-action@v10
        with:
          urls: |
            https://your-app.web.app
          configPath: ./lighthouserc.json
          uploadArtifacts: true
```

## تحسينات متقدمة

### 1. Content Security Policy (CSP)

```html
<!-- web/index.html -->
<meta http-equiv="Content-Security-Policy" content="
  default-src 'self';
  script-src 'self' 'unsafe-inline' 'unsafe-eval';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: blob: https:;
  font-src 'self' data:;
  connect-src 'self' https://api.example.com wss://ws.example.com;
  frame-ancestors 'self';
  base-uri 'self';
  form-action 'self';
">
```

### 2. Integrity Checking

```html
<!-- التحقق من سلامة الملفات -->
<script src="main.dart.js" 
        integrity="sha384-xxxxx" 
        crossorigin="anonymous"></script>
```

### 3. إنشاء Integrity Hashes

```bash
#!/bin/bash
# scripts/generate-integrity.sh

for file in build/web/*.js; do
    hash=$(openssl dgst -sha384 -binary "$file" | openssl base64 -A)
    echo "$file: sha384-$hash"
done
```

## قائمة التحقق للبناء

```
✅ إعدادات البناء
├── ☐ استخدام --release
├── ☐ تحديد الـ renderer المناسب
├── ☐ تفعيل tree-shake-icons
├── ☐ تحديد مستوى التحسين (O4)
└── ☐ تعريف متغيرات البيئة

✅ التحسينات
├── ☐ ضغط الملفات (gzip/brotli)
├── ☐ تحسين الصور
├── ☐ تصغير CSS/JS
└── ☐ إزالة Source Maps من الإنتاج

✅ التخزين المؤقت
├── ☐ Cache headers صحيحة
├── ☐ Service Worker محدث
├── ☐ استراتيجية versioning
└── ☐ CDN مُعَد

✅ الأمان
├── ☐ HTTPS فقط
├── ☐ CSP headers
├── ☐ Security headers
└── ☐ Integrity checking

✅ المراقبة
├── ☐ Error tracking (Sentry)
├── ☐ Analytics
├── ☐ Performance monitoring
└── ☐ Build info endpoint
```

## المراجع

- [01-renderer-selection.md](01-renderer-selection.md) - اختيار الـ Renderer
- [02-bundle-optimization.md](02-bundle-optimization.md) - تحسين حجم الحزمة
- [03-deferred-loading.md](03-deferred-loading.md) - التحميل الكسول
- [06-caching-strategies.md](06-caching-strategies.md) - استراتيجيات التخزين
- [10-service-workers.md](10-service-workers.md) - Service Workers
- [13-measurement-tools.md](13-measurement-tools.md) - أدوات القياس
