# التحميل المؤجل والكسول (Deferred Loading)

## المقدمة

التحميل المؤجل (Deferred Loading) هو **أقوى تقنية** لتحسين وقت الإقلاع. بدلاً من تحميل كل الكود دفعة واحدة، يتم تحميل الأجزاء عند الحاجة فقط.

## المفهوم الأساسي

```
┌─────────────────────────────────────────────────────────────────┐
│                    بدون التحميل المؤجل                          │
├─────────────────────────────────────────────────────────────────┤
│  main.dart.js (4 MB)                                            │
│  ├── Home Screen Code                                           │
│  ├── Dashboard Code                                             │
│  ├── Settings Code                                              │
│  ├── Reports Code                                               │
│  ├── Admin Panel Code                                           │
│  └── All Features Code                                          │
│                                                                 │
│  ⏱️ وقت التحميل: 5-8 ثواني                                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    مع التحميل المؤجل                            │
├─────────────────────────────────────────────────────────────────┤
│  main.dart.js (800 KB) - يُحمّل فوراً                           │
│  ├── Core Framework                                             │
│  ├── Home Screen Code                                           │
│  └── Essential Code Only                                        │
│                                                                 │
│  dashboard.part.js (500 KB) - يُحمّل عند الطلب                  │
│  settings.part.js (200 KB) - يُحمّل عند الطلب                   │
│  reports.part.js (800 KB) - يُحمّل عند الطلب                    │
│  admin.part.js (1 MB) - يُحمّل عند الطلب                        │
│                                                                 │
│  ⏱️ وقت التحميل الأولي: 1-2 ثانية                               │
└─────────────────────────────────────────────────────────────────┘
```

## كيفية عمل Deferred Loading في Dart

### الصيغة الأساسية

```dart
// استيراد مؤجل
import 'package:my_app/features/dashboard/dashboard.dart' 
    deferred as dashboard;

// التحميل والاستخدام
Future<void> loadDashboard() async {
  await dashboard.loadLibrary(); // تحميل الكود
  // الآن يمكن استخدام dashboard
  final widget = dashboard.DashboardScreen();
}
```

### الفرق عن الاستيراد العادي

```dart
// ❌ استيراد عادي - يُحمّل مع التطبيق
import 'package:my_app/features/dashboard/dashboard.dart';

// ✅ استيراد مؤجل - يُحمّل عند الحاجة
import 'package:my_app/features/dashboard/dashboard.dart' 
    deferred as dashboard;
```

## تطبيق عملي شامل

### هيكل المشروع

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── router/
│   │   └── app_router.dart
│   ├── widgets/
│   │   └── loading_widget.dart
│   └── utils/
│       └── deferred_loader.dart
└── features/
    ├── home/
    │   └── home_screen.dart           # يُحمّل فوراً
    ├── dashboard/
    │   ├── dashboard_screen.dart      # مؤجل
    │   └── widgets/
    ├── settings/
    │   └── settings_screen.dart       # مؤجل
    ├── reports/
    │   └── reports_screen.dart        # مؤجل
    └── admin/
        └── admin_panel.dart           # مؤجل
```

### 1. إنشاء Deferred Loader عام

```dart
// lib/core/utils/deferred_loader.dart
import 'package:flutter/material.dart';

/// Generic Deferred Loader Widget
class DeferredLoader<T> extends StatefulWidget {
  final Future<void> Function() loadLibrary;
  final T Function() createWidget;
  final Widget? loadingWidget;
  final Widget Function(Object error)? errorBuilder;

  const DeferredLoader({
    Key? key,
    required this.loadLibrary,
    required this.createWidget,
    this.loadingWidget,
    this.errorBuilder,
  }) : super(key: key);

  @override
  State<DeferredLoader<T>> createState() => _DeferredLoaderState<T>();
}

class _DeferredLoaderState<T> extends State<DeferredLoader<T>> {
  late Future<void> _loadFuture;
  
  @override
  void initState() {
    super.initState();
    _loadFuture = widget.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return widget.errorBuilder?.call(snapshot.error!) ??
                _DefaultErrorWidget(error: snapshot.error!);
          }
          return widget.createWidget() as Widget;
        }
        return widget.loadingWidget ?? const _DefaultLoadingWidget();
      },
    );
  }
}

