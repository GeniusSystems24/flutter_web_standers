# تحسين التحميل الأولي (Initial Load Optimization)

## المقدمة

التحميل الأولي هو اللحظة الحاسمة التي تحدد انطباع المستخدم الأول. هذا الملف يركز على تقنيات تحسين ما يحدث من لحظة طلب الصفحة حتى ظهور المحتوى الأول القابل للتفاعل.

## فهم مراحل التحميل الأولي

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        مراحل التحميل الأولي                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Request ──► DNS ──► TCP ──► TLS ──► TTFB ──► HTML ──► Resources ──► Render │
│    │         │       │       │        │        │          │           │     │
│    0ms      50ms   100ms   150ms    300ms    400ms    1000ms+       2000ms+ │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  المراحل القابلة للتحسين:                                                    │
│  • TTFB: استخدام CDN + تخزين مؤقت                                           │
│  • HTML: تصغير وضغط                                                         │
│  • Resources: تحميل متوازي + أولويات                                        │
│  • Render: شاشة splash محسنة                                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

## شاشة الانتظار (Splash Screen) المحسنة

### الأسلوب التقليدي ❌

```html
<!-- index.html - أسلوب غير محسن -->
<body>
  <!-- لا شيء يظهر حتى يتم تحميل Flutter بالكامل -->
  <script src="main.dart.js"></script>
</body>
```

### الأسلوب المحسن ✅

```html
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  
  <!-- Preconnect للموارد الخارجية -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  
  <!-- Preload للموارد الحرجة -->
  <link rel="preload" href="main.dart.js" as="script">
  <link rel="preload" href="assets/fonts/app-font.woff2" as="font" type="font/woff2" crossorigin>
  
  <!-- DNS Prefetch للموارد المستقبلية -->
  <link rel="dns-prefetch" href="//api.example.com">
  
  <title>تطبيقي</title>
  
  <style>
    /* أنماط شاشة الانتظار - Critical CSS مضمنة */
    :root {
      --primary-color: #2196F3;
      --background-color: #FAFAFA;
    }
    
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      background-color: var(--background-color);
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      min-height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
    }
    
    /* شاشة الانتظار */
    .splash-screen {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      position: fixed;
      inset: 0;
      z-index: 9999;
      background: var(--background-color);
      transition: opacity 0.3s ease-out;
    }
    
    .splash-screen.fade-out {
      opacity: 0;
      pointer-events: none;
    }
    
    /* الشعار */
    .splash-logo {
      width: 120px;
      height: 120px;
      margin-bottom: 24px;
      animation: pulse 2s ease-in-out infinite;
    }
    
    @keyframes pulse {
      0%, 100% { transform: scale(1); opacity: 1; }
      50% { transform: scale(1.05); opacity: 0.8; }
    }
    
    /* مؤشر التحميل */
    .splash-loader {
      width: 200px;
      height: 4px;
      background: #E0E0E0;
      border-radius: 2px;
      overflow: hidden;
      margin-bottom: 16px;
    }
    
    .splash-loader-bar {
      height: 100%;
      width: 0%;
      background: var(--primary-color);
      border-radius: 2px;
      transition: width 0.3s ease;
    }
    
    /* نص الحالة */
    .splash-status {
      font-size: 14px;
      color: #757575;
      text-align: center;
    }
    
    /* إخفاء Flutter أثناء التحميل */
    flutter-view {
      opacity: 0;
      transition: opacity 0.3s ease-in;
    }
    
    flutter-view.ready {
      opacity: 1;
    }
  </style>
</head>

<body>
  <!-- شاشة الانتظار -->
  <div id="splash" class="splash-screen">
    <!-- SVG مضمن للشعار (أسرع من تحميل صورة) -->
    <svg class="splash-logo" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <circle cx="50" cy="50" r="45" fill="#2196F3"/>
      <text x="50" y="60" text-anchor="middle" fill="white" font-size="30" font-weight="bold">M</text>
    </svg>
    
    <div class="splash-loader">
      <div id="loader-bar" class="splash-loader-bar"></div>
    </div>
    
    <p id="splash-status" class="splash-status">جاري تحميل التطبيق...</p>
  </div>

  <script>
    // إدارة شاشة الانتظار
    const SplashManager = {
      loaderBar: null,
      statusText: null,
      splash: null,
      
      init() {
        this.loaderBar = document.getElementById('loader-bar');
        this.statusText = document.getElementById('splash-status');
        this.splash = document.getElementById('splash');
      },
      
      updateProgress(percent, message) {
        if (this.loaderBar) {
          this.loaderBar.style.width = `${percent}%`;
        }
        if (this.statusText && message) {
          this.statusText.textContent = message;
        }
      },
      
      hide() {
        if (this.splash) {
          this.splash.classList.add('fade-out');
          setTimeout(() => {
            this.splash.remove();
          }, 300);
        }
        
        const flutterView = document.querySelector('flutter-view');
        if (flutterView) {
          flutterView.classList.add('ready');
        }
      }
    };
    
    SplashManager.init();
  </script>

  <script src="flutter.js" defer></script>
  
  <script>
    window.addEventListener('load', async function() {
      // تحديث التقدم
      SplashManager.updateProgress(20, 'جاري تهيئة Flutter...');
      
      // تهيئة Flutter مع تتبع التقدم
      const engineInitializer = await _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: serviceWorkerVersion,
        },
        onEntrypointLoaded: async function(engineInitializer) {
          SplashManager.updateProgress(50, 'جاري تحميل المحرك...');
          
          const appRunner = await engineInitializer.initializeEngine({
            // إعدادات المحرك
          });
          
          SplashManager.updateProgress(80, 'جاري بدء التطبيق...');
          await appRunner.runApp();
        }
      });
    });
    
    // استقبال إشارة الجاهزية من Flutter
    window.flutterReady = function() {
      SplashManager.updateProgress(100, 'جاهز!');
      setTimeout(() => SplashManager.hide(), 200);
    };
  </script>
</body>
</html>
```

