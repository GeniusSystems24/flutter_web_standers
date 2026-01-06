# تحسين إدارة الحالة (State Management Optimization)

## المقدمة

إدارة الحالة السيئة تؤدي إلى إعادة بناء غير ضرورية للـ widgets، استهلاك ذاكرة زائد، وبطء في الاستجابة. هذا الملف يركز على تحسين أداء إدارة الحالة في Flutter Web.

## فهم مشاكل الأداء

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    مشاكل إدارة الحالة الشائعة                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ❌ الحالة السيئة                    ✅ الحالة المحسنة                        │
│  ┌───────────────────┐               ┌───────────────────┐                  │
│  │   Root Widget     │               │   Root Widget     │                  │
│  │   (State Here)    │               │   (No State)      │                  │
│  │        │          │               │        │          │                  │
│  │   ┌────┴────┐     │               │   ┌────┴────┐     │                  │
│  │   ▼         ▼     │               │   ▼         ▼     │                  │
│  │ Child A  Child B  │               │ Provider   Child B │                  │
│  │   │         │     │               │    │              │                  │
│  │   ▼         ▼     │               │    ▼              │                  │
│  │ Grandchild        │               │ Consumer Only     │                  │
│  └───────────────────┘               └───────────────────┘                  │
│                                                                             │
│  كل تغيير يعيد بناء                  فقط المستهلك يُعاد بناؤه                │
│  الشجرة بالكامل                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Provider المحسن

### تجنب إعادة البناء غير الضرورية

```dart
// ❌ خطأ: كل شيء يُعاد بناؤه
class BadExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // هذا يستمع لكل التغييرات
    final user = context.watch<UserProvider>().user;
    final cart = context.watch<CartProvider>().cart;
    final theme = context.watch<ThemeProvider>().theme;
    
    return Column(
      children: [
        Text(user.name),  // يُعاد بناؤه عند تغيير السلة!
        Text('${cart.itemCount} items'),
        Icon(Icons.person, color: theme.primaryColor),
      ],
    );
  }
}

// ✅ صحيح: كل widget يستمع لما يحتاجه فقط
class GoodExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const UserNameWidget(),   // مستقل
        const CartCountWidget(),   // مستقل
        const ThemedIcon(),        // مستقل
      ],
    );
  }
}

class UserNameWidget extends StatelessWidget {
  const UserNameWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // يستمع فقط للاسم
    final name = context.select<UserProvider, String>((p) => p.user.name);
    return Text(name);
  }
}

class CartCountWidget extends StatelessWidget {
  const CartCountWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // يستمع فقط للعدد
    final count = context.select<CartProvider, int>((p) => p.cart.itemCount);
    return Text('$count items');
  }
}

class ThemedIcon extends StatelessWidget {
  const ThemedIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final color = context.select<ThemeProvider, Color>((p) => p.theme.primaryColor);
    return Icon(Icons.person, color: color);
  }
}
```

### استخدام Selector للتحكم الدقيق

```dart
// lib/features/products/presentation/widgets/product_card.dart
class ProductCard extends StatelessWidget {
  final String productId;
  
  const ProductCard({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // الصورة: تتغير نادراً
          Selector<ProductsProvider, String>(
            selector: (_, p) => p.getProduct(productId).imageUrl,
            builder: (_, imageUrl, __) => CachedNetworkImage(
              imageUrl: imageUrl,
            ),
          ),
          
          // الاسم: يتغير نادراً
          Selector<ProductsProvider, String>(
            selector: (_, p) => p.getProduct(productId).name,
            builder: (_, name, __) => Text(name),
          ),
          
          // السعر: قد يتغير
          Selector<ProductsProvider, double>(
            selector: (_, p) => p.getProduct(productId).price,
            builder: (_, price, __) => Text('\$$price'),
          ),
          
          // حالة المفضلة: تتغير كثيراً
          Selector<FavoritesProvider, bool>(
            selector: (_, p) => p.isFavorite(productId),
            builder: (_, isFav, __) => IconButton(
              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
              onPressed: () => context.read<FavoritesProvider>().toggle(productId),
            ),
          ),
        ],
      ),
    );
  }
}
```

### ProxyProvider للبيانات المشتقة