class _DefaultLoadingWidget extends StatelessWidget {
  const _DefaultLoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري التحميل...'),
          ],
        ),
      ),
    );
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  final Object error;
  
  const _DefaultErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('حدث خطأ: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // إعادة المحاولة
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SizedBox()),
                );
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 2. إنشاء Router مع Deferred Loading

```dart
// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import '../utils/deferred_loader.dart';

// الصفحات الأساسية - تُحمّل فوراً
import 'package:my_app/features/home/home_screen.dart';

// الصفحات المؤجلة
import 'package:my_app/features/dashboard/dashboard_screen.dart' 
    deferred as dashboard;
import 'package:my_app/features/settings/settings_screen.dart' 
    deferred as settings;
import 'package:my_app/features/reports/reports_screen.dart' 
    deferred as reports;
import 'package:my_app/features/admin/admin_panel.dart' 
    deferred as admin;

class AppRouter {
  static const String home = '/';
  static const String dashboardRoute = '/dashboard';
  static const String settingsRoute = '/settings';
  static const String reportsRoute = '/reports';
  static const String adminRoute = '/admin';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
        
      case dashboardRoute:
        return MaterialPageRoute(
          builder: (_) => DeferredLoader(
            loadLibrary: dashboard.loadLibrary,
            createWidget: () => dashboard.DashboardScreen(),
            loadingWidget: const _FeatureLoadingScreen(
              featureName: 'لوحة التحكم',
            ),
          ),
        );
        
      case settingsRoute:
        return MaterialPageRoute(
          builder: (_) => DeferredLoader(
            loadLibrary: settings.loadLibrary,
            createWidget: () => settings.SettingsScreen(),
            loadingWidget: const _FeatureLoadingScreen(
              featureName: 'الإعدادات',
            ),
          ),
        );
        
      case reportsRoute:
        return MaterialPageRoute(
          builder: (_) => DeferredLoader(
            loadLibrary: reports.loadLibrary,
            createWidget: () => reports.ReportsScreen(),
            loadingWidget: const _FeatureLoadingScreen(
              featureName: 'التقارير',
            ),
          ),
        );
        
      case adminRoute:
        return MaterialPageRoute(
          builder: (_) => DeferredLoader(
            loadLibrary: admin.loadLibrary,
            createWidget: () => admin.AdminPanel(),
            loadingWidget: const _FeatureLoadingScreen(
              featureName: 'لوحة الإدارة',
            ),
          ),
        );
        
      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundScreen(),
        );
    }
  }
}

class _FeatureLoadingScreen extends StatelessWidget {
  final String featureName;
  
  const _FeatureLoadingScreen({required this.featureName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(featureName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'جاري تحميل $featureName...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('غير موجود')),
      body: const Center(
        child: Text('الصفحة المطلوبة غير موجودة'),
      ),
    );
  }
}
```