### كود Dart للتكامل مع شاشة الانتظار

```dart
// lib/main.dart
import 'dart:js' as js;
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة أولية سريعة فقط
  await _quickInit();
  
  runApp(const MyApp());
  
  // إخفاء شاشة الانتظار بعد الرسم الأول
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _notifyFlutterReady();
  });
}

Future<void> _quickInit() async {
  // فقط التهيئات الضرورية للشاشة الأولى
  // باقي التهيئات تتم في الخلفية
}

void _notifyFlutterReady() {
  js.context.callMethod('flutterReady');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيقي',
      home: const HomeScreen(),
    );
  }
}
```

## تحسين ترتيب تحميل الموارد

### Resource Hints

```html
<head>
  <!-- 1. Preconnect: إنشاء اتصالات مسبقة -->
  <!-- للخوادم التي ستطلب منها موارد حتماً -->
  <link rel="preconnect" href="https://api.myapp.com">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  
  <!-- 2. DNS-Prefetch: تحليل DNS مسبق -->
  <!-- للخوادم التي قد تطلب منها لاحقاً -->
  <link rel="dns-prefetch" href="//analytics.example.com">
  <link rel="dns-prefetch" href="//cdn.example.com">
  
  <!-- 3. Preload: تحميل مسبق للموارد الحرجة -->
  <!-- تحميل فوري، أعلى أولوية -->
  <link rel="preload" href="main.dart.js" as="script">
  <link rel="preload" href="assets/fonts/main.woff2" as="font" type="font/woff2" crossorigin>
  <link rel="preload" href="assets/images/hero.webp" as="image">
  
  <!-- 4. Prefetch: تحميل مسبق للموارد المستقبلية -->
  <!-- تحميل في وقت الفراغ، أولوية منخفضة -->
  <link rel="prefetch" href="assets/images/secondary-page.webp">
  
  <!-- 5. Modulepreload: للوحدات JavaScript -->
  <link rel="modulepreload" href="deferred/dashboard.js">
</head>
```

