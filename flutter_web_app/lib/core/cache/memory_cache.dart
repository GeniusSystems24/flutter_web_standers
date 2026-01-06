/// ==========================================
/// التخزين المؤقت في الذاكرة (06-caching-strategies.md)
/// ==========================================
///
/// هذا الملف يطبق:
/// - معيار 6: استراتيجيات التخزين المؤقت
/// - Memory Cache مع TTL
/// - إدارة السعة
/// - Cache Hit/Miss Metrics
library;

import 'dart:async';

/// تخزين مؤقت في الذاكرة مع TTL وإدارة السعة
class MemoryCache<T> {
  final Duration defaultExpiry;
  final int maxSize;
  final Map<String, _CacheEntry<T>> _cache = {};

  // مقاييس الأداء
  int _hits = 0;
  int _misses = 0;

  MemoryCache({
    this.defaultExpiry = const Duration(minutes: 5),
    this.maxSize = 100,
  });

  /// تخزين قيمة
  void set(String key, T value, {Duration? expiry}) {
    _ensureCapacity();
    _cache[key] = _CacheEntry(
      value: value,
      expiry: DateTime.now().add(expiry ?? defaultExpiry),
      createdAt: DateTime.now(),
    );
  }

  /// الحصول على قيمة
  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) {
      _misses++;
      return null;
    }

    if (entry.isExpired) {
      _cache.remove(key);
      _misses++;
      return null;
    }

    _hits++;
    entry.lastAccessed = DateTime.now();
    return entry.value;
  }

  /// الحصول أو التحميل
  Future<T> getOrLoad(
    String key,
    Future<T> Function() loader, {
    Duration? expiry,
  }) async {
    final cached = get(key);
    if (cached != null) return cached;

    final value = await loader();
    set(key, value, expiry: expiry);
    return value;
  }

  /// حذف قيمة
  void remove(String key) => _cache.remove(key);

  /// مسح كل الـ cache
  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  /// هل القيمة موجودة وصالحة؟
  bool containsKey(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) return false;
    return true;
  }

  /// عدد العناصر
  int get length => _cache.length;

  /// نسبة الإصابة (Hit Rate)
  double get hitRate {
    final total = _hits + _misses;
    return total > 0 ? _hits / total : 0;
  }

  /// إحصائيات الكاش
  Map<String, dynamic> get stats => {
        'size': _cache.length,
        'maxSize': maxSize,
        'hits': _hits,
        'misses': _misses,
        'hitRate': '${(hitRate * 100).toStringAsFixed(1)}%',
      };

  /// التأكد من السعة (LRU Eviction)
  void _ensureCapacity() {
    if (_cache.length >= maxSize) {
      // حذف أقدم العناصر (الأقل استخداماً)
      final sortedKeys = _cache.keys.toList()
        ..sort((a, b) =>
            _cache[a]!.lastAccessed.compareTo(_cache[b]!.lastAccessed));

      // حذف ربع العناصر
      final toRemove = maxSize ~/ 4;
      for (var i = 0; i < toRemove && i < sortedKeys.length; i++) {
        _cache.remove(sortedKeys[i]);
      }
    }
  }

  /// تنظيف العناصر المنتهية
  void cleanup() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }
}

/// مدخل الكاش
class _CacheEntry<T> {
  final T value;
  final DateTime expiry;
  final DateTime createdAt;
  DateTime lastAccessed;

  _CacheEntry({
    required this.value,
    required this.expiry,
    required this.createdAt,
  }) : lastAccessed = createdAt;

  bool get isExpired => DateTime.now().isAfter(expiry);

  Duration get age => DateTime.now().difference(createdAt);
}

/// استراتيجيات التخزين المؤقت
enum CacheStrategy {
  /// Cache First - للملفات الثابتة
  cacheFirst,

  /// Network First - للـ API
  networkFirst,

  /// Stale While Revalidate - للصور
  staleWhileRevalidate,

  /// Network Only - للبيانات الحساسة
  networkOnly,

  /// Cache Only - للوضع Offline
  cacheOnly,
}

/// تكوين التخزين المؤقت
class CacheConfig {
  final CacheStrategy strategy;
  final Duration? expiry;
  final bool persistToDisk;

  const CacheConfig({
    required this.strategy,
    this.expiry,
    this.persistToDisk = false,
  });

  // تكوينات مُعدة مسبقاً
  static const api = CacheConfig(
    strategy: CacheStrategy.networkFirst,
    expiry: Duration(minutes: 5),
  );

  static const images = CacheConfig(
    strategy: CacheStrategy.staleWhileRevalidate,
    expiry: Duration(days: 1),
    persistToDisk: true,
  );

  static const staticAssets = CacheConfig(
    strategy: CacheStrategy.cacheFirst,
    expiry: Duration(days: 365),
    persistToDisk: true,
  );
}
