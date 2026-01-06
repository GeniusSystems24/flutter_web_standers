# تحسين الخطوط (Fonts Optimization)

## المقدمة

الخطوط المخصصة يمكن أن تضيف 500 KB - 2 MB لحجم التطبيق. التحسين الصحيح يقلل هذا إلى 100-300 KB مع الحفاظ على الجودة.

## مشاكل الخطوط الشائعة

```
┌─────────────────────────────────────────────────────────────────┐
│                   مشاكل الخطوط في Flutter Web                   │
├─────────────────────────────────────────────────────────────────┤
│  1. FOIT (Flash of Invisible Text)                              │
│     └── النص يختفي أثناء تحميل الخط                             │
│                                                                 │
│  2. FOUT (Flash of Unstyled Text)                               │
│     └── النص يظهر بخط مختلف ثم يتغير                            │
│                                                                 │
│  3. Layout Shift                                                │
│     └── تغير التخطيط عند تحميل الخط                             │
│                                                                 │
│  4. حجم كبير                                                    │
│     └── خطوط TTF/OTF غير محسنة                                  │
│                                                                 │
│  5. تحميل خطوط غير مستخدمة                                      │
│     └── تحميل جميع الأوزان والأنماط                             │
└─────────────────────────────────────────────────────────────────┘
```

## تنسيقات الخطوط

### مقارنة التنسيقات

| التنسيق | الحجم | الدعم | الاستخدام |
|---------|-------|-------|-----------|
| WOFF2 | 🟢 أصغر (30% أقل) | 95%+ | ✅ الأفضل للويب |
| WOFF | 🟡 متوسط | 98%+ | ✅ Fallback |
| TTF | 🔴 كبير | 99%+ | ⚠️ للتطوير فقط |
| OTF | 🔴 كبير | 99%+ | ⚠️ للتطوير فقط |
| EOT | 🔴 قديم | IE فقط | ❌ لا تستخدم |

### تحويل الخطوط إلى WOFF2

```bash
#!/bin/bash
# scripts/convert_fonts.sh

# تثبيت woff2
# apt-get install woff2

INPUT_DIR="assets/fonts"
OUTPUT_DIR="assets/fonts_optimized"

mkdir -p $OUTPUT_DIR

# تحويل TTF إلى WOFF2
for file in $INPUT_DIR/*.ttf; do
  if [ -f "$file" ]; then
    filename=$(basename "$file" .ttf)
    woff2_compress "$file"
    mv "$INPUT_DIR/$filename.woff2" "$OUTPUT_DIR/"
    echo "Converted: $filename.ttf -> $filename.woff2"
  fi
done

# تحويل OTF إلى WOFF2 (يحتاج تحويل إلى TTF أولاً)
for file in $INPUT_DIR/*.otf; do
  if [ -f "$file" ]; then
    filename=$(basename "$file" .otf)
    # استخدم fontforge للتحويل
    fontforge -c 'Open($1); Generate($2)' "$file" "$OUTPUT_DIR/$filename.woff2"
    echo "Converted: $filename.otf -> $filename.woff2"
  fi
done

echo ""
echo "=== Size Comparison ==="
echo "Original:"
du -sh $INPUT_DIR
echo "Optimized:"
du -sh $OUTPUT_DIR
```

## استراتيجيات تحميل الخطوط

### 1. Font Display Strategies

```css
/* web/styles/fonts.css */

/* 1. swap - الأفضل للنص المهم */
@font-face {
  font-family: 'CustomFont';
  src: url('fonts/CustomFont.woff2') format('woff2');
  font-display: swap;
  /* يظهر خط النظام فوراً، ثم يتبدل للخط المخصص */
}

/* 2. optional - للخطوط غير الضرورية */
@font-face {
  font-family: 'DecorativeFont';
  src: url('fonts/DecorativeFont.woff2') format('woff2');
  font-display: optional;
  /* يستخدم الخط فقط إذا كان محمّلاً في الـ cache */
}

/* 3. fallback - توازن بين swap و block */
@font-face {
  font-family: 'HeadingFont';
  src: url('fonts/HeadingFont.woff2') format('woff2');
  font-display: fallback;
  /* ينتظر قليلاً (100ms) ثم يعرض خط النظام */
}
```

### 2. تكوين الخطوط في Flutter

```dart
// lib/core/theme/app_fonts.dart
import 'package:flutter/material.dart';

class AppFonts {
  // الخط الرئيسي
  static const String primary = 'Cairo';
  
  // خط العناوين
  static const String heading = 'Tajawal';
  
  // خط الأكواد
  static const String monospace = 'JetBrains Mono';
  
  // Font Weights المستخدمة فقط
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight bold = FontWeight.w700;
}
```

