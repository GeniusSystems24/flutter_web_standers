# تحسين الأصول والصور (Assets Optimization)

## المقدمة

الأصول (الصور، الأيقونات، الملفات) يمكن أن تشكل 30-50% من حجم التطبيق. التحسين الصحيح يقلل وقت التحميل بشكل كبير.

## تحليل الأصول الحالية

### سكريبت تحليل الأصول

```bash
#!/bin/bash
# scripts/analyze_assets.sh

echo "=== Assets Analysis ==="

ASSETS_DIR="assets"
TOTAL_SIZE=0

echo ""
echo "📁 Images:"
find $ASSETS_DIR -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" \) -exec ls -lh {} \; | awk '{print $5, $9}'

echo ""
echo "📁 Icons:"
find $ASSETS_DIR -type f -name "*.svg" -exec ls -lh {} \; | awk '{print $5, $9}'

echo ""
echo "📁 Other files:"
find $ASSETS_DIR -type f ! \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" -o -name "*.svg" \) -exec ls -lh {} \; | awk '{print $5, $9}'

echo ""
echo "Total assets size:"
du -sh $ASSETS_DIR
```

## تحسين الصور

### 1. اختيار التنسيق المناسب

```
┌─────────────────────────────────────────────────────────────────┐
│                  دليل اختيار تنسيق الصور                        │
├─────────────────────────────────────────────────────────────────┤
│  WebP  ➜ الاختيار الأفضل للويب (أصغر 25-35%)                   │
│  AVIF  ➜ أحدث وأفضل ضغط (أصغر 50%، دعم محدود)                 │
│  PNG   ➜ للصور مع شفافية أو رسوميات حادة                       │
│  JPEG  ➜ للصور الفوتوغرافية بدون شفافية                        │
│  SVG   ➜ للأيقونات والرسوميات المتجهية                         │
│  GIF   ➜ تجنبه! استخدم WebP أو Lottie للـ animations          │
└─────────────────────────────────────────────────────────────────┘
```

### 2. تحويل الصور إلى WebP

```bash
#!/bin/bash
# scripts/convert_to_webp.sh

QUALITY=80
INPUT_DIR="assets/images"
OUTPUT_DIR="assets/images_optimized"

mkdir -p $OUTPUT_DIR

# تحويل PNG إلى WebP
for file in $INPUT_DIR/*.png; do
  if [ -f "$file" ]; then
    filename=$(basename "$file" .png)
    cwebp -q $QUALITY "$file" -o "$OUTPUT_DIR/$filename.webp"
    echo "Converted: $filename.png -> $filename.webp"
  fi
done

# تحويل JPEG إلى WebP
for file in $INPUT_DIR/*.jpg $INPUT_DIR/*.jpeg; do
  if [ -f "$file" ]; then
    filename=$(basename "$file" | sed 's/\.[^.]*$//')
    cwebp -q $QUALITY "$file" -o "$OUTPUT_DIR/$filename.webp"
    echo "Converted: $file -> $filename.webp"
  fi
done

echo ""
echo "=== Size Comparison ==="
echo "Original:"
du -sh $INPUT_DIR
echo "Optimized:"
du -sh $OUTPUT_DIR
```

### 3. تحسين أبعاد الصور

```dart
// lib/core/utils/image_dimensions.dart

/// أبعاد الصور المُوصى بها
class ImageDimensions {
  /// للصور الكاملة العرض
  static const fullWidth = Size(1920, 1080);
  
  /// للصور المصغرة
  static const thumbnail = Size(150, 150);
  
  /// لصور المنتجات
  static const product = Size(600, 600);
  
  /// لصور الملف الشخصي
  static const avatar = Size(200, 200);
  
  /// للخلفيات
  static const background = Size(1920, 1080);
  
  /// للأيقونات
  static const icon = Size(64, 64);
}
```

### 4. سكريبت تغيير أبعاد الصور

```bash
#!/bin/bash
# scripts/resize_images.sh

# تثبيت ImageMagick إذا لم يكن موجوداً
# apt-get install imagemagick

INPUT_DIR="assets/images"
OUTPUT_DIR="assets/images_resized"

mkdir -p $OUTPUT_DIR

# تغيير حجم الصور الكبيرة
for file in $INPUT_DIR/*; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")
    # تغيير الحجم مع الحفاظ على النسبة
    convert "$file" -resize "1920x1080>" "$OUTPUT_DIR/$filename"
    echo "Resized: $filename"
  fi
done

# إنشاء نسخ مصغرة
mkdir -p $OUTPUT_DIR/thumbnails
for file in $INPUT_DIR/*; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")
    convert "$file" -resize "150x150^" -gravity center -crop 150x150+0+0 "$OUTPUT_DIR/thumbnails/$filename"
    echo "Thumbnail: $filename"
  fi
done
```

## تحميل الصور المحسن

### 1. استخدام cached_network_image

```yaml
# pubspec.yaml
dependencies:
  cached_network_image: ^3.3.0
```

