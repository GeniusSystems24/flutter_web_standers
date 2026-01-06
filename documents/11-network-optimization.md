# تحسين الشبكة (Network Optimization)

## المقدمة

أداء الشبكة يؤثر بشكل مباشر على تجربة المستخدم. هذا الملف يغطي تقنيات تحسين طلبات الشبكة، تقليل زمن الاستجابة، وتحسين استراتيجيات جلب البيانات.

## فهم أداء الشبكة

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    مراحل طلب الشبكة                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  DNS    TCP      TLS       TTFB      Download                               │
│  ┌──┐   ┌──┐    ┌───┐     ┌────┐    ┌────────┐                              │
│  │  │ → │  │ → │   │ →   │    │ → │        │                              │
│  └──┘   └──┘    └───┘     └────┘    └────────┘                              │
│  ~50ms  ~50ms   ~100ms    ~200ms    متغير                                   │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  التحسينات الممكنة:                                                          │
│  • DNS Prefetch: تحليل DNS مسبقاً                                           │
│  • Connection Reuse: إعادة استخدام الاتصالات                                 │
│  • HTTP/2 Multiplexing: طلبات متعددة على اتصال واحد                         │
│  • Compression: ضغط البيانات                                                 │
│  • CDN: توزيع المحتوى جغرافياً                                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

## تحسين طلبات HTTP

### HTTP Client محسن

```dart
// lib/core/network/optimized_http_client.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OptimizedHttpClient {
  static final OptimizedHttpClient _instance = OptimizedHttpClient._internal();
  factory OptimizedHttpClient() => _instance;
  OptimizedHttpClient._internal();

  // عميل واحد مشترك لإعادة استخدام الاتصالات
  final _client = http.Client();
  
  // تكوين الطلبات
  static const _defaultTimeout = Duration(seconds: 30);
  static const _connectTimeout = Duration(seconds: 10);
  
  // Headers مشتركة
  final _defaultHeaders = <String, String>{
    'Accept': 'application/json',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
  };

  /// GET مع تحسينات
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Duration timeout = _defaultTimeout,
  }) async {
    final uri = Uri.parse(url);
    final mergedHeaders = {..._defaultHeaders, ...?headers};
    
    return _executeWithTimeout(
      () => _client.get(uri, headers: mergedHeaders),
      timeout,
    );
  }

  /// POST مع تحسينات
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = _defaultTimeout,
  }) async {
    final uri = Uri.parse(url);
    final mergedHeaders = {
      ..._defaultHeaders,
      'Content-Type': 'application/json',
      ...?headers,
    };
    
    final encodedBody = body is String ? body : jsonEncode(body);
    
    return _executeWithTimeout(
      () => _client.post(uri, headers: mergedHeaders, body: encodedBody),
      timeout,
    );
  }

  Future<http.Response> _executeWithTimeout(
    Future<http.Response> Function() request,
    Duration timeout,
  ) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      throw NetworkException('Network error: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}
```

### Request Batching (تجميع الطلبات)

```dart
// lib/core/network/request_batcher.dart
import 'dart:async';

class RequestBatcher<K, V> {
  final Future<Map<K, V>> Function(List<K> keys) _batchFetcher;
  final Duration _delay;
  
  final _pending = <K, Completer<V>>{};
  Timer? _timer;

  RequestBatcher({
    required Future<Map<K, V>> Function(List<K> keys) batchFetcher,
    Duration delay = const Duration(milliseconds: 50),
  })  : _batchFetcher = batchFetcher,
        _delay = delay;

  /// طلب عنصر واحد (يُجمع مع طلبات أخرى)
  Future<V> fetch(K key) {
    if (_pending.containsKey(key)) {
      return _pending[key]!.future;
    }

    final completer = Completer<V>();
    _pending[key] = completer;

    _scheduleFlush();

    return completer.future;
  }

  void _scheduleFlush() {
    _timer?.cancel();
    _timer = Timer(_delay, _flush);
  }

  Future<void> _flush() async {
    if (_pending.isEmpty) return;

    final batch = Map<K, Completer<V>>.from(_pending);
    _pending.clear();

    try {
      final results = await _batchFetcher(batch.keys.toList());
      
      for (final entry in batch.entries) {
        if (results.containsKey(entry.key)) {
          entry.value.complete(results[entry.key]);
        } else {
          entry.value.completeError(Exception('Key not found: ${entry.key}'));
        }
      }
    } catch (e) {
      for (final completer in batch.values) {
        completer.completeError(e);
      }
    }
  }
}

// الاستخدام
class UserRepository {
  final _batcher = RequestBatcher<String, User>(
    batchFetcher: (ids) async {
      // طلب واحد لجلب عدة مستخدمين
      final response = await api.post('/users/batch', body: {'ids': ids});
      final users = (response.data as List).map((j) => User.fromJson(j));
      return {for (final u in users) u.id: u};
    },
  );

  Future<User> getUser(String id) => _batcher.fetch(id);
}
```