### 3. التطبيق الرئيسي

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيقي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
```

### 4. الصفحة الرئيسية (تُحمّل فوراً)

```dart
// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../core/router/app_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NavigationCard(
            title: 'لوحة التحكم',
            icon: Icons.dashboard,
            route: AppRouter.dashboardRoute,
          ),
          _NavigationCard(
            title: 'الإعدادات',
            icon: Icons.settings,
            route: AppRouter.settingsRoute,
          ),
          _NavigationCard(
            title: 'التقارير',
            icon: Icons.analytics,
            route: AppRouter.reportsRoute,
          ),
          _NavigationCard(
            title: 'لوحة الإدارة',
            icon: Icons.admin_panel_settings,
            route: AppRouter.adminRoute,
          ),
        ],
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String route;

  const _NavigationCard({
    required this.title,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
```

## تقنيات متقدمة

### 1. التحميل المسبق (Preloading)

```dart
// lib/core/utils/preloader.dart
import 'package:my_app/features/dashboard/dashboard_screen.dart' 
    deferred as dashboard;
import 'package:my_app/features/settings/settings_screen.dart' 
    deferred as settings;

/// تحميل مسبق للصفحات المتوقع زيارتها
class FeaturePreloader {
  static final Map<String, Future<void>> _loadingFutures = {};
  static final Set<String> _loadedFeatures = {};

  /// تحميل مسبق لميزة معينة
  static Future<void> preload(String feature) async {
    if (_loadedFeatures.contains(feature)) return;
    if (_loadingFutures.containsKey(feature)) {
      return _loadingFutures[feature];
    }

    Future<void> loadFuture;
    switch (feature) {
      case 'dashboard':
        loadFuture = dashboard.loadLibrary();
        break;
      case 'settings':
        loadFuture = settings.loadLibrary();
        break;
      default:
        return;
    }

    _loadingFutures[feature] = loadFuture;
    await loadFuture;
    _loadedFeatures.add(feature);
    _loadingFutures.remove(feature);
  }

  /// تحميل مسبق لعدة ميزات
  static Future<void> preloadAll(List<String> features) async {
    await Future.wait(features.map(preload));
  }

  /// التحقق من حالة التحميل
  static bool isLoaded(String feature) => _loadedFeatures.contains(feature);
}
```

### 2. التحميل المسبق الذكي

```dart
// lib/features/home/home_screen.dart
import '../../core/utils/preloader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // تحميل مسبق للصفحات الأكثر استخداماً بعد رسم الإطار الأول
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _smartPreload();
    });
  }

  void _smartPreload() {
    // تحميل في الخلفية بعد 2 ثانية من الإقلاع
    Future.delayed(const Duration(seconds: 2), () {
      FeaturePreloader.preloadAll(['dashboard', 'settings']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... الواجهة
      body: ListView(
        children: [
          _NavigationCard(
            title: 'لوحة التحكم',
            icon: Icons.dashboard,
            route: AppRouter.dashboardRoute,
            onHover: () {
              // تحميل مسبق عند التحويم
              FeaturePreloader.preload('dashboard');
            },
          ),
          // ... باقي البطاقات
        ],
      ),
    );
  }
}

class _NavigationCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String route;
  final VoidCallback? onHover;

  const _NavigationCard({
    required this.title,
    required this.icon,
    required this.route,
    this.onHover,
  });

  @override
  State<_NavigationCard> createState() => _NavigationCardState();
}

class _NavigationCardState extends State<_NavigationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHover?.call();
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        elevation: _isHovered ? 4 : 1,
        child: ListTile(
          leading: Icon(widget.icon),
          title: Text(widget.title),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => Navigator.pushNamed(context, widget.route),
        ),
      ),
    );
  }
}
```

### 3. تحميل مؤجل للمكونات

```dart
// lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../core/utils/deferred_loader.dart';

// مكونات مؤجلة داخل الصفحة
import 'widgets/charts_section.dart' deferred as charts;
import 'widgets/analytics_section.dart' deferred as analytics;
import 'widgets/reports_section.dart' deferred as reportWidgets;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة التحكم')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // قسم الإحصائيات السريعة (يُحمّل فوراً)
          const QuickStatsSection(),
          
          const SizedBox(height: 24),
          
          // قسم الرسوم البيانية (مؤجل)
          DeferredLoader(
            loadLibrary: charts.loadLibrary,
            createWidget: () => charts.ChartsSection(),
            loadingWidget: const _SectionPlaceholder(
              title: 'الرسوم البيانية',
            ),
          ),
          
          const SizedBox(height: 24),
          
          // قسم التحليلات (مؤجل)
          DeferredLoader(
            loadLibrary: analytics.loadLibrary,
            createWidget: () => analytics.AnalyticsSection(),
            loadingWidget: const _SectionPlaceholder(
              title: 'التحليلات',
            ),
          ),
        ],
      ),
    );
  }
}

class QuickStatsSection extends StatelessWidget {
  const QuickStatsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الإحصائيات السريعة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(title: 'المستخدمين', value: '1,234'),
                _StatItem(title: 'الطلبات', value: '567'),
                _StatItem(title: 'الإيرادات', value: '\$12,345'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;

  const _StatItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(title),
      ],
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  final String title;

  const _SectionPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('جاري تحميل $title...'),
          ],
        ),
      ),
    );
  }
}
```

### 4. تحميل مؤجل مع Retry

```dart
// lib/core/utils/reliable_deferred_loader.dart
import 'package:flutter/material.dart';

class ReliableDeferredLoader extends StatefulWidget {
  final Future<void> Function() loadLibrary;
  final Widget Function() createWidget;
  final Widget? loadingWidget;
  final int maxRetries;
  final Duration retryDelay;