### أولويات التحميل (Fetch Priority)

```html
<!-- أعلى أولوية -->
<script src="main.dart.js" fetchpriority="high"></script>
<img src="hero.webp" fetchpriority="high" alt="Hero">

<!-- أولوية عادية (افتراضي) -->
<img src="content.webp" alt="Content">

<!-- أولوية منخفضة -->
<img src="footer-decoration.webp" fetchpriority="low" alt="">
<script src="analytics.js" fetchpriority="low" defer></script>
```

## تأخير التهيئات غير الضرورية

### نمط التهيئة المرحلية

```dart
// lib/core/initialization/app_initializer.dart
import 'dart:async';

enum InitPhase { critical, important, background }

class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  factory AppInitializer() => _instance;
  AppInitializer._internal();

  final _phaseCompleters = <InitPhase, Completer<void>>{};
  
  /// تهيئة التطبيق على مراحل
  Future<void> initialize() async {
    // المرحلة 1: التهيئات الحرجة (قبل عرض أي شيء)
    await _initCritical();
    _completePhase(InitPhase.critical);
    
    // المرحلة 2: التهيئات المهمة (بعد الشاشة الأولى)
    _scheduleAfterFirstFrame(() async {
      await _initImportant();
      _completePhase(InitPhase.important);
    });
    
    // المرحلة 3: التهيئات الخلفية (عندما يكون التطبيق خاملاً)
    _scheduleWhenIdle(() async {
      await _initBackground();
      _completePhase(InitPhase.background);
    });
  }

  /// التهيئات الحرجة - الحد الأدنى للتشغيل
  Future<void> _initCritical() async {
    // فقط ما هو ضروري للشاشة الأولى
    await Future.wait([
      _initLocalization(),      // ~50ms
      _initTheme(),             // ~10ms
      _initAuthState(),         // ~100ms (من التخزين المحلي)
    ]);
  }

  /// التهيئات المهمة - بعد ظهور الشاشة الأولى
  Future<void> _initImportant() async {
    await Future.wait([
      _initAnalytics(),         // ~200ms
      _initNotifications(),     // ~150ms
      _initDeepLinks(),         // ~50ms
    ]);
  }

  /// التهيئات الخلفية - في وقت الفراغ
  Future<void> _initBackground() async {
    await Future.wait([
      _initCrashReporting(),    // ~300ms
      _initRemoteConfig(),      // ~500ms
      _prefetchCommonData(),    // ~1000ms
      _initOfflineSync(),       // ~200ms
    ]);
  }

  void _scheduleAfterFirstFrame(Future<void> Function() task) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      task();
    });
  }

  void _scheduleWhenIdle(Future<void> Function() task) {
    Future.delayed(const Duration(seconds: 2), task);
  }

  void _completePhase(InitPhase phase) {
    _phaseCompleters[phase]?.complete();
  }

  /// انتظار اكتمال مرحلة معينة
  Future<void> waitForPhase(InitPhase phase) {
    _phaseCompleters[phase] ??= Completer<void>();
    return _phaseCompleters[phase]!.future;
  }

  // تهيئات فردية
  Future<void> _initLocalization() async {
    // تحميل اللغة من التخزين المحلي
  }

  Future<void> _initTheme() async {
    // تحميل السمة المحفوظة
  }

  Future<void> _initAuthState() async {
    // التحقق من حالة تسجيل الدخول المحفوظة
  }

  Future<void> _initAnalytics() async {
    // تهيئة تحليلات Firebase/GA
  }

  Future<void> _initNotifications() async {
    // تهيئة الإشعارات
  }

  Future<void> _initDeepLinks() async {
    // تهيئة الروابط العميقة
  }

  Future<void> _initCrashReporting() async {
    // تهيئة تقارير الأعطال
  }

  Future<void> _initRemoteConfig() async {
    // جلب الإعدادات عن بعد
  }

  Future<void> _prefetchCommonData() async {
    // جلب البيانات الشائعة مسبقاً
  }

  Future<void> _initOfflineSync() async {
    // تهيئة المزامنة للعمل بدون اتصال
  }
}
```

