/// ==========================================
/// خدمة الشبكة المحسنة (11-network-optimization.md)
/// ==========================================
///
/// هذا الملف يطبق:
/// - معيار 11: تحسين الشبكة
/// - Connection Pooling
/// - Request Batching
/// - Circuit Breaker Pattern
/// - Retry with Exponential Backoff
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../cache/memory_cache.dart';

/// خدمة HTTP محسنة
class OptimizedHttpClient {
  OptimizedHttpClient._();

  static final _instance = OptimizedHttpClient._();
  static OptimizedHttpClient get instance => _instance;

  final _client = http.Client();
  final _cache = MemoryCache<http.Response>(
    defaultExpiry: const Duration(minutes: 5),
    maxSize: 100,
  );

  // إعدادات
  static const _maxRetries = 3;
  static const _baseRetryDelay = Duration(seconds: 1);
  final _timeout = Duration(seconds: AppConfig.networkTimeout);

  // Circuit Breaker
  final _circuitBreaker = CircuitBreaker();

  /// طلب GET مع تخزين مؤقت
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    bool useCache = true,
    Duration? cacheExpiry,
  }) async {
    final cacheKey = 'GET:$url';

    // فحص الكاش
    if (useCache) {
      final cached = _cache.get(cacheKey);
      if (cached != null) {
        if (kDebugMode) print('[HTTP] Cache hit: $url');
        return cached;
      }
    }

    // فحص Circuit Breaker
    if (!_circuitBreaker.canRequest) {
      throw Exception('Circuit breaker is open');
    }

    // الطلب مع إعادة المحاولة
    final response = await _requestWithRetry(
      () => _client.get(
        Uri.parse(url),
        headers: _buildHeaders(headers),
      ).timeout(_timeout),
    );

    // تخزين في الكاش إذا ناجح
    if (response.statusCode == 200 && useCache) {
      _cache.set(cacheKey, response, expiry: cacheExpiry);
    }

    return response;
  }

  /// طلب POST
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    if (!_circuitBreaker.canRequest) {
      throw Exception('Circuit breaker is open');
    }

    final response = await _requestWithRetry(
      () => _client.post(
        Uri.parse(url),
        headers: _buildHeaders(headers),
        body: body is String ? body : jsonEncode(body),
      ).timeout(_timeout),
    );

    // إبطال الكاش المرتبط
    _invalidateRelatedCache(url);

    return response;
  }

  /// طلب مع إعادة محاولة
  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() request,
  ) async {
    int retryCount = 0;

    while (true) {
      try {
        final response = await request();

        // تسجيل نجاح في Circuit Breaker
        _circuitBreaker.recordSuccess();

        // فحص أخطاء الخادم
        if (response.statusCode >= 500) {
          _circuitBreaker.recordFailure();
          if (retryCount < _maxRetries) {
            retryCount++;
            await _delay(retryCount);
            continue;
          }
        }

        return response;
      } catch (e) {
        _circuitBreaker.recordFailure();

        if (retryCount < _maxRetries) {
          retryCount++;
          if (kDebugMode) {
            print('[HTTP] Retry $retryCount/$_maxRetries: $e');
          }
          await _delay(retryCount);
          continue;
        }

        rethrow;
      }
    }
  }

  /// بناء الـ Headers
  Map<String, String> _buildHeaders(Map<String, String>? custom) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip, deflate',
      ...?custom,
    };
  }

  /// تأخير مع Exponential Backoff
  Future<void> _delay(int retryCount) async {
    final delay = _baseRetryDelay * (1 << (retryCount - 1));
    await Future.delayed(delay);
  }

  /// إبطال الكاش المرتبط
  void _invalidateRelatedCache(String url) {
    // إبطال GET للمسار نفسه
    _cache.remove('GET:$url');

    // إبطال المسار الأب
    final uri = Uri.parse(url);
    final parentPath = uri.pathSegments.take(2).join('/');
    _cache.remove('GET:${uri.origin}/$parentPath');
  }

  /// إغلاق العميل
  void dispose() {
    _client.close();
    _cache.clear();
  }
}

/// نمط Circuit Breaker لحماية النظام
class CircuitBreaker {
  int _failureCount = 0;
  DateTime? _lastFailure;
  CircuitState _state = CircuitState.closed;

  static const _failureThreshold = 5;
  static const _resetTimeout = Duration(seconds: 30);

  /// هل يمكن إرسال الطلب؟
  bool get canRequest {
    if (_state == CircuitState.closed) return true;

    if (_state == CircuitState.open) {
      // فحص إذا انتهت فترة الانتظار
      if (_lastFailure != null &&
          DateTime.now().difference(_lastFailure!) > _resetTimeout) {
        _state = CircuitState.halfOpen;
        return true;
      }
      return false;
    }

    // Half-open: نسمح بطلب واحد للاختبار
    return true;
  }

  /// تسجيل نجاح
  void recordSuccess() {
    _failureCount = 0;
    _state = CircuitState.closed;
  }

  /// تسجيل فشل
  void recordFailure() {
    _failureCount++;
    _lastFailure = DateTime.now();

    if (_failureCount >= _failureThreshold) {
      _state = CircuitState.open;
      if (kDebugMode) {
        print('[CircuitBreaker] Circuit opened after $_failureCount failures');
      }
    }
  }
}

enum CircuitState { closed, open, halfOpen }

/// مُجمّع الطلبات (Request Batcher)
class RequestBatcher<T> {
  final Duration _batchWindow;
  final Future<Map<String, T>> Function(List<String>) _batchFetcher;

  final _pendingRequests = <String, Completer<T>>{};
  Timer? _batchTimer;

  RequestBatcher({
    Duration batchWindow = const Duration(milliseconds: 50),
    required Future<Map<String, T>> Function(List<String>) batchFetcher,
  })  : _batchWindow = batchWindow,
        _batchFetcher = batchFetcher;

  /// طلب عنصر (يُجمّع مع طلبات أخرى)
  Future<T> fetch(String id) {
    if (_pendingRequests.containsKey(id)) {
      return _pendingRequests[id]!.future;
    }

    final completer = Completer<T>();
    _pendingRequests[id] = completer;

    // جدولة تنفيذ الدفعة
    _batchTimer?.cancel();
    _batchTimer = Timer(_batchWindow, _executeBatch);

    return completer.future;
  }

  /// تنفيذ الدفعة
  Future<void> _executeBatch() async {
    if (_pendingRequests.isEmpty) return;

    final requests = Map<String, Completer<T>>.from(_pendingRequests);
    _pendingRequests.clear();

    try {
      final results = await _batchFetcher(requests.keys.toList());

      for (final entry in requests.entries) {
        if (results.containsKey(entry.key)) {
          entry.value.complete(results[entry.key]);
        } else {
          entry.value.completeError(Exception('Item not found: ${entry.key}'));
        }
      }
    } catch (e) {
      for (final completer in requests.values) {
        completer.completeError(e);
      }
    }
  }
}
