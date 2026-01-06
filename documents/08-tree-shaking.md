# 🌳 Tree Shaking وإزالة الكود غير المستخدم

## المقدمة

Tree Shaking هو عملية إزالة الكود غير المستخدم من الحزمة النهائية. هذا ضروري جداً لـ Flutter Web حيث كل كيلوبايت يؤثر على وقت التحميل.

```
┌─────────────────────────────────────────────────────────────────┐
│                        Tree Shaking                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   قبل Tree Shaking              بعد Tree Shaking               │
│                                                                 │
│   ┌──────────────┐              ┌──────────────┐               │
│   │   📦 App     │              │   📦 App     │               │
│   │  ┌────────┐  │              │  ┌────────┐  │               │
│   │  │ Used ✓ │  │    ──────►   │  │ Used ✓ │  │               │
│   │  └────────┘  │              │  └────────┘  │               │
│   │  ┌────────┐  │              │              │               │
│   │  │Unused ✗│  │              │  4MB → 1MB   │               │
│   │  └────────┘  │              │              │               │
│   └──────────────┘              └──────────────┘               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## كيف يعمل Tree Shaking في Dart

```
┌─────────────────────────────────────────────────────────────────┐
│                    مراحل الـ Compilation                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Parse Code                                                  │
│       ↓                                                         │
│  2. Build Dependency Graph (من main.dart)                       │
│       ↓                                                         │
│  3. Mark Reachable Code                                         │
│       ↓                                                         │
│  4. Remove Unreachable Code ← Tree Shaking                      │
│       ↓                                                         │
│  5. Optimize & Minify                                           │
│       ↓                                                         │
│  6. Generate JavaScript                                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1. تفعيل Tree Shaking الأمثل

### أوامر البناء

```bash
# ✅ أفضل إعدادات Tree Shaking
flutter build web \
  --release \
  --web-renderer html \
  --tree-shake-icons \
  --dart2js-optimization O4 \
  --no-source-maps

# للإنتاج مع تحليل
flutter build web \
  --release \
  --tree-shake-icons \
  --analyze-size
```

### مستويات التحسين

| المستوى | الوصف | الحجم | السرعة |
|---------|-------|-------|--------|
| O0 | بدون تحسين | كبير | أبطأ |
| O1 | تحسين بسيط | متوسط | متوسط |
| O2 | افتراضي | جيد | جيد |
| O3 | تحسين عالي | صغير | أسرع |
| O4 | أقصى تحسين | أصغر | أسرع |

---

## 2. Tree Shaking للأيقونات

### المشكلة: Material Icons الكاملة

```
┌─────────────────────────────────────────────────────────────────┐
│                   حجم الأيقونات                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Material Icons كاملة:     ~1.5 MB                            │
│   بعد Tree Shaking:         ~50-100 KB (حسب الاستخدام)         │
│                                                                 │
│   التوفير: 90%+ 🎉                                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### التفعيل

```yaml
# pubspec.yaml
flutter:
  uses-material-design: true
  # هذا يُفعّل tree shaking تلقائياً مع --tree-shake-icons
```

```bash
# البناء مع tree shaking للأيقونات
flutter build web --release --tree-shake-icons
```

### ممارسات الأيقونات الصحيحة

```dart
// ❌ خطأ: استيراد ديناميكي يمنع tree shaking
class BadIconUsage extends StatelessWidget {
  final String iconName;
  
  @override
  Widget build(BuildContext context) {
    // لن يعمل tree shaking!
    return Icon(
      IconData(
        _getIconCode(iconName),
        fontFamily: 'MaterialIcons',
      ),
    );
  }
  
  int _getIconCode(String name) {
    // هذا يجبر تضمين كل الأيقونات
    final icons = {
      'home': 0xe318,
      'settings': 0xe8b8,
      // ...
    };
    return icons[name] ?? 0;
  }
}

// ✅ صحيح: استخدام Icons constants مباشرة
class GoodIconUsage extends StatelessWidget {
  final IconType type;
  
  const GoodIconUsage({required this.type, super.key});
  
  @override
  Widget build(BuildContext context) {
    // Tree shaking يحذف الأيقونات غير المستخدمة
    return Icon(_getIcon());
  }
  
  IconData _getIcon() {
    return switch (type) {
      IconType.home => Icons.home,
      IconType.settings => Icons.settings,
      IconType.profile => Icons.person,
    };
  }
}