```dart
// lib/core/widgets/optimized_image.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _DefaultPlaceholder(),
      errorWidget: (context, url, error) => 
          errorWidget ?? _DefaultErrorWidget(),
      // تحسينات إضافية
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );
  }
}

class _DefaultPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.error_outline, color: Colors.grey),
    );
  }
}
```

### 2. التحميل التدريجي (Progressive Loading)

```dart
// lib/core/widgets/progressive_image.dart
import 'package:flutter/material.dart';

class ProgressiveImage extends StatefulWidget {
  final String thumbnailUrl;
  final String fullImageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ProgressiveImage({
    Key? key,
    required this.thumbnailUrl,
    required this.fullImageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<ProgressiveImage> createState() => _ProgressiveImageState();
}

class _ProgressiveImageState extends State<ProgressiveImage> {
  bool _isFullImageLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // الصورة المصغرة (تُحمّل أولاً)
        Image.network(
          widget.thumbnailUrl,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        ),
        
        // الصورة الكاملة (تُحمّل في الخلفية)
        AnimatedOpacity(
          opacity: _isFullImageLoaded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: Image.network(
            widget.fullImageUrl,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _isFullImageLoaded = true);
                  }
                });
                return child;
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
```

### 3. التحميل الكسول للصور (Lazy Loading)

```dart
// lib/core/widgets/lazy_image.dart
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LazyImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const LazyImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage> {
  bool _shouldLoad = false;
  final _key = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: _key,
      onVisibilityChanged: (info) {
        // تحميل الصورة عندما تصبح مرئية بنسبة 10%
        if (info.visibleFraction > 0.1 && !_shouldLoad) {
          setState(() => _shouldLoad = true);
        }
      },
      child: _shouldLoad
          ? Image.network(
              widget.imageUrl,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _Placeholder(width: widget.width, height: widget.height);
              },
              errorBuilder: (context, error, stackTrace) {
                return _ErrorWidget(width: widget.width, height: widget.height);
              },
            )
          : _Placeholder(width: widget.width, height: widget.height),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double? width;
  final double? height;

  const _Placeholder({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image, color: Colors.grey),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final double? width;
  final double? height;

  const _ErrorWidget({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
```

## تحسين الأيقونات

### 1. استخدام SVG بدلاً من PNG

```yaml
# pubspec.yaml
dependencies:
  flutter_svg: ^2.0.9
```

```dart
// lib/core/widgets/svg_icon.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcon extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final Color? color;

  const SvgIcon({
    Key? key,
    required this.assetPath,
    this.width = 24,
    this.height = 24,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      colorFilter: color != null 
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}

// الاستخدام
// SvgIcon(assetPath: 'assets/icons/home.svg', color: Colors.blue)
```

### 2. تجميع SVG في ملف واحد (SVG Sprite)

```dart
// lib/core/widgets/svg_sprite_icon.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// أيقونات SVG مُجمعة
class AppIcons {
  static const String _spritePath = 'assets/icons/sprite.svg';
  
  static Widget home({double size = 24, Color? color}) =>
      _SpriteIcon(id: 'home', size: size, color: color);
  
  static Widget settings({double size = 24, Color? color}) =>
      _SpriteIcon(id: 'settings', size: size, color: color);
  
  static Widget profile({double size = 24, Color? color}) =>
      _SpriteIcon(id: 'profile', size: size, color: color);
}

class _SpriteIcon extends StatelessWidget {
  final String id;
  final double size;
  final Color? color;

  const _SpriteIcon({
    required this.id,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$id.svg', // أو استخدم sprite sheet
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
```

### 3. تحسين SVG

```bash
#!/bin/bash
# scripts/optimize_svg.sh

# تثبيت svgo
npm install -g svgo

INPUT_DIR="assets/icons"
OUTPUT_DIR="assets/icons_optimized"

mkdir -p $OUTPUT_DIR

# تحسين ملفات SVG
svgo -f $INPUT_DIR -o $OUTPUT_DIR --config=svgo.config.js

echo "SVG optimization complete!"
```

```javascript
// svgo.config.js
module.exports = {
  plugins: [
    'preset-default',
    'removeDimensions',
    {
      name: 'removeAttrs',
      params: {
        attrs: '(stroke|fill)'
      }
    }
  ]
};
```

## التخزين المؤقت للأصول

### 1. تكوين Service Worker

```javascript
// web/flutter_service_worker.js (مُخصص)
const CACHE_NAME = 'assets-cache-v1';
const ASSETS_TO_CACHE = [
  '/assets/images/logo.webp',
  '/assets/icons/sprite.svg',
  '/assets/fonts/custom-font.woff2',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS_TO_CACHE);
    })
  );
});

self.addEventListener('fetch', (event) => {
  // تخزين الأصول مؤقتاً
  if (event.request.url.includes('/assets/')) {
    event.respondWith(
      caches.match(event.request).then((response) => {
        return response || fetch(event.request).then((fetchResponse) => {
          return caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, fetchResponse.clone());
            return fetchResponse;
          });
        });
      })
    );
  }
});
```

### 2. Preloading للأصول الحرجة

