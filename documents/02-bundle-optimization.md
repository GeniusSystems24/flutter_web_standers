# تحسين حجم الحزمة (Bundle Optimization)

## المقدمة

حجم الحزمة (Bundle Size) هو العامل الأكثر تأثيراً على وقت التحميل الأولي. كل 100 KB إضافية تضيف ~0.5-1 ثانية على الاتصالات المتوسطة.

## فهم تكوين الحزمة

### هيكل حزمة Flutter Web

```
build/web/
├── index.html                    # ~2-5 KB
├── main.dart.js                  # 🔴 الحزمة الرئيسية (500KB - 10MB+)
├── main.dart.js.map              # Source maps (للتطوير فقط)
├── flutter.js                    # ~50 KB
├── flutter_service_worker.js     # ~10 KB
├── manifest.json                 # ~1 KB
├── favicon.png                   # ~1-5 KB
├── icons/                        # أيقونات التطبيق
├── assets/
│   ├── AssetManifest.json        # قائمة الأصول
│   ├── FontManifest.json         # قائمة الخطوط
│   ├── fonts/                    # ملفات الخطوط
│   ├── images/                   # الصور
│   └── packages/                 # أصول الحزم
└── canvaskit/                    # ~2 MB (إذا مستخدم)
    ├── canvaskit.js
    └── canvaskit.wasm
```

### تحليل المكونات

```
┌─────────────────────────────────────────────────────────────────┐
│              تقسيم حجم الحزمة النموذجي                          │
├─────────────────────────────────────────────────────────────────┤
│  main.dart.js                                                   │
│  ├── Flutter Framework Core         (~400-600 KB)               │
│  ├── Material/Cupertino Widgets     (~200-400 KB)               │
│  ├── Your Application Code          (~100-500 KB)               │
│  ├── Third-party Packages           (~200KB - 5MB+)  🔴         │
│  └── Unused Code (if not optimized) (~100-500 KB)   🔴         │
├─────────────────────────────────────────────────────────────────┤
│  المجموع النموذجي: 1-8 MB                                       │
│  الهدف: < 1.5 MB للحزمة الأولية                                 │
└─────────────────────────────────────────────────────────────────┘
```

## أدوات تحليل الحجم

### 1. Flutter Build Size Analysis

```bash
# بناء مع تقرير الحجم
flutter build web --release --analyze-size

# سيُنشئ ملف JSON للتحليل
# يمكن فتحه في DevTools
```

### 2. Source Map Explorer

```bash
# تثبيت الأداة
npm install -g source-map-explorer

# بناء مع Source Maps
flutter build web --release --source-maps

# تحليل الحزمة
source-map-explorer build/web/main.dart.js \
  --html report.html
```

### 3. Webpack Bundle Analyzer (للمقارنة)

```bash
# إنشاء تقرير مرئي
npx webpack-bundle-analyzer build/web/main.dart.js.map
```

### 4. سكريبت تحليل مخصص

```dart
// tools/analyze_bundle.dart
import 'dart:io';
import 'dart:convert';

void main() async {
  final buildDir = Directory('build/web');
  final report = <String, int>{};
  
  await for (final entity in buildDir.list(recursive: true)) {
    if (entity is File) {
      final size = await entity.length();
      final extension = entity.path.split('.').last;
      report[extension] = (report[extension] ?? 0) + size;
    }
  }
  
  print('=== Bundle Size Report ===');
  report.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value))
    ..forEach((e) {
      print('${e.key}: ${_formatSize(e.value)}');
    });
  
  // تحليل main.dart.js
  final mainJs = File('build/web/main.dart.js');
  if (await mainJs.exists()) {
    final size = await mainJs.length();
    print('\n=== main.dart.js Analysis ===');
    print('Total Size: ${_formatSize(size)}');
    print('Gzipped (estimated): ${_formatSize((size * 0.3).round())}');
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}
```

## استراتيجيات تقليل الحجم

### 1. تحسين الـ Dependencies

#### تحليل الحزم المستخدمة

```yaml
# pubspec.yaml - قبل التحسين
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  dio: ^5.3.0              # ❌ تكرار - استخدم واحداً فقط
  provider: ^6.0.0
  riverpod: ^2.4.0         # ❌ تكرار - استخدم واحداً فقط
  get: ^4.6.0              # ❌ تكرار - استخدم واحداً فقط
  firebase_core: ^2.0.0
  firebase_auth: ^4.0.0
  firebase_firestore: ^4.0.0
  firebase_storage: ^11.0.0
  firebase_messaging: ^14.0.0
  image_picker: ^1.0.0
  camera: ^0.10.0
  video_player: ^2.8.0
  google_maps_flutter: ^2.5.0
  charts_flutter: ^0.14.0
  syncfusion_flutter_charts: ^23.0.0  # ❌ حزمة ضخمة
```