### 3. تكوين pubspec.yaml المحسن

```yaml
# pubspec.yaml
flutter:
  fonts:
    # الخط الرئيسي - الأوزان المستخدمة فقط
    - family: Cairo
      fonts:
        - asset: assets/fonts/Cairo-Regular.woff2
          weight: 400
        - asset: assets/fonts/Cairo-Medium.woff2
          weight: 500
        - asset: assets/fonts/Cairo-Bold.woff2
          weight: 700
    
    # خط العناوين
    - family: Tajawal
      fonts:
        - asset: assets/fonts/Tajawal-Bold.woff2
          weight: 700
    
    # خط الأكواد (اختياري)
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.woff2
```

## التحميل المؤجل للخطوط

### 1. تحميل الخطوط الأساسية فقط

```html
<!-- web/index.html -->
<head>
  <!-- تحميل مسبق للخط الأساسي فقط -->
  <link rel="preload" 
        href="assets/fonts/Cairo-Regular.woff2" 
        as="font" 
        type="font/woff2" 
        crossorigin>
  
  <!-- تحميل باقي الخطوط بشكل كسول -->
  <style>
    @font-face {
      font-family: 'Cairo';
      src: url('assets/fonts/Cairo-Regular.woff2') format('woff2');
      font-weight: 400;
      font-display: swap;
    }
    
    /* الأوزان الإضافية - تُحمّل عند الحاجة */
    @font-face {
      font-family: 'Cairo';
      src: url('assets/fonts/Cairo-Bold.woff2') format('woff2');
      font-weight: 700;
      font-display: swap;
    }
  </style>
</head>
```

### 2. تحميل ديناميكي للخطوط

```dart
// lib/core/utils/font_loader.dart
import 'dart:html' as html;

class FontLoader {
  static final Set<String> _loadedFonts = {};
  
  /// تحميل خط ديناميكياً
  static Future<void> loadFont(String fontName, String url) async {
    if (_loadedFonts.contains(fontName)) return;
    
    final style = html.StyleElement();
    style.text = '''
      @font-face {
        font-family: '$fontName';
        src: url('$url') format('woff2');
        font-display: swap;
      }
    ''';
    
    html.document.head!.append(style);
    _loadedFonts.add(fontName);
    
    // انتظار تحميل الخط
    await html.document.fonts!.ready;
  }
  
  /// تحميل مجموعة خطوط
  static Future<void> loadFonts(Map<String, String> fonts) async {
    await Future.wait(
      fonts.entries.map((e) => loadFont(e.key, e.value)),
    );
  }
}

// الاستخدام
// await FontLoader.loadFont('DecorativeFont', 'assets/fonts/Decorative.woff2');
```

### 3. تحميل الخطوط حسب اللغة

```dart
// lib/core/utils/locale_font_loader.dart
import 'dart:ui';

class LocaleFontLoader {
  static final Map<String, List<FontConfig>> _localeFonts = {
    'ar': [
      FontConfig('Cairo', 'assets/fonts/Cairo-Regular.woff2', 400),
      FontConfig('Cairo', 'assets/fonts/Cairo-Bold.woff2', 700),
    ],
    'en': [
      FontConfig('Roboto', 'assets/fonts/Roboto-Regular.woff2', 400),
      FontConfig('Roboto', 'assets/fonts/Roboto-Bold.woff2', 700),
    ],
    'ja': [
      FontConfig('NotoSansJP', 'assets/fonts/NotoSansJP-Regular.woff2', 400),
    ],
  };
  
  static Future<void> loadFontsForLocale(Locale locale) async {
    final fonts = _localeFonts[locale.languageCode];
    if (fonts == null) return;
    
    for (final font in fonts) {
      await FontLoader.loadFont(font.family, font.url);
    }
  }
}

class FontConfig {
  final String family;
  final String url;
  final int weight;
  
  FontConfig(this.family, this.url, this.weight);
}
```

## تقليل حجم الخطوط (Subsetting)

### 1. Subsetting للأحرف المستخدمة