```dart
// lib/core/providers/providers_setup.dart
MultiProvider(
  providers: [
    // Providers أساسية
    ChangeNotifierProvider(create: (_) => UserProvider()),
    ChangeNotifierProvider(create: (_) => CartProvider()),
    ChangeNotifierProvider(create: (_) => ProductsProvider()),
    
    // بيانات مشتقة (computed)
    ProxyProvider2<CartProvider, ProductsProvider, CartSummary>(
      update: (_, cart, products, __) => CartSummary(
        itemCount: cart.items.length,
        totalPrice: cart.items.fold(
          0.0,
          (sum, item) => sum + products.getProduct(item.productId).price * item.quantity,
        ),
        hasDiscounts: cart.items.any((item) => 
          products.getProduct(item.productId).hasDiscount,
        ),
      ),
    ),
  ],
  child: const MyApp(),
)

// استخدام البيانات المشتقة
class CartSummaryWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // يستمع فقط للملخص، لا لكل التغييرات
    final summary = context.watch<CartSummary>();
    
    return Column(
      children: [
        Text('${summary.itemCount} items'),
        Text('\$${summary.totalPrice}'),
        if (summary.hasDiscounts) const DiscountBadge(),
      ],
    );
  }
}
```

## Riverpod المحسن

### StateNotifier vs ChangeNotifier

```dart
// ✅ StateNotifier: أفضل للأداء (immutable state)
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(CartItem item) {
    state = state.copyWith(
      items: [...state.items, item],
    );
  }

  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((i) => i.id != itemId).toList(),
    );
  }

  void updateQuantity(String itemId, int quantity) {
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.id == itemId) {
          return i.copyWith(quantity: quantity);
        }
        return i;
      }).toList(),
    );
  }
}

@freezed
class CartState with _$CartState {
  const factory CartState({
    @Default([]) List<CartItem> items,
    @Default(false) bool isLoading,
    String? error,
  }) = _CartState;
}

// Provider definition
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
```

### select للتحكم في إعادة البناء

```dart
// lib/features/cart/presentation/widgets/cart_badge.dart
class CartBadge extends ConsumerWidget {
  const CartBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // يستمع فقط لعدد العناصر
    final itemCount = ref.watch(
      cartProvider.select((state) => state.items.length),
    );

    if (itemCount == 0) return const SizedBox.shrink();

    return Badge(
      label: Text('$itemCount'),
      child: const Icon(Icons.shopping_cart),
    );
  }
}

// مثال آخر: مجموع السعر
class CartTotal extends ConsumerWidget {
  const CartTotal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // يستمع فقط للمجموع
    final total = ref.watch(
      cartProvider.select((state) => 
        state.items.fold(0.0, (sum, item) => sum + item.total),
      ),
    );

    return Text('\$${total.toStringAsFixed(2)}');
  }
}
```

### Family Providers للبيانات المتعددة

```dart
// lib/features/products/providers/product_provider.dart

// Provider لمنتج واحد
final productProvider = FutureProvider.family<Product, String>((ref, id) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProduct(id);
});

// استخدام مع التخزين المؤقت التلقائي
class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productId));

    return productAsync.when(
      loading: () => const ProductSkeleton(),
      error: (e, _) => ErrorWidget(e),
      data: (product) => ProductDetails(product: product),
    );
  }
}
```

### AutoDispose للتنظيف التلقائي

```dart
// يُنظف تلقائياً عند عدم الاستخدام
final searchResultsProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, query) async {
  // إلغاء الطلب عند التخلص
  final cancelToken = CancelToken();
  ref.onDispose(() => cancelToken.cancel());

  // تأخير للـ debouncing
  await Future.delayed(const Duration(milliseconds: 300));
  
  // التحقق من الإلغاء
  if (cancelToken.isCancelled) throw Exception('Cancelled');

  final repository = ref.watch(productRepositoryProvider);
  return repository.search(query, cancelToken: cancelToken);
});
```

## BLoC المحسن

### تجنب emit غير الضرورية

```dart
// lib/features/counter/bloc/counter_bloc.dart
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState()) {
    on<CounterIncremented>(_onIncremented);
    on<CounterDecremented>(_onDecremented);
    on<CounterReset>(_onReset);
  }

  void _onIncremented(CounterIncremented event, Emitter<CounterState> emit) {
    // ✅ التحقق قبل emit
    final newValue = state.value + 1;
    if (newValue != state.value) {
      emit(state.copyWith(value: newValue));
    }
  }

  void _onDecremented(CounterDecremented event, Emitter<CounterState> emit) {
    final newValue = state.value - 1;
    if (newValue >= 0 && newValue != state.value) {
      emit(state.copyWith(value: newValue));
    }
  }

  void _onReset(CounterReset event, Emitter<CounterState> emit) {
    // ✅ لا تُرسل إذا كانت القيمة صفر أصلاً
    if (state.value != 0) {
      emit(const CounterState());
    }
  }
}
```