### استخدام التهيئة المرحلية

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final initializer = AppInitializer();
  
  // فقط انتظر المرحلة الحرجة
  await initializer.initialize();
  
  runApp(const MyApp());
}

// في شاشة تحتاج ميزة معينة
class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // انتظر اكتمال التهيئات المهمة إذا لزم
    AppInitializer().waitForPhase(InitPhase.important).then((_) {
      // الآن التحليلات جاهزة
      Analytics.logScreenView('dashboard');
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(/* ... */);
  }
}
```

## تحسين main.dart

### قبل التحسين ❌

```dart
// main.dart - غير محسن
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // كل هذا يؤخر ظهور الشاشة الأولى!
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('cache');
  await Hive.openBox('user');
  await GetStorage.init();
  await EasyLocalization.ensureInitialized();
  await FlutterDownloader.initialize();
  await NotificationService.init();
  await AnalyticsService.init();
  await CrashReportingService.init();
  await RemoteConfigService.init();
  await DeepLinkService.init();
  
  runApp(
    EasyLocalization(
      child: MyApp(),
    ),
  );
}
```

### بعد التحسين ✅

```dart
// lib/main.dart - محسن
import 'package:flutter/material.dart';

void main() {
  // لا نستخدم async هنا لتسريع البدء
  _bootstrap();
}

void _bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تشغيل التطبيق فوراً
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<void> _initFuture;
  
  @override
  void initState() {
    super.initState();
    _initFuture = _initMinimal();
  }
  
  Future<void> _initMinimal() async {
    // فقط الحد الأدنى المطلوب
    await Future.wait([
      _loadSavedLocale(),
      _loadSavedTheme(),
    ]);
    
    // بدء التهيئات الخلفية (بدون انتظار)
    _initBackgroundServices();
  }
  
  Future<void> _loadSavedLocale() async {
    // تحميل سريع من SharedPreferences
  }
  
  Future<void> _loadSavedTheme() async {
    // تحميل سريع من SharedPreferences
  }
  
  void _initBackgroundServices() {
    // لا ننتظر هذه
    Future.microtask(() async {
      // التهيئات الثانوية
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        // حتى أثناء التحميل، نعرض التطبيق
        return MaterialApp(
          home: snapshot.connectionState == ConnectionState.done
              ? const HomeScreen()
              : const MinimalSplashScreen(),
        );
      },
    );
  }
}

