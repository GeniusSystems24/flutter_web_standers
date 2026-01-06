/// ==========================================
/// شاشة الإعدادات (03-deferred-loading.md)
/// ==========================================
///
/// هذا الملف يُحمّل بشكل مؤجل (deferred loading)
/// لتقليل حجم الحزمة الأولية
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/config/app_config.dart';
import '../../../../main.dart';

/// شاشة الإعدادات
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: const _SettingsBody(),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // قسم المظهر
        const _SectionHeader(title: 'المظهر'),
        const _ThemeSettings(),
        AppConstants.thinDivider,

        // قسم التطبيق
        const _SectionHeader(title: 'التطبيق'),
        const _AppSettings(),
        AppConstants.thinDivider,

        // قسم معلومات التطبيق
        const _SectionHeader(title: 'حول التطبيق'),
        const _AboutSection(),
      ],
    );
  }
}

/// عنوان القسم
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// إعدادات السمة
class _ThemeSettings extends StatelessWidget {
  const _ThemeSettings();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Column(
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('فاتح'),
              secondary: const Icon(Icons.light_mode),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('مظلم'),
              secondary: const Icon(Icons.dark_mode),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('تلقائي (حسب النظام)'),
              secondary: const Icon(Icons.brightness_auto),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

/// إعدادات التطبيق
class _AppSettings extends StatefulWidget {
  const _AppSettings();

  @override
  State<_AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<_AppSettings> {
  bool _notificationsEnabled = true;
  bool _cacheEnabled = true;
  bool _analyticsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('الإشعارات'),
          subtitle: const Text('استلام إشعارات التطبيق'),
          secondary: const Icon(Icons.notifications),
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() => _notificationsEnabled = value);
          },
        ),
        SwitchListTile(
          title: const Text('التخزين المؤقت'),
          subtitle: const Text('تخزين البيانات للعمل بدون اتصال'),
          secondary: const Icon(Icons.cached),
          value: _cacheEnabled,
          onChanged: (value) {
            setState(() => _cacheEnabled = value);
          },
        ),
        SwitchListTile(
          title: const Text('التحليلات'),
          subtitle: const Text('مساعدتنا في تحسين التطبيق'),
          secondary: const Icon(Icons.analytics),
          value: _analyticsEnabled,
          onChanged: (value) {
            setState(() => _analyticsEnabled = value);
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_sweep),
          title: const Text('مسح الكاش'),
          subtitle: const Text('حذف البيانات المخزنة'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم مسح الكاش')),
            );
          },
        ),
      ],
    );
  }
}

/// قسم معلومات التطبيق
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('الإصدار'),
          trailing: Text(
            AppConfig.appVersion,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.bug_report),
          title: const Text('البيئة'),
          trailing: Text(
            AppConfig.environment,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('سياسة الخصوصية'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // فتح صفحة الخصوصية
          },
        ),
        ListTile(
          leading: const Icon(Icons.gavel),
          title: const Text('شروط الاستخدام'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // فتح صفحة الشروط
          },
        ),
      ],
    );
  }
}