### Request Deduplication (إزالة التكرار)

```dart
// lib/core/network/request_deduplicator.dart
class RequestDeduplicator {
  final _inFlight = <String, Future<dynamic>>{};

  /// تنفيذ طلب مع منع التكرار
  Future<T> execute<T>(
    String key,
    Future<T> Function() request,
  ) async {
    // إذا كان الطلب قيد التنفيذ، انتظره
    if (_inFlight.containsKey(key)) {
      return await _inFlight[key] as T;
    }

    // تنفيذ الطلب وتخزينه
    final future = request();
    _inFlight[key] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _inFlight.remove(key);
    }
  }
}

// الاستخدام
class ProductRepository {
  final _deduplicator = RequestDeduplicator();
  
  Future<Product> getProduct(String id) {
    return _deduplicator.execute(
      'product:$id',
      () => api.get('/products/$id'),
    );
  }
}
```

## Compression (الضغط)

### تكوين الخادم للضغط

```nginx
# nginx.conf
http {
    # تفعيل gzip
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 1000;
    
    gzip_types
        text/plain
        text/css
        text/javascript
        application/javascript
        application/json
        application/xml
        image/svg+xml
        font/woff2;
    
    # تفعيل Brotli (أفضل من gzip)
    brotli on;
    brotli_comp_level 6;
    brotli_types
        text/plain
        text/css
        text/javascript
        application/javascript
        application/json
        application/xml
        image/svg+xml
        font/woff2;
}
```

### فك الضغط في Flutter

```dart
// lib/core/network/compression_handler.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CompressionHandler {
  /// فك ضغط الاستجابة
  static String decompress(http.Response response) {
    final encoding = response.headers['content-encoding'];
    
    if (encoding == 'gzip') {
      return utf8.decode(gzip.decode(response.bodyBytes));
    } else if (encoding == 'deflate') {
      return utf8.decode(zlib.decode(response.bodyBytes));
    }
    
    return response.body;
  }

  /// ضغط الطلب
  static List<int> compress(String data) {
    return gzip.encode(utf8.encode(data));
  }
}
```

## CDN Integration

### تكوين CDN للأصول

```dart
// lib/core/config/cdn_config.dart
class CdnConfig {
  // قائمة CDN endpoints
  static const _cdnEndpoints = [
    'https://cdn1.myapp.com',
    'https://cdn2.myapp.com',
    'https://cdn3.myapp.com',
  ];
  
  static int _currentIndex = 0;
  
  /// الحصول على URL للأصل
  static String getAssetUrl(String path) {
    // Round-robin للتوزيع
    final endpoint = _cdnEndpoints[_currentIndex];
    _currentIndex = (_currentIndex + 1) % _cdnEndpoints.length;
    
    return '$endpoint$path';
  }
  
  /// URL مع versioning
  static String getVersionedUrl(String path, String version) {
    return '${getAssetUrl(path)}?v=$version';
  }
}

// الاستخدام
class AppImages {
  static String logo = CdnConfig.getAssetUrl('/images/logo.webp');
  static String hero = CdnConfig.getAssetUrl('/images/hero.webp');
}
```

### Failover للـ CDN