```yaml
# pubspec.yaml - بعد التحسين
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP client - واحد فقط
  dio: ^5.3.0
  
  # State Management - واحد فقط
  riverpod: ^2.4.0
  
  # Firebase - فقط ما تحتاجه
  firebase_core: ^2.0.0
  firebase_auth: ^4.0.0
  # firebase_firestore: # أزلها إذا لم تستخدمها
  
  # استبدال الحزم الضخمة ببدائل أخف
  fl_chart: ^0.66.0  # ✅ بديل أخف لـ charts
```

#### قائمة الحزم الثقيلة وبدائلها

| الحزمة الثقيلة | الحجم | البديل الأخف | الحجم |
|---------------|-------|--------------|-------|
| syncfusion_* | 5-15 MB | fl_chart / custom | < 500 KB |
| google_maps_flutter | 2+ MB | flutter_map | < 300 KB |
| video_player | 1+ MB | chewie (للويب فقط) | < 200 KB |
| firebase_* (كامل) | 3+ MB | firebase_core + ما تحتاجه | < 1 MB |
| intl (كامل) | 500+ KB | intl مع locales محددة | < 100 KB |

### 2. Tree Shaking الفعال

```dart
// ❌ استيراد كل شيء
import 'package:flutter/material.dart';
import 'package:my_icons/my_icons.dart';

// ✅ استيراد ما تحتاجه فقط (للحزم الكبيرة)
import 'package:flutter/material.dart' show 
  MaterialApp, 
  Scaffold, 
  AppBar,
  Container,
  Text,
  ElevatedButton;

// ✅ للأيقونات - استخدم const
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.home); // ✅ سيتم تضمين الأيقونة المستخدمة فقط
  }
}
```

### 3. تجنب الـ Reflection

```dart
// ❌ يمنع Tree Shaking
final instance = reflectClass(MyClass).newInstance(Symbol(''), []);

// ❌ استخدام mirrors
import 'dart:mirrors';

// ✅ استخدم Factory Pattern بدلاً
abstract class Service {
  static Service create(String type) {
    switch (type) {
      case 'auth': return AuthService();
      case 'api': return ApiService();
      default: throw UnimplementedError();
    }
  }
}
```

### 4. تحسين الـ Barrel Files

```dart
// ❌ barrel file يصدّر كل شيء
// lib/widgets/widgets.dart
export 'button.dart';
export 'card.dart';
export 'dialog.dart';
export 'form.dart';
export 'table.dart';
// ... 50+ widgets

// ❌ الاستيراد من barrel يحمّل كل شيء
import 'package:my_app/widgets/widgets.dart';

// ✅ استيراد مباشر
import 'package:my_app/widgets/button.dart';
import 'package:my_app/widgets/card.dart';
```

### 5. تقسيم الكود (Code Splitting)

```dart
// lib/main.dart
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // استخدم routes مع deferred loading
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => HomePage(),
            );
          case '/dashboard':
            // تحميل مؤجل للصفحات الثقيلة
            return MaterialPageRoute(
              builder: (_) => FutureBuilder(
                future: _loadDashboard(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data!;
                  }
                  return LoadingScreen();
                },
              ),
            );
          default:
            return MaterialPageRoute(builder: (_) => NotFoundPage());
        }
      },
    );
  }
}

// سيتم تغطية هذا بالتفصيل في 03-deferred-loading.md
```

## إعدادات البناء المحسنة

### 1. أوامر البناء

```bash
# بناء أساسي محسن
flutter build web \
  --release \
  --web-renderer html \
  --dart2js-optimization O4 \
  --no-source-maps

# بناء مع Tree Shaking قوي
flutter build web \
  --release \
  --web-renderer html \
  --tree-shake-icons
```

### 2. تكوين pubspec.yaml

```yaml
# pubspec.yaml
flutter:
  # تفعيل Tree Shaking للخطوط
  fonts:
    - family: CustomFont
      fonts:
        - asset: fonts/CustomFont-Regular.ttf
        - asset: fonts/CustomFont-Bold.ttf
          weight: 700
  
  # تحديد الأصول بدقة
  assets:
    - assets/images/logo.png
    # ❌ تجنب: - assets/images/
    # ✅ حدد الملفات المطلوبة فقط

# تكوين البناء
dependency_overrides:
  # إصلاح مشاكل الإصدارات إذا لزم الأمر
```

### 3. تكوين analysis_options.yaml

```yaml
# analysis_options.yaml
analyzer:
  errors:
    unused_import: error
    unused_local_variable: warning
    dead_code: warning
  
linter:
  rules:
    - avoid_unused_constructor_parameters
    - unnecessary_import
    - unused_element
    - unused_field
    - unused_import
    - unused_local_variable
```

## تحسينات متقدمة

### 1. إزالة الـ Debug Code

