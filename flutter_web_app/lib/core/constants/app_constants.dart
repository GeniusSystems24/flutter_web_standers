/// ==========================================
/// ثوابت التطبيق (07-rendering-optimization.md)
/// ==========================================
///
/// هذا الملف يطبق:
/// - معيار 7: تحسين الرسم والتصيير
/// - const widgets قابلة لإعادة الاستخدام
/// - تجنب إعادة إنشاء الكائنات
library;

import 'package:flutter/material.dart';

/// ثوابت Widgets شائعة الاستخدام (const للأداء)
abstract class AppConstants {
  AppConstants._();

  // ===== المسافات العمودية =====
  static const smallGap = SizedBox(height: 8);
  static const mediumGap = SizedBox(height: 16);
  static const largeGap = SizedBox(height: 24);
  static const xlargeGap = SizedBox(height: 32);

  // ===== المسافات الأفقية =====
  static const horizontalSmallGap = SizedBox(width: 8);
  static const horizontalMediumGap = SizedBox(width: 16);
  static const horizontalLargeGap = SizedBox(width: 24);

  // ===== الفواصل =====
  static const thinDivider = Divider(height: 1);
  static const thickDivider = Divider(height: 2, thickness: 2);
  static const verticalDivider = VerticalDivider(width: 1);

  // ===== Widgets شائعة =====
  static const loadingIndicator = Center(
    child: CircularProgressIndicator(),
  );

  static const loadingIndicatorSmall = SizedBox(
    width: 24,
    height: 24,
    child: CircularProgressIndicator(strokeWidth: 2),
  );

  static const emptyState = Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'لا توجد عناصر',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    ),
  );

  static const errorState = Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red),
        SizedBox(height: 16),
        Text(
          'حدث خطأ',
          style: TextStyle(
            fontSize: 16,
            color: Colors.red,
          ),
        ),
      ],
    ),
  );

  // ===== صناديق فارغة =====
  static const emptyBox = SizedBox.shrink();
  static const expandedBox = SizedBox.expand();
}

/// أيقونات التطبيق (لتسهيل Tree Shaking)
abstract class AppIcons {
  AppIcons._();

  static const home = Icons.home_outlined;
  static const homeSelected = Icons.home;
  static const dashboard = Icons.dashboard_outlined;
  static const dashboardSelected = Icons.dashboard;
  static const settings = Icons.settings_outlined;
  static const settingsSelected = Icons.settings;
  static const profile = Icons.person_outline;
  static const profileSelected = Icons.person;
  static const search = Icons.search;
  static const notifications = Icons.notifications_outlined;
  static const notificationsSelected = Icons.notifications;
  static const menu = Icons.menu;
  static const close = Icons.close;
  static const back = Icons.arrow_back;
  static const forward = Icons.arrow_forward;
  static const refresh = Icons.refresh;
  static const add = Icons.add;
  static const edit = Icons.edit_outlined;
  static const delete = Icons.delete_outline;
  static const share = Icons.share_outlined;
  static const favorite = Icons.favorite_outline;
  static const favoriteSelected = Icons.favorite;
}