### BlocSelector للتحكم في إعادة البناء

```dart
// lib/features/user/presentation/widgets/user_avatar.dart
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    // يستمع فقط للصورة
    return BlocSelector<UserBloc, UserState, String?>(
      selector: (state) => state.user?.avatarUrl,
      builder: (context, avatarUrl) {
        if (avatarUrl == null) {
          return const CircleAvatar(child: Icon(Icons.person));
        }
        return CircleAvatar(
          backgroundImage: NetworkImage(avatarUrl),
        );
      },
    );
  }
}

class UserName extends StatelessWidget {
  const UserName({super.key});

  @override
  Widget build(BuildContext context) {
    // يستمع فقط للاسم
    return BlocSelector<UserBloc, UserState, String>(
      selector: (state) => state.user?.name ?? 'Guest',
      builder: (context, name) => Text(name),
    );
  }
}
```

### buildWhen لتحسين الأداء

```dart
// lib/features/feed/presentation/screens/feed_screen.dart
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<FeedBloc, FeedState>(
        // إعادة البناء فقط عند تغيير القائمة
        buildWhen: (previous, current) {
          return previous.posts != current.posts;
        },
        builder: (context, state) {
          return ListView.builder(
            itemCount: state.posts.length,
            itemBuilder: (context, index) {
              return PostCard(post: state.posts[index]);
            },
          );
        },
      ),
      floatingActionButton: BlocBuilder<FeedBloc, FeedState>(
        // إعادة البناء فقط عند تغيير حالة التحميل
        buildWhen: (previous, current) {
          return previous.isLoading != current.isLoading;
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const CircularProgressIndicator();
          }
          return FloatingActionButton(
            onPressed: () => context.read<FeedBloc>().add(FeedRefreshed()),
            child: const Icon(Icons.refresh),
          );
        },
      ),
    );
  }
}
```

### MultiBlocListener vs متعدد BlocListener

```dart
// ❌ خطأ: متعددة متداخلة
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) { /* ... */ },
  child: BlocListener<CartBloc, CartState>(
    listener: (context, state) { /* ... */ },
    child: BlocListener<NotificationBloc, NotificationState>(
      listener: (context, state) { /* ... */ },
      child: const HomeScreen(),
    ),
  ),
)

// ✅ صحيح: MultiBlocListener
MultiBlocListener(
  listeners: [
    BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
    ),
    BlocListener<CartBloc, CartState>(
      listenWhen: (previous, current) => current.error != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!)),
        );
      },
    ),
    BlocListener<NotificationBloc, NotificationState>(
      listenWhen: (previous, current) => 
        current.unreadCount > previous.unreadCount,
      listener: (context, state) {
        // عرض إشعار
      },
    ),
  ],
  child: const HomeScreen(),
)
```

## GetX المحسن

### استخدام Obx بدلاً من GetX widget

```dart
// lib/features/counter/controllers/counter_controller.dart
class CounterController extends GetxController {
  final count = 0.obs;
  final isLoading = false.obs;

  void increment() => count.value++;
  void decrement() => count.value--;
}

// ❌ خطأ: GetX يستمع لكل شيء
GetX<CounterController>(
  builder: (controller) {
    // يُعاد بناؤه عند تغيير count أو isLoading
    return Text('${controller.count}');
  },
)

// ✅ صحيح: Obx للـ observable محددة
Obx(() {
  // يُعاد بناؤه فقط عند تغيير count
  return Text('${Get.find<CounterController>().count}');
})

// ✅ أفضل: تجميع في const widget
class CounterText extends StatelessWidget {
  const CounterText({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<CounterController>();
      return Text('${controller.count}');
    });
  }
}
```

### Workers للتفاعل مع التغييرات

```dart
class SearchController extends GetxController {
  final searchQuery = ''.obs;
  final results = <Product>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    
    // Debounce للبحث
    debounce(
      searchQuery,
      _performSearch,
      time: const Duration(milliseconds: 500),
    );
    
    // Ever للتحليلات
    ever(searchQuery, (query) {
      if (query.isNotEmpty) {
        Analytics.logSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      results.clear();
      return;
    }

    isLoading.value = true;
    try {
      results.value = await _repository.search(query);
    } finally {
      isLoading.value = false;
    }
  }
}
```