```dart
// lib/core/network/cdn_client.dart
class CdnClient {
  final List<String> _endpoints;
  final Map<String, bool> _healthStatus = {};
  
  CdnClient(this._endpoints) {
    for (final endpoint in _endpoints) {
      _healthStatus[endpoint] = true;
    }
  }

  /// جلب من CDN مع failover
  Future<http.Response> fetch(String path) async {
    final healthyEndpoints = _endpoints
        .where((e) => _healthStatus[e] == true)
        .toList();
    
    if (healthyEndpoints.isEmpty) {
      // إعادة تجربة الكل
      healthyEndpoints.addAll(_endpoints);
    }

    for (final endpoint in healthyEndpoints) {
      try {
        final response = await http
            .get(Uri.parse('$endpoint$path'))
            .timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          _healthStatus[endpoint] = true;
          return response;
        }
      } catch (e) {
        _healthStatus[endpoint] = false;
        // تجربة التالي
      }
    }

    throw Exception('All CDN endpoints failed');
  }

  /// فحص صحة الـ CDN
  Future<void> healthCheck() async {
    for (final endpoint in _endpoints) {
      try {
        final response = await http
            .head(Uri.parse('$endpoint/health'))
            .timeout(const Duration(seconds: 2));
        
        _healthStatus[endpoint] = response.statusCode == 200;
      } catch (e) {
        _healthStatus[endpoint] = false;
      }
    }
  }
}
```

## Connection Pooling

### إدارة الاتصالات

```dart
// lib/core/network/connection_pool.dart
import 'package:http/http.dart' as http;

class ConnectionPool {
  static final ConnectionPool _instance = ConnectionPool._internal();
  factory ConnectionPool() => _instance;
  ConnectionPool._internal();

  final Map<String, http.Client> _clients = {};
  static const _maxClientsPerHost = 6;

  /// الحصول على عميل للمضيف
  http.Client getClient(String host) {
    if (!_clients.containsKey(host)) {
      _clients[host] = http.Client();
    }
    return _clients[host]!;
  }

  /// إغلاق عميل محدد
  void closeClient(String host) {
    _clients[host]?.close();
    _clients.remove(host);
  }

  /// إغلاق جميع العملاء
  void closeAll() {
    for (final client in _clients.values) {
      client.close();
    }
    _clients.clear();
  }
}
```

## Prefetching (الجلب المسبق)

### استراتيجية الجلب المسبق

```dart
// lib/core/network/prefetch_manager.dart
import 'dart:async';

enum PrefetchPriority { high, medium, low }

class PrefetchManager {
  static final PrefetchManager _instance = PrefetchManager._internal();
  factory PrefetchManager() => _instance;
  PrefetchManager._internal();

  final _cache = <String, dynamic>{};
  final _inProgress = <String, Future<dynamic>>{};
  final _queue = <_PrefetchTask>[];
  
  bool _isProcessing = false;
  static const _maxConcurrent = 3;
  int _currentConcurrent = 0;

  /// إضافة مهمة للجلب المسبق
  void prefetch<T>(
    String key,
    Future<T> Function() fetcher, {
    PrefetchPriority priority = PrefetchPriority.medium,
  }) {
    // تجاهل إذا موجود في الكاش أو قيد التنفيذ
    if (_cache.containsKey(key) || _inProgress.containsKey(key)) {
      return;
    }

    _queue.add(_PrefetchTask(
      key: key,
      fetcher: fetcher,
      priority: priority,
    ));

    // ترتيب حسب الأولوية
    _queue.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _currentConcurrent >= _maxConcurrent) return;
    _isProcessing = true;

    while (_queue.isNotEmpty && _currentConcurrent < _maxConcurrent) {
      final task = _queue.removeAt(0);
      _currentConcurrent++;

      _executeTask(task).then((_) {
        _currentConcurrent--;
        _processQueue();
      });
    }

    _isProcessing = false;
  }

  Future<void> _executeTask(_PrefetchTask task) async {
    final future = task.fetcher();
    _inProgress[task.key] = future;

    try {
      final result = await future;
      _cache[task.key] = result;
    } catch (e) {
      // تجاهل الأخطاء في الجلب المسبق
    } finally {
      _inProgress.remove(task.key);
    }
  }

  /// الحصول على البيانات (من الكاش أو الجلب)
  Future<T> get<T>(String key, Future<T> Function() fetcher) async {
    if (_cache.containsKey(key)) {
      return _cache[key] as T;
    }

    if (_inProgress.containsKey(key)) {
      return await _inProgress[key] as T;
    }

    final result = await fetcher();
    _cache[key] = result;
    return result;
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

class _PrefetchTask {
  final String key;
  final Future<dynamic> Function() fetcher;
  final PrefetchPriority priority;

  _PrefetchTask({
    required this.key,
    required this.fetcher,
    required this.priority,
  });
}
```