class MinimalSplashScreen extends StatelessWidget {
  const MinimalSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

## تحميل البيانات الأولية

### نمط Shell مع بيانات مؤجلة

```dart
// lib/features/home/presentation/screens/home_screen.dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرئيسية')),
      body: Column(
        children: [
          // العناصر الثابتة تظهر فوراً
          const WelcomeBanner(),
          const QuickActions(),
          
          // البيانات الديناميكية تحمل بشكل مستقل
          Expanded(
            child: _DeferredContent(),
          ),
        ],
      ),
    );
  }
}

class _DeferredContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
      future: context.read<HomeRepository>().getHomeData(),
      builder: (context, snapshot) {
        // هيكل الصفحة يظهر فوراً
        return CustomScrollView(
          slivers: [
            // عنصر 1: يظهر فوراً أو skeleton
            _buildRecentItems(snapshot.data?.recentItems),
            
            // عنصر 2: يظهر فوراً أو skeleton
            _buildRecommendations(snapshot.data?.recommendations),
            
            // عنصر 3: يظهر فوراً أو skeleton
            _buildNews(snapshot.data?.news),
          ],
        );
      },
    );
  }

  Widget _buildRecentItems(List<Item>? items) {
    if (items == null) {
      return const SliverToBoxAdapter(
        child: RecentItemsSkeleton(),
      );
    }
    return SliverToBoxAdapter(
      child: RecentItemsList(items: items),
    );
  }

  Widget _buildRecommendations(List<Item>? items) {
    if (items == null) {
      return const SliverToBoxAdapter(
        child: RecommendationsSkeleton(),
      );
    }
    return SliverToBoxAdapter(
      child: RecommendationsList(items: items),
    );
  }

  Widget _buildNews(List<NewsItem>? items) {
    if (items == null) {
      return const SliverToBoxAdapter(
        child: NewsSkeleton(),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => NewsCard(item: items[index]),
        childCount: items.length,
      ),
    );
  }
}
```

### Skeleton Loading المحسن

```dart
// lib/shared/widgets/skeletons/skeleton_base.dart
import 'package:flutter/material.dart';

class SkeletonBase extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBase({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonBase> createState() => _SkeletonBaseState();
}

class _SkeletonBaseState extends State<SkeletonBase>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
            ),
          ),
        );
      },
    );
  }
}

// مثال: Skeleton لبطاقة
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة
            SkeletonBase(
              width: double.infinity,
              height: 150,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            // عنوان
            const SkeletonBase(width: 200, height: 20),
            const SizedBox(height: 8),
            // وصف
            const SkeletonBase(width: double.infinity, height: 14),
            const SizedBox(height: 4),
            const SkeletonBase(width: 150, height: 14),
          ],
        ),
      ),
    );
  }
}
```

## Above the Fold Optimization

### تحسين المحتوى فوق الطية

```dart
// lib/features/home/presentation/screens/optimized_home.dart
class OptimizedHomeScreen extends StatelessWidget {
  const OptimizedHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // المحتوى فوق الطية - أولوية قصوى
          SliverToBoxAdapter(
            child: SizedBox(
              height: screenHeight, // أول شاشة كاملة
              child: const _AboveTheFoldContent(),
            ),
          ),
          
          // المحتوى تحت الطية - يحمل بتأخير
          const _BelowTheFoldContent(),
        ],
      ),
    );
  }
}

class _AboveTheFoldContent extends StatelessWidget {
  const _AboveTheFoldContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // هذا يظهر فوراً
        const AppHeader(),
        const HeroSection(),
        const QuickActions(),
      ],
    );
  }
}

class _BelowTheFoldContent extends StatefulWidget {
  const _BelowTheFoldContent();

  @override
  State<_BelowTheFoldContent> createState() => _BelowTheFoldContentState();
}

class _BelowTheFoldContentState extends State<_BelowTheFoldContent> {
  bool _shouldLoad = false;

  @override
  void initState() {
    super.initState();
    // تأخير تحميل المحتوى تحت الطية
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _shouldLoad = true);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldLoad) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        const FeaturedProducts(),
        const RecentActivity(),
        const NewsSection(),
        const Footer(),
      ]),
    );
  }
}
```

## تحسين تحميل البيانات المبدئية

### Prefetch للبيانات المتوقعة

```dart
// lib/core/services/data_prefetcher.dart
class DataPrefetcher {
  static final DataPrefetcher _instance = DataPrefetcher._internal();
  factory DataPrefetcher() => _instance;
  DataPrefetcher._internal();

  final _cache = <String, dynamic>{};
  final _inProgress = <String, Future<dynamic>>{};

  /// بدء الجلب المسبق للبيانات الشائعة
  void startPrefetch() {
    // يبدأ بعد استقرار التطبيق
    Future.delayed(const Duration(seconds: 1), () {
      _prefetchUserData();
      _prefetchCommonData();
    });
  }

  Future<void> _prefetchUserData() async {
    await prefetch('user_profile', () => _api.getUserProfile());
    await prefetch('notifications_count', () => _api.getNotificationsCount());
  }

  Future<void> _prefetchCommonData() async {
    await prefetch('categories', () => _api.getCategories());
    await prefetch('featured_items', () => _api.getFeaturedItems());
  }

  /// جلب مسبق مع تخزين مؤقت
  Future<T?> prefetch<T>(String key, Future<T> Function() fetcher) async {
    if (_cache.containsKey(key)) {
      return _cache[key] as T;
    }

    if (_inProgress.containsKey(key)) {
      return await _inProgress[key] as T;
    }

    try {
      final future = fetcher();
      _inProgress[key] = future;
      final result = await future;
      _cache[key] = result;
      _inProgress.remove(key);
      return result;
    } catch (e) {
      _inProgress.remove(key);
      return null;
    }
  }

  /// الحصول على البيانات (من الكاش أو الجلب)
  Future<T> get<T>(String key, Future<T> Function() fetcher) async {
    if (_cache.containsKey(key)) {
      return _cache[key] as T;
    }
    
    final result = await prefetch(key, fetcher);
    return result as T;
  }

  /// مسح الكاش
  void invalidate([String? key]) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }
}
```

## قياس أداء التحميل الأولي

```dart
// lib/core/performance/startup_metrics.dart
class StartupMetrics {
  static final StartupMetrics _instance = StartupMetrics._internal();
  factory StartupMetrics() => _instance;
  StartupMetrics._internal();

  final _timestamps = <String, DateTime>{};

  void mark(String name) {
    _timestamps[name] = DateTime.now();
  }

  Duration? getDuration(String from, String to) {
    final start = _timestamps[from];
    final end = _timestamps[to];
    if (start == null || end == null) return null;
    return end.difference(start);
  }

  void logAll() {
    print('=== Startup Metrics ===');
    
    final appStart = _timestamps['app_start'];
    if (appStart == null) return;

    _timestamps.forEach((name, time) {
      if (name != 'app_start') {
        final duration = time.difference(appStart);
        print('$name: ${duration.inMilliseconds}ms');
      }
    });
  }

  Map<String, int> toJson() {
    final appStart = _timestamps['app_start'];
    if (appStart == null) return {};

    return _timestamps.map((name, time) {
      return MapEntry(name, time.difference(appStart).inMilliseconds);
    });
  }
}

// الاستخدام
void main() {
  StartupMetrics().mark('app_start');
  
  WidgetsFlutterBinding.ensureInitialized();
  StartupMetrics().mark('binding_initialized');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    StartupMetrics().mark('build_started');
    
    return MaterialApp(
      home: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            StartupMetrics().mark('first_frame');
            StartupMetrics().logAll();
          });
          return const HomeScreen();
        },
      ),
    );
  }
}
```

## قائمة المراجعة

### التحميل الأولي
- [ ] شاشة انتظار HTML محسنة مع تقدم حقيقي
- [ ] استخدام Resource Hints (preconnect, preload, prefetch)
- [ ] Fetch Priority للموارد الحرجة
- [ ] Critical CSS مضمن في HTML

### التهيئة
- [ ] تأجيل التهيئات غير الضرورية للشاشة الأولى
- [ ] تهيئة مرحلية (critical → important → background)
- [ ] عدم استخدام await غير ضروري في main()
- [ ] تهيئات الخلفية تعمل بدون حجب UI

### البيانات
- [ ] Skeleton loading للمحتوى الديناميكي
- [ ] Above the fold content يظهر أولاً
- [ ] Prefetch للبيانات المتوقعة
- [ ] تخزين مؤقت للبيانات الأولية

### القياس
- [ ] قياس وتسجيل startup metrics
- [ ] مراقبة FCP, LCP, TTI
- [ ] تحديد عنق الزجاجة في التحميل

## الأخطاء الشائعة

| الخطأ | المشكلة | الحل |
|-------|---------|------|
| `await` كثيرة في main | تأخير ظهور أي شيء | التهيئة المرحلية |
| لا splash screen | شاشة بيضاء طويلة | splash HTML محسن |
| تحميل كل البيانات | بطء الشاشة الأولى | تحميل تدريجي |
| لا skeleton | تجربة سيئة | skeleton loading |
| لا resource hints | تحميل تسلسلي بطيء | preconnect, preload |

---

**المرجع السابق:** [08-tree-shaking.md](./08-tree-shaking.md) - إزالة الكود غير المستخدم
**المرجع التالي:** [10-service-workers.md](./10-service-workers.md) - تكوين Service Workers
