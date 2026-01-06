/// ==========================================
/// التوجيه مع التحميل المؤجل (03-deferred-loading.md)
/// ==========================================
///
/// هذا الملف يطبق:
/// - معيار 3: التحميل المؤجل (Deferred Loading)
/// - تحميل الصفحات عند الحاجة فقط
/// - تقليل حجم الحزمة الأولية
library;

import 'package:flutter/material.dart';

// استيراد مؤجل للصفحات الثانوية
import '../../features/dashboard/presentation/screens/dashboard_screen.dart'
    deferred as dashboard;
import '../../features/settings/presentation/screens/settings_screen.dart'
    deferred as settings;
import '../../features/home/presentation/screens/home_screen.dart';

/// مسارات التطبيق
abstract class AppRoutes {
  AppRoutes._();

  static const home = '/';
  static const dashboard = '/dashboard';
  static const settings = '/settings';
  static const profile = '/profile';
  static const notFound = '/404';
}

/// موجه التطبيق
abstract class AppRouter {
  AppRouter._();

  /// توليد المسارات
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case AppRoutes.home:
        return _buildRoute(
          const HomeScreen(),
          routeSettings,
        );

      case AppRoutes.dashboard:
        // تحميل مؤجل لصفحة Dashboard
        return _buildDeferredRoute(
          () => dashboard.loadLibrary(),
          () => dashboard.DashboardScreen(),
          routeSettings,
          loadingMessage: 'جاري تحميل لوحة التحكم...',
        );

      case AppRoutes.settings:
        // تحميل مؤجل لصفحة الإعدادات
        return _buildDeferredRoute(
          () => settings.loadLibrary(),
          () => settings.SettingsScreen(),
          routeSettings,
          loadingMessage: 'جاري تحميل الإعدادات...',
        );

      default:
        return _buildRoute(
          const _NotFoundScreen(),
          routeSettings,
        );
    }
  }

  /// بناء مسار عادي
  static MaterialPageRoute<T> _buildRoute<T>(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<T>(
      builder: (_) => page,
      settings: settings,
    );
  }

  /// بناء مسار مؤجل
  static MaterialPageRoute<T> _buildDeferredRoute<T>(
    Future<void> Function() loadLibrary,
    Widget Function() buildPage,
    RouteSettings settings, {
    String loadingMessage = 'جاري التحميل...',
  }) {
    return MaterialPageRoute<T>(
      builder: (_) => _DeferredPageLoader(
        loadLibrary: loadLibrary,
        buildPage: buildPage,
        loadingMessage: loadingMessage,
      ),
      settings: settings,
    );
  }
}

/// محمّل الصفحات المؤجلة
class _DeferredPageLoader extends StatefulWidget {
  final Future<void> Function() loadLibrary;
  final Widget Function() buildPage;
  final String loadingMessage;

  const _DeferredPageLoader({
    required this.loadLibrary,
    required this.buildPage,
    required this.loadingMessage,
  });

  @override
  State<_DeferredPageLoader> createState() => _DeferredPageLoaderState();
}

class _DeferredPageLoaderState extends State<_DeferredPageLoader> {
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
            return _ErrorScreen(
              error: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  _loadFuture = widget.loadLibrary();
                });
              },
            );
          }
          return widget.buildPage();
        }

        return _LoadingScreen(message: widget.loadingMessage);
      },
    );
  }
}

/// شاشة التحميل
class _LoadingScreen extends StatelessWidget {
  final String message;

  const _LoadingScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// شاشة الخطأ
class _ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorScreen({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ في تحميل الصفحة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

/// شاشة 404
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '404',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'الصفحة غير موجودة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              icon: const Icon(Icons.home),
              label: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    );
  }
}