### جلب مسبق ذكي

```dart
// lib/features/home/prefetch_strategy.dart
class HomePrefetchStrategy {
  final PrefetchManager _prefetch = PrefetchManager();
  final ApiClient _api;

  HomePrefetchStrategy(this._api);

  /// بدء الجلب المسبق للصفحة الرئيسية
  void startPrefetch() {
    // الأولوية العالية: بيانات المستخدم
    _prefetch.prefetch(
      'user_profile',
      () => _api.getUserProfile(),
      priority: PrefetchPriority.high,
    );

    // الأولوية المتوسطة: قوائم المحتوى
    _prefetch.prefetch(
      'featured_items',
      () => _api.getFeaturedItems(),
      priority: PrefetchPriority.medium,
    );

    _prefetch.prefetch(
      'categories',
      () => _api.getCategories(),
      priority: PrefetchPriority.medium,
    );

    // الأولوية المنخفضة: بيانات ثانوية
    _prefetch.prefetch(
      'notifications',
      () => _api.getNotifications(),
      priority: PrefetchPriority.low,
    );
  }

  /// جلب مسبق بناءً على سلوك المستخدم
  void prefetchOnHover(String itemId) {
    _prefetch.prefetch(
      'item_details:$itemId',
      () => _api.getItemDetails(itemId),
      priority: PrefetchPriority.high,
    );
  }
}
```

## Retry Logic (منطق إعادة المحاولة)

### إعادة المحاولة مع Exponential Backoff

```dart
// lib/core/network/retry_client.dart
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;

class RetryClient {
  final http.Client _inner;
  final int _maxRetries;
  final Duration _baseDelay;
  final Set<int> _retryStatusCodes;

  RetryClient({
    http.Client? inner,
    int maxRetries = 3,
    Duration baseDelay = const Duration(seconds: 1),
    Set<int>? retryStatusCodes,
  })  : _inner = inner ?? http.Client(),
        _maxRetries = maxRetries,
        _baseDelay = baseDelay,
        _retryStatusCodes = retryStatusCodes ?? {408, 429, 500, 502, 503, 504};

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _retryRequest(() => _inner.get(url, headers: headers));
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _retryRequest(() => _inner.post(url, headers: headers, body: body));
  }

  Future<http.Response> _retryRequest(
    Future<http.Response> Function() request,
  ) async {
    int attempt = 0;
    
    while (true) {
      attempt++;
      
      try {
        final response = await request();
        
        if (_shouldRetry(response.statusCode) && attempt <= _maxRetries) {
          await _delay(attempt);
          continue;
        }
        
        return response;
      } catch (e) {
        if (attempt > _maxRetries) {
          rethrow;
        }
        
        await _delay(attempt);
      }
    }
  }

  bool _shouldRetry(int statusCode) {
    return _retryStatusCodes.contains(statusCode);
  }

  Future<void> _delay(int attempt) async {
    // Exponential backoff with jitter
    final delay = _baseDelay * pow(2, attempt - 1);
    final jitter = Random().nextDouble() * 0.3 * delay.inMilliseconds;
    
    await Future.delayed(
      Duration(milliseconds: delay.inMilliseconds + jitter.toInt()),
    );
  }

  void close() {
    _inner.close();
  }
}
```

### Circuit Breaker Pattern

```dart
// lib/core/network/circuit_breaker.dart
enum CircuitState { closed, open, halfOpen }

class CircuitBreaker {
  final int _failureThreshold;
  final Duration _resetTimeout;
  final Duration _halfOpenTimeout;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  DateTime? _nextRetryTime;

  CircuitBreaker({
    int failureThreshold = 5,
    Duration resetTimeout = const Duration(seconds: 30),
    Duration halfOpenTimeout = const Duration(seconds: 10),
  })  : _failureThreshold = failureThreshold,
        _resetTimeout = resetTimeout,
        _halfOpenTimeout = halfOpenTimeout;

  CircuitState get state => _state;

  /// تنفيذ مع حماية Circuit Breaker
  Future<T> execute<T>(Future<T> Function() action) async {
    if (_state == CircuitState.open) {
      if (DateTime.now().isAfter(_nextRetryTime!)) {
        _state = CircuitState.halfOpen;
      } else {
        throw CircuitBreakerOpenException();
      }
    }

    try {
      final result = await action();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitState.closed;
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= _failureThreshold) {
      _state = CircuitState.open;
      _nextRetryTime = DateTime.now().add(_resetTimeout);
    }
  }

  void reset() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _lastFailureTime = null;
    _nextRetryTime = null;
  }
}

class CircuitBreakerOpenException implements Exception {
  @override
  String toString() => 'Circuit breaker is open';
}

// الاستخدام
class ApiService {
  final _circuitBreaker = CircuitBreaker();
  final _client = OptimizedHttpClient();

  Future<Response> fetchData() {
    return _circuitBreaker.execute(() => _client.get('/data'));
  }
}
```