## تحسينات عامة

### Immutable State

```dart
// lib/core/state/immutable_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_state.freezed.dart';

@freezed
class UserState with _$UserState {
  const factory UserState({
    User? user,
    @Default(false) bool isLoading,
    @Default(false) bool isAuthenticated,
    String? error,
  }) = _UserState;

  const UserState._();

  // Computed properties
  bool get hasError => error != null;
  String get displayName => user?.name ?? 'Guest';
}

// الاستخدام
final state = UserState(user: user, isAuthenticated: true);
final newState = state.copyWith(isLoading: true);

// المقارنة سهلة وسريعة
if (state != newState) {
  // تغير
}
```

### Lazy Loading للـ Providers

```dart
// lib/core/providers/lazy_providers.dart

// Provider يُحمّل عند الحاجة فقط
final heavyFeatureProvider = Provider<HeavyFeature>((ref) {
  return HeavyFeature();
});

// استخدام lazy loading
class SettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        // يُحمّل فقط عند الضغط
        final feature = ref.read(heavyFeatureProvider);
        feature.doSomething();
      },
      child: const Text('Use Feature'),
    );
  }
}
```

### تجزئة الحالة

```dart
// ❌ خطأ: حالة ضخمة واحدة
class AppState {
  final User? user;
  final List<Product> products;
  final Cart cart;
  final List<Order> orders;
  final Settings settings;
  final List<Notification> notifications;
  // ... المزيد
}

// ✅ صحيح: حالات منفصلة
// كل feature لديها حالتها الخاصة

// User feature
final userProvider = StateNotifierProvider<UserNotifier, UserState>(...);

// Products feature
final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>(...);

// Cart feature
final cartProvider = StateNotifierProvider<CartNotifier, CartState>(...);

// Orders feature
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>(...);

// هذا يسمح بـ:
// 1. إعادة بناء أقل
// 2. تحميل مؤجل لكل feature
// 3. اختبار أسهل
// 4. كود أوضح
```

### Memoization للحسابات المكلفة

```dart
// lib/core/utils/memoize.dart
class Memoize<T, R> {
  final R Function(T) _compute;
  final Map<T, R> _cache = {};

  Memoize(this._compute);

  R call(T input) {
    return _cache.putIfAbsent(input, () => _compute(input));
  }

  void clear() => _cache.clear();
  void remove(T input) => _cache.remove(input);
}

// الاستخدام في Provider
class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  
  // Memoized computed value
  final _totalCalculator = Memoize<List<CartItem>, double>((items) {
    return items.fold(0.0, (sum, item) => sum + item.total);
  });

  double get total => _totalCalculator(_items);

  void addItem(CartItem item) {
    _items = [..._items, item];
    _totalCalculator.remove(_items); // إبطال الكاش
    notifyListeners();
  }
}
```

## أنماط أداء متقدمة

### Repository Pattern مع Caching

```dart
// lib/features/products/data/repositories/products_repository.dart
class ProductsRepository {
  final ApiClient _api;
  final LocalStorage _storage;
  final _cache = <String, Product>{};
  
  ProductsRepository(this._api, this._storage);

  Future<Product> getProduct(String id) async {
    // 1. التحقق من الكاش في الذاكرة
    if (_cache.containsKey(id)) {
      return _cache[id]!;
    }

    // 2. التحقق من التخزين المحلي
    final local = await _storage.getProduct(id);
    if (local != null && !local.isStale) {
      _cache[id] = local;
      return local;
    }

    // 3. جلب من الشبكة
    final product = await _api.getProduct(id);
    
    // 4. تخزين في الكاش والتخزين المحلي
    _cache[id] = product;
    await _storage.saveProduct(product);
    
    return product;
  }

  Future<List<Product>> getProducts({int page = 1}) async {
    final products = await _api.getProducts(page: page);
    
    // تخزين في الكاش
    for (final product in products) {
      _cache[product.id] = product;
    }
    
    return products;
  }

  void invalidateCache([String? id]) {
    if (id != null) {
      _cache.remove(id);
    } else {
      _cache.clear();
    }
  }
}
```

### Optimistic Updates

