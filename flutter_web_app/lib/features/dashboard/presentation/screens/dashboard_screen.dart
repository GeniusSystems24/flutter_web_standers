/// ==========================================
/// شاشة لوحة التحكم (03-deferred-loading.md)
/// ==========================================
///
/// هذا الملف يُحمّل بشكل مؤجل (deferred loading)
/// لتقليل حجم الحزمة الأولية
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// شاشة لوحة التحكم
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
      ),
      body: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الإحصائيات
          const _StatsGrid(),
          AppConstants.largeGap,

          // الرسم البياني
          Text(
            'الأداء',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppConstants.mediumGap,
          const _PerformanceChart(),
          AppConstants.largeGap,

          // آخر النشاطات
          Text(
            'آخر النشاطات',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppConstants.mediumGap,
          const _ActivityList(),
        ],
      ),
    );
  }
}

/// شبكة الإحصائيات
class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: const [
        _StatCard(
          title: 'الزيارات',
          value: '12,543',
          icon: Icons.visibility,
          color: Colors.blue,
        ),
        _StatCard(
          title: 'المستخدمين',
          value: '1,234',
          icon: Icons.people,
          color: Colors.green,
        ),
        _StatCard(
          title: 'المبيعات',
          value: '\$8,765',
          icon: Icons.attach_money,
          color: Colors.orange,
        ),
        _StatCard(
          title: 'التقييم',
          value: '4.8',
          icon: Icons.star,
          color: Colors.purple,
        ),
      ],
    );
  }
}

/// بطاقة إحصائية
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// الرسم البياني (محاكاة)
class _PerformanceChart extends StatelessWidget {
  const _PerformanceChart();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insert_chart, size: 64, color: Colors.grey),
              SizedBox(height: 8),
              Text('الرسم البياني للأداء'),
            ],
          ),
        ),
      ),
    );
  }
}

/// قائمة النشاطات
class _ActivityList extends StatelessWidget {
  const _ActivityList();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.primaries[index % Colors.primaries.length]
                  .withOpacity(0.2),
              child: Icon(
                Icons.notifications,
                color: Colors.primaries[index % Colors.primaries.length],
              ),
            ),
            title: Text('نشاط ${index + 1}'),
            subtitle: Text('منذ ${index + 1} ساعة'),
            trailing: const Icon(Icons.chevron_right),
          );
        },
      ),
    );
  }
}