## Response Caching

### طبقة كاش للشبكة

```dart
// lib/core/network/network_cache.dart
import 'dart:convert';

class NetworkCache {
  final Map<String, _CacheEntry> _cache = {};
  final Duration _defaultTtl;
  
  NetworkCache({Duration defaultTtl = const Duration(minutes: 5)})
      : _defaultTtl = defaultTtl;

  /// تخزين استجابة
  void put(String key, dynamic data, {Duration? ttl}) {
    _cache[key] = _CacheEntry(
      data: data,
      expiry: DateTime.now().add(ttl ?? _defaultTtl),
    );
  }

  /// جلب من الكاش
  T? get<T>(String key) {
    final entry = _cache[key];
    
    if (entry == null) return null;
    
    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      return null;
    }
    
    return entry.data as T;
  }

  /// جلب أو تنفيذ
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? ttl,
  }) async {
    final cached = get<T>(key);
    if (cached != null) return cached;

    final data = await fetcher();
    put(key, data, ttl: ttl);
    return data;
  }

  /// مسح الكاش
  void invalidate([String? key]) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }

  /// تنظيف المنتهي
  void cleanup() {
    final now = DateTime.now();
    _cache.removeWhere((_, entry) => now.isAfter(entry.expiry));
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry({required this.data, required this.expiry});
}
```

### ETag Support

```dart
// lib/core/network/etag_client.dart
class ETagClient {
  final http.Client _client;
  final Map<String, String> _etags = {};
  final NetworkCache _cache;

  ETagClient({http.Client? client, NetworkCache? cache})
      : _client = client ?? http.Client(),
        _cache = cache ?? NetworkCache();

  Future<http.Response> get(String url) async {
    final headers = <String, String>{};
    
    // إضافة ETag إذا موجود
    if (_etags.containsKey(url)) {
      headers['If-None-Match'] = _etags[url]!;
    }

    final response = await _client.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 304) {
      // لم يتغير، استخدم الكاش
      final cached = _cache.get<http.Response>(url);
      if (cached != null) return cached;
    }

    if (response.statusCode == 200) {
      // تحديث ETag والكاش
      final etag = response.headers['etag'];
      if (etag != null) {
        _etags[url] = etag;
      }
      _cache.put(url, response);
    }

    return response;
  }
}
```

## GraphQL Optimization

### تحسين استعلامات GraphQL

```dart
// lib/core/graphql/optimized_client.dart
class OptimizedGraphQLClient {
  final String _endpoint;
  final http.Client _client;
  final NetworkCache _cache;

  OptimizedGraphQLClient({
    required String endpoint,
    http.Client? client,
  })  : _endpoint = endpoint,
        _client = client ?? http.Client(),
        _cache = NetworkCache();

  /// استعلام مع تخزين مؤقت
  Future<Map<String, dynamic>> query(
    String query, {
    Map<String, dynamic>? variables,
    Duration? cacheTtl,
  }) async {
    final cacheKey = _generateCacheKey(query, variables);
    
    // التحقق من الكاش
    final cached = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'variables': variables,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    
    if (cacheTtl != null && !data.containsKey('errors')) {
      _cache.put(cacheKey, data, ttl: cacheTtl);
    }

    return data;
  }

  /// Query Batching
  Future<List<Map<String, dynamic>>> batchQuery(
    List<GraphQLOperation> operations,
  ) async {
    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(operations.map((op) => {
        return {
          'query': op.query,
          'variables': op.variables,
          'operationName': op.operationName,
        };
      }).toList()),
    );

    return (jsonDecode(response.body) as List)
        .cast<Map<String, dynamic>>();
  }

  String _generateCacheKey(String query, Map<String, dynamic>? variables) {
    final normalized = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    final varsString = variables != null ? jsonEncode(variables) : '';
    return '$normalized:$varsString'.hashCode.toString();
  }
}

class GraphQLOperation {
  final String query;
  final Map<String, dynamic>? variables;
  final String? operationName;

  GraphQLOperation({
    required this.query,
    this.variables,
    this.operationName,
  });
}
```