  const ReliableDeferredLoader({
    Key? key,
    required this.loadLibrary,
    required this.createWidget,
    this.loadingWidget,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<ReliableDeferredLoader> createState() => _ReliableDeferredLoaderState();
}

class _ReliableDeferredLoaderState extends State<ReliableDeferredLoader> {
  late Future<void> _loadFuture;
  int _retryCount = 0;
  Object? _lastError;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadWithRetry();
  }

  Future<void> _loadWithRetry() async {
    while (_retryCount < widget.maxRetries) {
      try {
        await widget.loadLibrary();
        return;
      } catch (e) {
        _lastError = e;
        _retryCount++;
        if (_retryCount < widget.maxRetries) {
          await Future.delayed(widget.retryDelay);
        }
      }
    }
    throw _lastError!;
  }

  void _retry() {
    setState(() {
      _retryCount = 0;
      _lastError = null;
      _loadFuture = _loadWithRetry();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return _ErrorWidget(
              error: snapshot.error!,
              onRetry: _retry,
            );
          }
          return widget.createWidget();
        }
        return widget.loadingWidget ?? const _DefaultLoadingWidget();
      },
    );
  }
}

class _DefaultLoadingWidget extends StatelessWidget {
  const _DefaultLoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('فشل التحميل: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
```

## استراتيجيات التقسيم

### 1. التقسيم حسب الميزات (Feature-based)

```
lib/
├── features/
│   ├── auth/           # مؤجل - يُحمّل عند الحاجة للتسجيل
│   ├── home/           # فوري - الصفحة الرئيسية
│   ├── dashboard/      # مؤجل
│   ├── settings/       # مؤجل
│   └── admin/          # مؤجل
```

### 2. التقسيم حسب الأدوار (Role-based)

```dart
// تحميل مؤجل حسب دور المستخدم
import 'package:my_app/features/admin/admin_panel.dart' 
    deferred as admin;
import 'package:my_app/features/user/user_dashboard.dart' 
    deferred as user;

class RoleBasedScreen extends StatelessWidget {
  final UserRole role;
  
  const RoleBasedScreen({required this.role});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case UserRole.admin:
        return DeferredLoader(
          loadLibrary: admin.loadLibrary,
          createWidget: () => admin.AdminPanel(),
        );
      case UserRole.user:
        return DeferredLoader(
          loadLibrary: user.loadLibrary,
          createWidget: () => user.UserDashboard(),
        );
    }
  }
}
```

### 3. التقسيم حسب الحجم (Size-based)

```yaml
# معايير التقسيم
مؤجل (> 100 KB):
  - صفحات الرسوم البيانية
  - صفحات التقارير
  - لوحات الإدارة
  - صفحات التحرير المعقدة

فوري (< 100 KB):
  - الصفحة الرئيسية
  - صفحات تسجيل الدخول
  - الصفحات البسيطة
```

## قياس التأثير

### سكريبت التحليل

```bash
#!/bin/bash
# scripts/analyze_deferred.sh

echo "=== Deferred Loading Analysis ==="

# بناء مع deferred loading
flutter build web --release

# تحليل الملفات المُنتجة
echo "Generated chunks:"
ls -lh build/web/*.part.js 2>/dev/null || echo "No deferred chunks found"

echo ""
echo "Main bundle size:"
ls -lh build/web/main.dart.js

echo ""
echo "Total size:"
du -sh build/web/
```

### جدول النتائج المتوقعة

| السيناريو | بدون Deferred | مع Deferred | التحسين |
|-----------|---------------|-------------|---------|
| main.dart.js | 4 MB | 800 KB | 80% |
| وقت الإقلاع | 6s | 1.5s | 75% |
| LCP | 5s | 1.8s | 64% |
| TTI | 8s | 2.5s | 69% |

## أفضل الممارسات

```markdown
## Deferred Loading Best Practices

### التقسيم
- [ ] الصفحة الرئيسية تُحمّل فوراً
- [ ] الصفحات الثانوية مؤجلة
- [ ] المكونات الثقيلة مؤجلة (Charts, Reports)
- [ ] الميزات حسب الأدوار مؤجلة

### تجربة المستخدم
- [ ] شاشات تحميل جذابة
- [ ] مؤشرات تقدم واضحة
- [ ] معالجة الأخطاء مع إعادة المحاولة
- [ ] تحميل مسبق ذكي

### الأداء
- [ ] قياس حجم كل chunk
- [ ] مراقبة وقت التحميل
- [ ] اختبار على شبكات بطيئة
```

---

**المرجع السابق:** [02-bundle-optimization.md](./02-bundle-optimization.md)
**المرجع التالي:** [04-assets-optimization.md](./04-assets-optimization.md)