```dart
// lib/features/favorites/bloc/favorites_bloc.dart
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoritesRepository _repository;

  FavoritesBloc(this._repository) : super(const FavoritesState()) {
    on<FavoriteToggled>(_onToggled);
  }

  Future<void> _onToggled(
    FavoriteToggled event,
    Emitter<FavoritesState> emit,
  ) async {
    final productId = event.productId;
    final wasFavorite = state.favorites.contains(productId);

    // 1. تحديث متفائل (فوري)
    if (wasFavorite) {
      emit(state.copyWith(
        favorites: state.favorites.where((id) => id != productId).toSet(),
      ));
    } else {
      emit(state.copyWith(
        favorites: {...state.favorites, productId},
      ));
    }

    // 2. تحديث الخادم
    try {
      if (wasFavorite) {
        await _repository.removeFavorite(productId);
      } else {
        await _repository.addFavorite(productId);
      }
    } catch (e) {
      // 3. التراجع عند الفشل
      if (wasFavorite) {
        emit(state.copyWith(
          favorites: {...state.favorites, productId},
          error: 'Failed to remove favorite',
        ));
      } else {
        emit(state.copyWith(
          favorites: state.favorites.where((id) => id != productId).toSet(),
          error: 'Failed to add favorite',
        ));
      }
    }
  }
}
```

## قياس أداء إدارة الحالة

```dart
// lib/core/debug/state_performance.dart
import 'package:flutter/foundation.dart';

class StatePerformanceMonitor {
  static final _rebuilds = <String, int>{};
  static final _times = <String, List<int>>{};

  static void recordRebuild(String widgetName) {
    _rebuilds[widgetName] = (_rebuilds[widgetName] ?? 0) + 1;
  }

  static void recordBuildTime(String widgetName, int microseconds) {
    _times.putIfAbsent(widgetName, () => []).add(microseconds);
  }

  static void printReport() {
    if (!kDebugMode) return;

    print('=== State Performance Report ===');
    print('\nRebuilds:');
    final sortedRebuilds = _rebuilds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedRebuilds.take(10)) {
      print('  ${entry.key}: ${entry.value} rebuilds');
    }

    print('\nBuild Times:');
    for (final entry in _times.entries) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      final max = entry.value.reduce((a, b) => a > b ? a : b);
      print('  ${entry.key}: avg=${avg.toStringAsFixed(0)}μs, max=${max}μs');
    }
  }

  static void reset() {
    _rebuilds.clear();
    _times.clear();
  }
}

// استخدام في Widget
class MonitoredWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stopwatch = Stopwatch()..start();
    
    StatePerformanceMonitor.recordRebuild('MonitoredWidget');
    
    final result = _buildContent(context);
    
    stopwatch.stop();
    StatePerformanceMonitor.recordBuildTime(
      'MonitoredWidget',
      stopwatch.elapsedMicroseconds,
    );
    
    return result;
  }

  Widget _buildContent(BuildContext context) {
    // المحتوى الفعلي
    return Container();
  }
}
```

## قائمة المراجعة

### التصميم
- [ ] تجزئة الحالة إلى وحدات صغيرة
- [ ] استخدام Immutable state
- [ ] فصل UI state عن domain state

### Provider
- [ ] استخدام `select` بدلاً من `watch`
- [ ] تجنب `watch` في root widget
- [ ] استخدام `const` widgets

### Riverpod
- [ ] استخدام `StateNotifier` للحالة المعقدة
- [ ] استخدام `autoDispose` للتنظيف
- [ ] استخدام `family` للبيانات المتعددة

### BLoC
- [ ] استخدام `buildWhen` و `listenWhen`
- [ ] استخدام `BlocSelector` للتحكم الدقيق
- [ ] تجنب `emit` غير الضرورية

### القياس
- [ ] مراقبة عدد rebuilds
- [ ] قياس build time
- [ ] تحديد widgets بطيئة

## الأخطاء الشائعة

| الخطأ | المشكلة | الحل |
|-------|---------|------|
| `watch` بدون `select` | إعادة بناء كثيرة | استخدام `select` |
| حالة ضخمة واحدة | كل تغيير يؤثر على الكل | تجزئة الحالة |
| mutable state | مقارنة غير موثوقة | immutable state |
| computed في build | حسابات متكررة | memoization |
| لا `const` | widgets جديدة كل مرة | استخدام `const` |

---

**المرجع السابق:** [11-network-optimization.md](./11-network-optimization.md) - تحسين الشبكة
**المرجع التالي:** [13-measurement-tools.md](./13-measurement-tools.md) - أدوات القياس والمراقبة