```bash
#!/bin/bash
# scripts/subset_fonts.sh

# تثبيت pyftsubset
pip install fonttools brotli

INPUT_FONT="assets/fonts/Cairo-Regular.ttf"
OUTPUT_FONT="assets/fonts/Cairo-Regular-subset.woff2"

# Subset للأحرف العربية والإنجليزية والأرقام
pyftsubset "$INPUT_FONT" \
  --output-file="$OUTPUT_FONT" \
  --flavor=woff2 \
  --unicodes="U+0000-00FF,U+0600-06FF,U+FB50-FDFF,U+FE70-FEFF" \
  --layout-features='*'

echo "Created subset font: $OUTPUT_FONT"
ls -lh "$OUTPUT_FONT"
```

### 2. Subset للنص المعروف

```bash
#!/bin/bash
# scripts/subset_by_text.sh

INPUT_FONT="assets/fonts/Logo-Font.ttf"
OUTPUT_FONT="assets/fonts/Logo-Font-subset.woff2"
TEXT_FILE="text_used.txt"

# إنشاء ملف النص المستخدم
echo "تطبيقي الرائع - My Amazing App - 0123456789" > $TEXT_FILE

# Subset بناءً على النص
pyftsubset "$INPUT_FONT" \
  --output-file="$OUTPUT_FONT" \
  --flavor=woff2 \
  --text-file="$TEXT_FILE" \
  --layout-features='*'

echo "Created text-based subset: $OUTPUT_FONT"
```

### 3. Unicode Ranges للتحميل التدريجي

```css
/* web/styles/fonts.css */

/* الأحرف اللاتينية الأساسية */
@font-face {
  font-family: 'Cairo';
  src: url('fonts/Cairo-latin.woff2') format('woff2');
  unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC;
  font-display: swap;
}

/* الأحرف العربية */
@font-face {
  font-family: 'Cairo';
  src: url('fonts/Cairo-arabic.woff2') format('woff2');
  unicode-range: U+0600-06FF, U+FB50-FDFF, U+FE70-FEFF;
  font-display: swap;
}

/* الأحرف الخاصة (تُحمّل عند الحاجة) */
@font-face {
  font-family: 'Cairo';
  src: url('fonts/Cairo-extended.woff2') format('woff2');
  unicode-range: U+0100-024F, U+1E00-1EFF, U+2000-206F;
  font-display: swap;
}
```

## استخدام Variable Fonts

### مقدمة عن Variable Fonts

```
┌─────────────────────────────────────────────────────────────────┐
│                      Variable Fonts                             │
├─────────────────────────────────────────────────────────────────┤
│  بدلاً من:                                                       │
│  ├── Font-Light.woff2      (50 KB)                              │
│  ├── Font-Regular.woff2    (50 KB)                              │
│  ├── Font-Medium.woff2     (50 KB)                              │
│  ├── Font-Bold.woff2       (50 KB)                              │
│  └── المجموع: 200 KB                                            │
│                                                                 │
│  استخدم:                                                        │
│  └── Font-Variable.woff2   (80 KB)  ✅ أصغر بـ 60%              │
│      └── يدعم جميع الأوزان من 100 إلى 900                       │
└─────────────────────────────────────────────────────────────────┘
```

### تكوين Variable Font

```css
/* web/styles/variable-fonts.css */

@font-face {
  font-family: 'Cairo Variable';
  src: url('fonts/Cairo-Variable.woff2') format('woff2-variations');
  font-weight: 200 900; /* نطاق الأوزان */
  font-stretch: 75% 125%; /* نطاق العرض (إذا مدعوم) */
  font-display: swap;
}
```

```dart
// lib/core/theme/variable_font_theme.dart
import 'package:flutter/material.dart';

class VariableFontTheme {
  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Cairo Variable',
      fontVariations: [FontVariation('wght', 700)],
      fontSize: 57,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Cairo Variable',
      fontVariations: [FontVariation('wght', 600)],
      fontSize: 32,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Cairo Variable',
      fontVariations: [FontVariation('wght', 400)],
      fontSize: 16,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Cairo Variable',
      fontVariations: [FontVariation('wght', 300)],
      fontSize: 14,
    ),
  );
}
```

## خطوط النظام كـ Fallback

```dart
// lib/core/theme/font_fallback.dart
import 'package:flutter/material.dart';

class FontFallback {
  /// Font stack مع fallback للنظام
  static const String primaryFontFamily = 'Cairo, '
      '-apple-system, '
      'BlinkMacSystemFont, '
      '"Segoe UI", '
      'Roboto, '
      '"Helvetica Neue", '
      'Arial, '
      'sans-serif';
  
  /// للخطوط العربية
  static const String arabicFontFamily = 'Cairo, '
      '"Segoe UI", '
      'Tahoma, '
      'Arial, '
      'sans-serif';
  
  /// للأكواد
  static const String monospaceFontFamily = 'JetBrains Mono, '
      'Menlo, '
      'Monaco, '
      '"Courier New", '
      'monospace';
}
```