```dart
// lib/config/app_config.dart
import 'package:flutter/foundation.dart';

class AppConfig {
  // سيتم إزالته في Release
  static void debugLog(String message) {
    if (kDebugMode) {
      print('[DEBUG] $message');
    }
  }
  
  // استخدم assert للتحقق في Debug فقط
  static void validateConfig() {
    assert(() {
      // هذا الكود سيُزال في Release
      print('Validating config...');
      return true;
    }());
  }
}
```

### 2. تحسين JSON Serialization

```dart
// ❌ استخدام reflection-based serialization
// يمنع Tree Shaking ويضيف حجماً

// ✅ استخدم json_serializable مع build_runner
// pubspec.yaml
dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.7.0

// models/user.dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String name;
  final String email;
  
  User({required this.id, required this.name, required this.email});
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

### 3. تجميع الثوابت

```dart
// ❌ ثوابت متفرقة
class Screen1 {
  static const padding = 16.0;
}
class Screen2 {
  static const padding = 16.0; // تكرار
}

// ✅ ثوابت مركزية
// lib/core/constants/dimensions.dart
class Dimensions {
  Dimensions._();
  
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  static const double borderRadius = 8.0;
  static const double iconSize = 24.0;
}
```

### 4. تحسين الـ Enums

```dart
// ❌ enum مع قيم كثيرة غير مستخدمة
enum AllIcons {
  home, settings, profile, /* ... 100+ قيمة */
}

// ✅ استخدم فقط ما تحتاجه
enum AppIcon {
  home,
  settings,
  profile,
}

extension AppIconExtension on AppIcon {
  IconData get icon {
    switch (this) {
      case AppIcon.home: return Icons.home;
      case AppIcon.settings: return Icons.settings;
      case AppIcon.profile: return Icons.person;
    }
  }
}
```

## قياس التحسينات

### سكريبت المقارنة

```bash
#!/bin/bash
# scripts/measure_bundle.sh

echo "=== Measuring Bundle Size ==="

# قياس قبل التحسين
echo "Building before optimization..."
flutter build web --release
BEFORE_SIZE=$(du -sb build/web/main.dart.js | cut -f1)

# تطبيق التحسينات (يدوياً أو عبر سكريبت)

# قياس بعد التحسين
echo "Building after optimization..."
flutter build web --release --web-renderer html --tree-shake-icons
AFTER_SIZE=$(du -sb build/web/main.dart.js | cut -f1)

# حساب الفرق
DIFF=$((BEFORE_SIZE - AFTER_SIZE))
PERCENT=$((DIFF * 100 / BEFORE_SIZE))

echo ""
echo "=== Results ==="
echo "Before: $(numfmt --to=iec $BEFORE_SIZE)"
echo "After: $(numfmt --to=iec $AFTER_SIZE)"
echo "Saved: $(numfmt --to=iec $DIFF) ($PERCENT%)"
```

### جدول الأهداف

| مستوى التطبيق | الحجم الأولي | الهدف | التحسين المتوقع |
|--------------|--------------|-------|-----------------|
| بسيط | 2 MB | < 800 KB | 60% |
| متوسط | 4 MB | < 1.5 MB | 62% |
| معقد | 8 MB | < 3 MB | 62% |

## قائمة المراجعة

```markdown
## Bundle Optimization Checklist

### الحزم والتبعيات
- [ ] مراجعة كل dependency وإزالة غير المستخدمة
- [ ] استبدال الحزم الثقيلة ببدائل أخف
- [ ] تجنب الحزم المكررة (http vs dio, provider vs riverpod)
- [ ] استخدام dependency_overrides لإصلاح التعارضات

### الكود
- [ ] إزالة الـ imports غير المستخدمة
- [ ] تجنب barrel files للحزم الكبيرة
- [ ] استخدام const constructors
- [ ] إزالة debug code في Release

### البناء
- [ ] استخدام --release flag
- [ ] تفعيل --tree-shake-icons
- [ ] اختيار المحرك المناسب (html لمعظم الحالات)
- [ ] تعطيل source-maps في Production

### القياس
- [ ] قياس الحجم قبل وبعد كل تحسين
- [ ] استخدام source-map-explorer للتحليل
- [ ] مقارنة مع الأهداف المحددة
```

## الأخطاء الشائعة

### ❌ إضافة حزم بدون تقييم

```yaml
# لا تفعل هذا
dependencies:
  awesome_package: ^1.0.0  # لم تختبر حجمها
```

### ✅ تقييم الحزمة قبل الإضافة

```bash
# 1. تحقق من الحجم على pub.dev
# 2. اختبر التأثير على حجم الحزمة
flutter build web --release
du -h build/web/main.dart.js
# 3. قارن قبل وبعد الإضافة
```

---

**المرجع السابق:** [01-renderer-selection.md](./01-renderer-selection.md)
**المرجع التالي:** [03-deferred-loading.md](./03-deferred-loading.md)
