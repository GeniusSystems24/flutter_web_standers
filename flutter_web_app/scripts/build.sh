#!/bin/bash
# ==========================================
# سكربت البناء المحسن (14-build-configuration.md)
# ==========================================
#
# هذا الملف يطبق:
# - معيار 14: إعدادات البناء المثلى
# - تحسين dart2js
# - Tree Shaking للأيقونات

set -e

echo "🔨 بناء Flutter Web المحسن..."
echo "================================"

# المتغيرات
RENDERER="${1:-auto}"  # html, canvaskit, auto
ENVIRONMENT="${2:-production}"

echo "📋 الإعدادات:"
echo "   - المحرك: $RENDERER"
echo "   - البيئة: $ENVIRONMENT"
echo ""

# تنظيف البناء السابق
echo "🧹 تنظيف البناء السابق..."
flutter clean
rm -rf build/web

# البناء مع الإعدادات المثلى
echo ""
echo "🚀 بدء البناء..."

flutter build web \
  --release \
  --web-renderer "$RENDERER" \
  --tree-shake-icons \
  --dart-define=ENVIRONMENT="$ENVIRONMENT" \
  --dart-define=APP_VERSION="1.0.0" \
  --dart-define=ENABLE_ANALYTICS=true \
  --dart-define=ENABLE_CRASH_REPORTING=true

# التحقق من نجاح البناء
if [ ! -f "build/web/main.dart.js" ]; then
  echo "❌ فشل البناء!"
  exit 1
fi

# إحصائيات الحجم
echo ""
echo "📊 إحصائيات الحجم:"
echo "==================="

MAIN_SIZE=$(du -h build/web/main.dart.js | cut -f1)
echo "   main.dart.js: $MAIN_SIZE"

if [ -f "build/web/flutter.js" ]; then
  FLUTTER_SIZE=$(du -h build/web/flutter.js | cut -f1)
  echo "   flutter.js: $FLUTTER_SIZE"
fi

TOTAL_SIZE=$(du -sh build/web | cut -f1)
echo "   المجموع: $TOTAL_SIZE"

# فحص الأهداف
echo ""
echo "🎯 فحص الأهداف:"
echo "================"

MAIN_KB=$(du -k build/web/main.dart.js | cut -f1)
if [ "$MAIN_KB" -lt 1500 ]; then
  echo "   ✅ main.dart.js < 1.5MB"
else
  echo "   ⚠️  main.dart.js > 1.5MB (تحتاج تحسين)"
fi

echo ""
echo "✅ تم البناء بنجاح!"
echo "   المسار: build/web/"