## قياس أداء الخطوط

### 1. قياس وقت التحميل

```dart
// lib/core/utils/font_performance.dart
import 'dart:html' as html;

class FontPerformance {
  static Future<Map<String, Duration>> measureFontLoadTimes() async {
    final results = <String, Duration>{};
    final performance = html.window.performance;
    
    // الحصول على Resource Timing
    final entries = performance.getEntriesByType('resource');
    
    for (final entry in entries) {
      if (entry.name.contains('.woff2') || entry.name.contains('.woff')) {
        final fontName = entry.name.split('/').last;
        final duration = Duration(
          milliseconds: (entry.duration as num).toInt(),
        );
        results[fontName] = duration;
      }
    }
    
    return results;
  }
  
  static void logFontMetrics() async {
    final metrics = await measureFontLoadTimes();
    print('=== Font Load Times ===');
    metrics.forEach((font, duration) {
      print('$font: ${duration.inMilliseconds}ms');
    });
  }
}
```

### 2. فحص حالة الخطوط

```dart
// lib/core/utils/font_status.dart
import 'dart:html' as html;

class FontStatus {
  /// التحقق من تحميل خط معين
  static Future<bool> isFontLoaded(String fontFamily) async {
    await html.document.fonts!.ready;
    return html.document.fonts!.check('16px $fontFamily');
  }
  
  /// انتظار تحميل جميع الخطوط
  static Future<void> waitForAllFonts() async {
    await html.document.fonts!.ready;
  }
  
  /// الحصول على قائمة الخطوط المحملة
  static List<String> getLoadedFonts() {
    final fonts = <String>[];
    html.document.fonts!.forEach((font, _, __) {
      fonts.add(font.family);
    });
    return fonts;
  }
}
```

## جدول المقارنة

| السيناريو | قبل التحسين | بعد التحسين | التحسين |
|-----------|-------------|-------------|---------|
| 4 أوزان TTF | 800 KB | 250 KB (WOFF2) | 69% |
| خط كامل | 250 KB | 80 KB (Subset) | 68% |
| 4 ملفات WOFF2 | 200 KB | 80 KB (Variable) | 60% |
| وقت FOIT | 2-3 ثواني | 0 (swap) | 100% |

## قائمة المراجعة

```markdown
## Fonts Optimization Checklist

### التنسيق
- [ ] تحويل جميع الخطوط إلى WOFF2
- [ ] إزالة تنسيقات TTF/OTF من Production
- [ ] استخدام Variable Fonts إذا توفرت

### التحميل
- [ ] تطبيق font-display: swap
- [ ] تحميل مسبق للخط الأساسي
- [ ] تحميل مؤجل للخطوط الثانوية

### تقليل الحجم
- [ ] Subsetting للأحرف المستخدمة
- [ ] تحميل الأوزان المستخدمة فقط
- [ ] استخدام Unicode Ranges

### Fallback
- [ ] تحديد font-stack مع fallbacks
- [ ] اختبار على أجهزة بدون الخط

### القياس
- [ ] قياس وقت تحميل الخطوط
- [ ] فحص CLS (Cumulative Layout Shift)
- [ ] اختبار على شبكات بطيئة
```

## الأخطاء الشائعة

### ❌ تحميل جميع الأوزان

```yaml
# لا تفعل هذا
fonts:
  - family: Cairo
    fonts:
      - asset: fonts/Cairo-Thin.woff2
      - asset: fonts/Cairo-ExtraLight.woff2
      - asset: fonts/Cairo-Light.woff2
      - asset: fonts/Cairo-Regular.woff2
      - asset: fonts/Cairo-Medium.woff2
      - asset: fonts/Cairo-SemiBold.woff2
      - asset: fonts/Cairo-Bold.woff2
      - asset: fonts/Cairo-ExtraBold.woff2
      - asset: fonts/Cairo-Black.woff2
```

### ✅ تحميل ما تحتاجه فقط

```yaml
# افعل هذا
fonts:
  - family: Cairo
    fonts:
      - asset: fonts/Cairo-Regular.woff2
        weight: 400
      - asset: fonts/Cairo-Bold.woff2
        weight: 700
```

---

**المرجع السابق:** [04-assets-optimization.md](./04-assets-optimization.md)
**المرجع التالي:** [06-caching-strategies.md](./06-caching-strategies.md)