```html
<!-- web/index.html -->
<head>
  <!-- تحميل مسبق للأصول الحرجة -->
  <link rel="preload" href="assets/images/logo.webp" as="image">
  <link rel="preload" href="assets/fonts/CustomFont.woff2" as="font" crossorigin>
  
  <!-- DNS Prefetch للصور الخارجية -->
  <link rel="dns-prefetch" href="//images.example.com">
</head>
```

## تحسين pubspec.yaml

```yaml
# pubspec.yaml
flutter:
  assets:
    # ❌ تجنب تحميل مجلدات كاملة
    # - assets/images/
    
    # ✅ حدد الملفات المطلوبة فقط
    - assets/images/logo.webp
    - assets/images/background.webp
    - assets/icons/home.svg
    - assets/icons/settings.svg
    
    # أو استخدم نمط محدد
    - assets/images/essential/
    
  # تحسين الخطوط
  fonts:
    - family: CustomFont
      fonts:
        - asset: assets/fonts/CustomFont-Regular.woff2
        - asset: assets/fonts/CustomFont-Bold.woff2
          weight: 700
```

## أدوات التحسين

### 1. سكريبت التحسين الشامل

```bash
#!/bin/bash
# scripts/optimize_all_assets.sh

echo "=== Starting Assets Optimization ==="

# 1. تحويل الصور إلى WebP
echo "Converting images to WebP..."
for file in assets/images/*.{png,jpg,jpeg}; do
  if [ -f "$file" ]; then
    filename=$(basename "$file" | sed 's/\.[^.]*$//')
    cwebp -q 80 "$file" -o "assets/images/$filename.webp"
    rm "$file"
  fi
done

# 2. تغيير حجم الصور الكبيرة
echo "Resizing large images..."
for file in assets/images/*.webp; do
  if [ -f "$file" ]; then
    # تغيير حجم الصور الأكبر من 1920px
    convert "$file" -resize "1920x1920>" "$file"
  fi
done

# 3. تحسين SVG
echo "Optimizing SVG files..."
if command -v svgo &> /dev/null; then
  svgo -f assets/icons/ -o assets/icons/
fi

# 4. إنشاء تقرير
echo ""
echo "=== Optimization Report ==="
echo "Images:"
du -sh assets/images/
echo "Icons:"
du -sh assets/icons/
echo "Total:"
du -sh assets/

echo ""
echo "✅ Optimization complete!"
```

### 2. Dart Script للتحليل

```dart
// tools/analyze_assets.dart
import 'dart:io';

void main() async {
  final assetsDir = Directory('assets');
  final report = <String, _AssetReport>{};
  
  await for (final entity in assetsDir.list(recursive: true)) {
    if (entity is File) {
      final extension = entity.path.split('.').last.toLowerCase();
      final size = await entity.length();
      
      report[extension] ??= _AssetReport(extension);
      report[extension]!.count++;
      report[extension]!.totalSize += size;
      
      // تحذير للملفات الكبيرة
      if (size > 500 * 1024) { // > 500 KB
        print('⚠️ Large file: ${entity.path} (${_formatSize(size)})');
      }
    }
  }
  
  print('\n=== Assets Report ===');
  report.values.toList()
    ..sort((a, b) => b.totalSize.compareTo(a.totalSize))
    ..forEach((r) {
      print('${r.extension}: ${r.count} files, ${_formatSize(r.totalSize)}');
    });
}

class _AssetReport {
  final String extension;
  int count = 0;
  int totalSize = 0;
  
  _AssetReport(this.extension);
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
```

## جدول المقارنة

| نوع الأصل | قبل التحسين | بعد التحسين | التحسين |
|-----------|-------------|-------------|---------|
| صور PNG | 2 MB | 600 KB (WebP) | 70% |
| صور JPEG | 1.5 MB | 450 KB (WebP) | 70% |
| أيقونات PNG | 500 KB | 50 KB (SVG) | 90% |
| خطوط TTF | 800 KB | 300 KB (WOFF2) | 62% |
| **المجموع** | **4.8 MB** | **1.4 MB** | **71%** |

## قائمة المراجعة

```markdown
## Assets Optimization Checklist

### الصور
- [ ] تحويل جميع الصور إلى WebP
- [ ] تغيير حجم الصور الكبيرة (max 1920px)
- [ ] إنشاء نسخ مصغرة للقوائم
- [ ] استخدام تحميل كسول للصور
- [ ] تفعيل التخزين المؤقت

### الأيقونات
- [ ] استخدام SVG بدلاً من PNG
- [ ] تحسين ملفات SVG باستخدام SVGO
- [ ] تجميع الأيقونات في sprite (اختياري)

### الخطوط
- [ ] تحويل إلى WOFF2
- [ ] استخدام font-display: swap
- [ ] تحميل مؤجل للخطوط الثانوية

### عام
- [ ] تحديد الأصول المطلوبة في pubspec.yaml
- [ ] تكوين Service Worker للتخزين
- [ ] تحميل مسبق للأصول الحرجة
- [ ] قياس التحسين قبل وبعد
```

---

**المرجع السابق:** [03-deferred-loading.md](./03-deferred-loading.md)
**المرجع التالي:** [05-fonts-optimization.md](./05-fonts-optimization.md)