## قياس أداء الشبكة

```dart
// lib/core/network/network_metrics.dart
class NetworkMetrics {
  static final NetworkMetrics _instance = NetworkMetrics._internal();
  factory NetworkMetrics() => _instance;
  NetworkMetrics._internal();

  final _requests = <_RequestMetric>[];

  /// تسجيل طلب
  void recordRequest({
    required String url,
    required String method,
    required int statusCode,
    required Duration duration,
    int? requestSize,
    int? responseSize,
  }) {
    _requests.add(_RequestMetric(
      url: url,
      method: method,
      statusCode: statusCode,
      duration: duration,
      requestSize: requestSize,
      responseSize: responseSize,
      timestamp: DateTime.now(),
    ));

    // الاحتفاظ بآخر 100 طلب فقط
    if (_requests.length > 100) {
      _requests.removeAt(0);
    }
  }

  /// إحصائيات الأداء
  Map<String, dynamic> getStats() {
    if (_requests.isEmpty) return {};

    final durations = _requests.map((r) => r.duration.inMilliseconds).toList();
    durations.sort();

    return {
      'total_requests': _requests.length,
      'avg_duration_ms': durations.reduce((a, b) => a + b) ~/ durations.length,
      'p50_duration_ms': durations[durations.length ~/ 2],
      'p95_duration_ms': durations[(durations.length * 0.95).floor()],
      'p99_duration_ms': durations[(durations.length * 0.99).floor()],
      'error_rate': _requests.where((r) => r.statusCode >= 400).length / 
                    _requests.length,
    };
  }

  /// طلبات بطيئة
  List<_RequestMetric> getSlowRequests({Duration threshold = const Duration(seconds: 2)}) {
    return _requests
        .where((r) => r.duration > threshold)
        .toList()
      ..sort((a, b) => b.duration.compareTo(a.duration));
  }
}

class _RequestMetric {
  final String url;
  final String method;
  final int statusCode;
  final Duration duration;
  final int? requestSize;
  final int? responseSize;
  final DateTime timestamp;

  _RequestMetric({
    required this.url,
    required this.method,
    required this.statusCode,
    required this.duration,
    this.requestSize,
    this.responseSize,
    required this.timestamp,
  });
}
```

## قائمة المراجعة

### الطلبات
- [ ] إعادة استخدام اتصالات HTTP
- [ ] Request batching للطلبات المتعددة
- [ ] Request deduplication لمنع التكرار
- [ ] Retry logic مع exponential backoff

### التخزين المؤقت
- [ ] Response caching بـ TTL مناسب
- [ ] ETag support للتحقق من التغييرات
- [ ] Cache invalidation عند التحديث

### الأداء
- [ ] Compression (gzip/brotli)
- [ ] CDN للأصول الثابتة
- [ ] Prefetching للبيانات المتوقعة
- [ ] Circuit breaker للحماية من الأعطال

### القياس
- [ ] تسجيل مقاييس الأداء
- [ ] مراقبة الطلبات البطيئة
- [ ] تتبع معدل الأخطاء

## الأخطاء الشائعة

| الخطأ | المشكلة | الحل |
|-------|---------|------|
| اتصال جديد لكل طلب | overhead عالي | Connection pooling |
| لا retry | فشل مؤقت يسبب أخطاء | Retry with backoff |
| لا تخزين مؤقت | طلبات زائدة | Response caching |
| لا ضغط | بطء التحميل | gzip/brotli |
| طلبات متكررة | إهدار موارد | Deduplication |

---

**المرجع السابق:** [10-service-workers.md](./10-service-workers.md) - تكوين Service Workers
**المرجع التالي:** [12-state-management.md](./12-state-management.md) - تحسين إدارة الحالة
