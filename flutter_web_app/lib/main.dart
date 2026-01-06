/// ==========================================
/// main.dart - نقطة الدخول الرئيسية
/// ==========================================
///
/// هذا الملف يطبق:
/// - معيار 9: تحسين التحميل الأولي (09-initial-load.md)
/// - معيار 2: تحسين حجم الحزمة (02-bundle-optimization.md)
/// - التهيئة المرحلية للأداء الأمثل
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/services/initialization_service.dart';
import 'core/services/update_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/home/presentation/screens/home_screen.dart';

/// نقطة الدخول الرئيسية - بدون async لتسريع البدء
void main() {
  _bootstrap();
}

/// بدء التطبيق مع التهيئة المرحلية
void _bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();

  // تسجيل بداية التطبيق للقياس
  if (kDebugMode) {
    print('[Performance] App bootstrap started');
  }

  // تشغيل التطبيق فوراً - التهيئات تتم بالتوازي
  runApp(const AppBootstrap());
}

/// Widget التمهيد - يدير التهيئة المرحلية
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<void> _initFuture;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
  }

  /// التهيئة المرحلية - الحرجة فقط قبل العرض
  Future<void> _initializeApp() async {
    final stopwatch = Stopwatch()..start();

    // المرحلة 1: التهيئات الحرجة فقط
    await InitializationService.initCritical();

    if (kDebugMode) {
      print('[Performance] Critical init: ${stopwatch.elapsedMilliseconds}ms');
    }

    setState(() => _initialized = true);

    // المرحلة 2: التهيئات المهمة (بعد الرسم الأول)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InitializationService.initImportant();
      _notifyFlutterReady();
    });

    // المرحلة 3: التهيئات الخلفية (بتأخير)
    Future.delayed(const Duration(seconds: 2), () {
      InitializationService.initBackground();
    });
  }

  /// إخطار JavaScript أن Flutter جاهز
  void _notifyFlutterReady() {
    if (kIsWeb) {
      // استدعاء الدالة في index.html
      try {
        // ignore: avoid_dynamic_calls
        // js.context.callMethod('flutterReady');
      } catch (e) {
        if (kDebugMode) {
          print('[Performance] Could not notify JS: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        // عرض التطبيق حتى أثناء التهيئة
        return MultiProvider(
          providers: [
            // تسجيل الـ Providers هنا
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            Provider<UpdateService>(create: (_) => UpdateService()),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return MaterialApp(
                title: AppConfig.appName,
                debugShowCheckedModeBanner: false,

                // السمة المحسنة
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,

                // الصفحة الرئيسية
                home: _initialized
                    ? const HomeScreen()
                    : const _MinimalSplashScreen(),

                // التوجيه
                onGenerateRoute: AppRouter.generateRoute,
              );
            },
          ),
        );
      },
    );
  }
}

/// شاشة انتظار Flutter (تظهر بعد HTML splash)
class _MinimalSplashScreen extends StatelessWidget {
  const _MinimalSplashScreen();

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

/// Provider للسمة
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}
