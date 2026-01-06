/// ==========================================
/// الشاشة الرئيسية (07-rendering-optimization.md)
/// ==========================================
///
/// هذا الملف يطبق:
/// - معيار 7: تحسين الرسم والتصيير
/// - const constructors
/// - تجزئة Widgets
/// - RepaintBoundary للعزل
/// - ListView.builder للقوائم
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../main.dart';

/// الشاشة الرئيسية
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Web المحسّن'),
        actions: [
          // Widget منفصل للسمة (لتجنب إعادة بناء AppBar)
          const _ThemeToggleButton(),
        ],
      ),
      body: const _HomeBody(),
      bottomNavigationBar: const _BottomNavigation(),
    );
  }
}

/// زر تبديل السمة - Widget منفصل
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    // استخدام Selector لقراءة قيمة واحدة فقط
    return Selector<ThemeProvider, ThemeMode>(
      selector: (_, provider) => provider.themeMode,
      builder: (context, themeMode, _) {
        return IconButton(
          icon: Icon(
            themeMode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
          onPressed: () {
            context.read<ThemeProvider>().toggleTheme();
          },
          tooltip: 'تبديل السمة',
        );
      },
    );
  }
}

/// محتوى الشاشة الرئيسية
class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        // Header ثابت - يستخدم RepaintBoundary
        SliverToBoxAdapter(
          child: RepaintBoundary(
            child: _WelcomeSection(),
          ),
        ),

        // أزرار التنقل السريع
        SliverToBoxAdapter(
          child: _QuickActions(),
        ),

        // قائمة الميزات - تستخدم builder
        _FeaturesList(),

        // Footer
        SliverToBoxAdapter(
          child: _Footer(),
        ),
      ],
    );
  }
}

/// قسم الترحيب
class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحباً بك',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppConstants.smallGap,
          Text(
            'هذا المشروع يوضح تطبيق معايير الأداء لـ Flutter Web',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// أزرار الإجراءات السريعة
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: AppIcons.dashboard,
              label: 'لوحة التحكم',
              onTap: () => Navigator.pushNamed(context, AppRoutes.dashboard),
            ),
          ),
          AppConstants.horizontalMediumGap,
          Expanded(
            child: _QuickActionCard(
              icon: AppIcons.settings,
              label: 'الإعدادات',
              onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة إجراء سريع
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              AppConstants.smallGap,
              Text(label, style: theme.textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// قائمة الميزات - تستخدم Sliver للأداء
class _FeaturesList extends StatelessWidget {
  const _FeaturesList();

  static const _features = [
    _FeatureItem(
      icon: Icons.speed,
      title: 'اختيار المحرك الذكي',
      description: 'HTML للأجهزة الضعيفة، CanvasKit للقوية',
    ),
    _FeatureItem(
      icon: Icons.compress,
      title: 'تحسين حجم الحزمة',
      description: 'Tree Shaking وتحسين الاستيرادات',
    ),
    _FeatureItem(
      icon: Icons.download,
      title: 'التحميل المؤجل',
      description: 'تحميل الصفحات عند الحاجة فقط',
    ),
    _FeatureItem(
      icon: Icons.cached,
      title: 'التخزين المؤقت',
      description: 'Service Worker واستراتيجيات متعددة',
    ),
    _FeatureItem(
      icon: Icons.brush,
      title: 'تحسين الرسم',
      description: 'const constructors وRepaintBoundary',
    ),
    _FeatureItem(
      icon: Icons.network_check,
      title: 'تحسين الشبكة',
      description: 'Circuit Breaker وRetry Logic',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final feature = _features[index];
            return _FeatureCard(feature: feature);
          },
          childCount: _features.length,
        ),
      ),
    );
  }
}

/// بيانات الميزة
class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// بطاقة الميزة
class _FeatureCard extends StatelessWidget {
  final _FeatureItem feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            feature.icon,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(feature.title),
        subtitle: Text(feature.description),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// التنقل السفلي
class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        switch (index) {
          case 1:
            Navigator.pushNamed(context, AppRoutes.dashboard);
            break;
          case 2:
            Navigator.pushNamed(context, AppRoutes.settings);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(AppIcons.home),
          selectedIcon: Icon(AppIcons.homeSelected),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(AppIcons.dashboard),
          selectedIcon: Icon(AppIcons.dashboardSelected),
          label: 'لوحة التحكم',
        ),
        NavigationDestination(
          icon: Icon(AppIcons.settings),
          selectedIcon: Icon(AppIcons.settingsSelected),
          label: 'الإعدادات',
        ),
      ],
    );
  }
}

/// Footer
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: Text(
          'مبني بـ Flutter Web مع أفضل معايير الأداء',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