enum IconType { home, settings, profile }
```

### استخدام أيقونات SVG بدلاً من Material Icons

```dart
// pubspec.yaml
// dependencies:
//   flutter_svg: ^2.0.9

import 'package:flutter_svg/flutter_svg.dart';

class SvgIconWidget extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  
  const SvgIconWidget({
    required this.name,
    this.size = 24,
    this.color,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}

// أيقونات محددة فقط - حجم صغير جداً
class AppIcons {
  AppIcons._();
  
  static const home = SvgIconWidget(name: 'home');
  static const settings = SvgIconWidget(name: 'settings');
  static const profile = SvgIconWidget(name: 'profile');
}
```

---

## 3. تجنب ما يكسر Tree Shaking

### 1. Reflection وMirrors

```dart
// ❌ خطأ: dart:mirrors يمنع tree shaking
import 'dart:mirrors'; // غير متاح في Web أصلاً

void badReflection() {
  final mirror = reflect(myObject);
  // ...
}

// ✅ صحيح: استخدام code generation
// مثال مع json_serializable

// user.dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String name;
  final String email;
  
  User({
    required this.id,
    required this.name,
    required this.email,
  });
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

### 2. Dynamic Types

```dart
// ❌ خطأ: dynamic يمنع التحليل الثابت
dynamic badFunction(dynamic input) {
  return input.someMethod(); // الcompiler لا يعرف ما هي
}

// ✅ صحيح: أنواع محددة
String goodFunction(User user) {
  return user.name; // الcompiler يعرف بالضبط
}

// ✅ أفضل: generics مع constraints
T processItem<T extends Serializable>(T item) {
  return item..process();
}
```

### 3. String-based Routing

```dart
// ❌ خطأ: أسماء نصية تمنع tree shaking
class BadRouter {
  static Widget getPage(String name) {
    switch (name) {
      case 'home':
        return HomePage();
      case 'settings':
        return SettingsPage();
      case 'profile':
        return ProfilePage();
      // كل الصفحات تُضمّن حتى لو لم تُستخدم
      default:
        return NotFoundPage();
    }
  }
}

// ✅ صحيح: Type-safe routing مع deferred loading
enum AppRoute { home, settings, profile }

class GoodRouter {
  static final Map<AppRoute, Widget Function()> _builders = {
    AppRoute.home: () => const HomePage(),
    AppRoute.settings: () => const SettingsPage(),
    AppRoute.profile: () => const ProfilePage(),
  };
  
  static Widget getPage(AppRoute route) {
    return _builders[route]?.call() ?? const NotFoundPage();
  }
}
```

---

## 4. تحسين الاستيراد (Imports)

### Barrel Files Problem

```dart
// ❌ خطأ: barrel file يستورد كل شيء
// lib/widgets/widgets.dart
export 'button.dart';
export 'card.dart';
export 'dialog.dart';
export 'drawer.dart';
export 'form_field.dart';
export 'header.dart';
export 'footer.dart';
export 'table.dart';
export 'chart.dart'; // مكتبة ثقيلة!

// الاستخدام
import 'package:myapp/widgets/widgets.dart';
// ^ هذا يستورد كل شيء حتى لو استخدمت Button فقط!

// ✅ صحيح: استيراد مباشر
import 'package:myapp/widgets/button.dart';
// ^ فقط ما تحتاجه
```

### Show/Hide للاستيراد الانتقائي

```dart
// ✅ استيراد محدد
import 'package:flutter/material.dart' show 
    Widget, 
    StatelessWidget, 
    BuildContext,
    Text,
    Container,
    Column,
    Row;

// ✅ إخفاء ما لا تحتاجه
import 'package:some_package/some_package.dart' hide HeavyWidget;
```

### تنظيم الاستيرادات

```dart
// lib/core/imports.dart
// استيرادات مشتركة خفيفة فقط

export 'package:flutter/material.dart' show
    Widget,
    StatelessWidget,
    StatefulWidget,
    State,
    BuildContext,
    Key,
    ValueKey,
    Text,
    Container,
    SizedBox,
    Column,
    Row,
    Expanded,
    Padding,
    Center,
    GestureDetector,
    InkWell;

export 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

// الاستخدام
import 'package:myapp/core/imports.dart';
```

---

## 5. تحليل الحزمة وتحديد الكود غير المستخدم

### استخدام --analyze-size

```bash
# بناء مع تحليل الحجم
flutter build web --analyze-size

# النتيجة تُحفظ في
# build/app-size-analysis.json
```

### تحليل الـ Bundle

```bash
# تثبيت أداة التحليل
npm install -g source-map-explorer

# تحليل main.dart.js
source-map-explorer build/web/main.dart.js.map

# أو استخدام webpack-bundle-analyzer
npx webpack-bundle-analyzer build/web/main.dart.js.map
```

### سكربت تحليل مخصص

```bash
#!/bin/bash
# analyze-bundle.sh

echo "🔍 تحليل حزمة Flutter Web..."

# البناء مع التحليل
flutter build web --release --analyze-size 2>&1 | tee build-log.txt

# استخراج الأحجام
echo ""
echo "📊 أحجام الملفات:"
echo "==================="

# حجم main.dart.js
MAIN_SIZE=$(du -h build/web/main.dart.js | cut -f1)
echo "main.dart.js: $MAIN_SIZE"

# حجم flutter.js
FLUTTER_SIZE=$(du -h build/web/flutter.js | cut -f1)
echo "flutter.js: $FLUTTER_SIZE"

# حجم المجلد الكلي
TOTAL_SIZE=$(du -sh build/web | cut -f1)
echo "Total: $TOTAL_SIZE"

# أكبر 10 ملفات
echo ""
echo "📁 أكبر 10 ملفات:"
echo "=================="
find build/web -type f -exec du -h {} \; | sort -rh | head -10

# تحليل الـ dependencies
echo ""
echo "📦 تحليل الـ Dependencies:"
echo "=========================="
flutter pub deps --style=compact | head -30
```

### Dart DevTools للتحليل

```dart
// في main.dart للتطوير فقط
import 'package:flutter/foundation.dart';

void main() {
  if (kDebugMode) {
    // تفعيل DevTools
    debugPrintRebuildDirtyWidgets = true;
  }
  
  runApp(const MyApp());
}
```

---

## 6. إزالة Debug Code

### Conditional Compilation

```dart
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = kReleaseMode
      ? 'https://api.production.com'
      : 'https://api.staging.com';
  
  void logRequest(String endpoint) {
    // يُحذف تماماً في release
    if (kDebugMode) {
      print('API Request: $endpoint');
    }
  }
}

// أفضل: استخدام assert
class BetterService {
  void process(Data data) {
    // يُحذف تماماً في release
    assert(() {
      print('Processing: $data');
      return true;
    }());
    
    // الكود الفعلي
    _doProcess(data);
  }
}
```

### إزالة Logs

```dart
// lib/core/logger.dart
import 'package:flutter/foundation.dart';

class Logger {
  static void debug(String message) {
    if (kDebugMode) {
      print('[DEBUG] $message');
    }
  }
  
  static void info(String message) {
    if (kDebugMode) {
      print('[INFO] $message');
    }
  }
  
  static void error(String message, [Object? error, StackTrace? stack]) {
    // الأخطاء تُسجل دائماً
    print('[ERROR] $message');
    if (error != null) print(error);
    if (stack != null && kDebugMode) print(stack);
  }
}

// استخدام conditional import للـ logging المتقدم
// lib/core/logger_stub.dart (للـ release)
class AdvancedLogger {
  void log(String message) {} // فارغ - يُحذف
}

// lib/core/logger_impl.dart (للـ debug)
class AdvancedLogger {
  void log(String message) => print(message);
}
```

---

## 7. تحسين Dependencies

### تحليل الـ Dependencies

```bash
# عرض شجرة الـ dependencies
flutter pub deps

# عرض الـ dependencies غير المستخدمة
dart pub outdated

# تحليل تفصيلي
flutter pub deps --style=list | grep -E "^\s" | wc -l
# يعطيك عدد الـ dependencies
```

### استبدال الحزم الثقيلة

```yaml
# ❌ ثقيلة
dependencies:
  intl: ^0.18.0           # ~300KB
  http: ^1.1.0            # بسيطة
  dio: ^5.3.0             # ~150KB مع كل الميزات
  cached_network_image: ^3.3.0  # يستورد حزم كثيرة

# ✅ خفيفة
dependencies:
  # استخدم DateFormat البسيط بدلاً من intl الكامل
  # أو استورد فقط ما تحتاجه
  intl: ^0.18.0
  
  # http أخف من dio إذا لم تحتج interceptors
  http: ^1.1.0
  
  # للصور المخزنة: استخدم extended_image أو اكتب حلك
```

### فحص حجم كل Dependency

```dart
// scripts/analyze_deps.dart
import 'dart:io';

void main() async {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  
  print('📦 تحليل Dependencies...\n');
  
  // قائمة الحزم المعروفة بحجمها
  final heavyPackages = {
    'firebase_core': '~200KB',
    'cloud_firestore': '~500KB',
    'google_maps_flutter': '~400KB',
    'syncfusion_flutter_charts': '~2MB',
    'flutter_bloc': '~50KB',
    'provider': '~20KB',
    'dio': '~100KB',
    'http': '~30KB',
  };
  
  for (final package in heavyPackages.entries) {
    if (pubspec.contains(package.key)) {
      print('⚠️  ${package.key}: ${package.value}');
    }
  }
}
```

---

## 8. Part Files vs Imports

```dart
// ❌ خطأ: ملفات كثيرة منفصلة
// user_model.dart
class User { ... }

// user_model_extensions.dart
extension UserExtensions on User { ... }

// user_model_validators.dart
class UserValidator { ... }

// ✅ صحيح: استخدام part للملفات المرتبطة
// user.dart
part 'user_extensions.dart';
part 'user_validators.dart';

class User {
  final String id;
  final String name;
  
  User({required this.id, required this.name});
}

// user_extensions.dart
part of 'user.dart';

extension UserExtensions on User {
  String get displayName => name.toUpperCase();
}

// user_validators.dart
part of 'user.dart';

class UserValidator {
  static bool isValid(User user) => user.name.isNotEmpty;
}
```

---

## 9. Conditional Features

```dart
// lib/features/premium/premium.dart
import 'package:flutter/foundation.dart';

// تعريف الميزات
abstract class FeatureFlags {
  static const bool enablePremium = bool.fromEnvironment(
    'ENABLE_PREMIUM',
    defaultValue: false,
  );
  
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );
  
  static const bool enableExperiments = kDebugMode;
}

// استخدام conditional
class AppFeatures {
  Widget getPremiumWidget() {
    if (!FeatureFlags.enablePremium) {
      // هذا الكود يُحذف إذا كانت الميزة معطلة
      return const SizedBox.shrink();
    }
    return const PremiumFeatureWidget();
  }
}
```

### البناء مع Feature Flags

```bash
# بناء بدون premium features
flutter build web \
  --release \
  --dart-define=ENABLE_PREMIUM=false \
  --dart-define=ENABLE_ANALYTICS=true

# بناء مع كل الميزات
flutter build web \
  --release \
  --dart-define=ENABLE_PREMIUM=true \
  --dart-define=ENABLE_ANALYTICS=true
```

---

## 10. قياس تأثير Tree Shaking

### سكربت المقارنة

```bash
#!/bin/bash
# compare-tree-shaking.sh

echo "📊 مقارنة تأثير Tree Shaking"
echo "============================"

# بناء بدون tree shaking للأيقونات
echo "🔨 Building without icon tree shaking..."
flutter build web --release --no-tree-shake-icons > /dev/null 2>&1
SIZE_WITHOUT=$(du -k build/web/main.dart.js | cut -f1)

# بناء مع tree shaking
echo "🔨 Building with icon tree shaking..."
flutter build web --release --tree-shake-icons > /dev/null 2>&1
SIZE_WITH=$(du -k build/web/main.dart.js | cut -f1)

# الحساب
SAVED=$((SIZE_WITHOUT - SIZE_WITH))
PERCENT=$((SAVED * 100 / SIZE_WITHOUT))

echo ""
echo "📈 النتائج:"
echo "بدون Tree Shaking: ${SIZE_WITHOUT}KB"
echo "مع Tree Shaking: ${SIZE_WITH}KB"
echo "التوفير: ${SAVED}KB (${PERCENT}%)"
```

---

## قائمة المراجعة

```
□ تفعيل --tree-shake-icons في البناء
□ استخدام -O4 للتحسين الأقصى
□ تجنب dynamic types قدر الإمكان
□ استيراد محدد بدلاً من barrel files
□ إزالة debug code باستخدام kDebugMode
□ استبدال الحزم الثقيلة ببدائل خفيفة
□ تحليل الحزمة بانتظام مع --analyze-size
□ استخدام const constructors
□ تجنب reflection و mirrors
□ استخدام feature flags للميزات الاختيارية
```

---

## الملفات ذات الصلة

- [02-bundle-optimization.md](02-bundle-optimization.md) - تحسين الحزمة
- [03-deferred-loading.md](03-deferred-loading.md) - التحميل المؤجل
- [14-build-configuration.md](14-build-configuration.md) - إعدادات البناء
