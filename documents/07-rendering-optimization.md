# 🎨 تحسين الرسم والتصيير (Rendering Optimization)

## المقدمة

تحسين الرسم والتصيير هو أحد أهم العوامل للحصول على تجربة مستخدم سلسة. حتى لو كان التحميل الأولي سريعاً، فإن الأداء السيء أثناء التفاعل سيفسد التجربة.

```
┌─────────────────────────────────────────────────────────────────┐
│                    دورة الإطار (Frame Cycle)                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Input → Animation → Build → Layout → Paint → Composite → Display
│                                                                 │
│  ←────────────────── 16.67ms للحصول على 60fps ─────────────────→ │
│  ←────────────────── 8.33ms للحصول على 120fps ─────────────────→ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## أهداف الأداء

| المقياس | الهدف | الحد الأقصى |
|---------|-------|-------------|
| Frame Time | < 16ms | 33ms |
| Frame Rate | 60 fps | 30 fps min |
| Jank Frames | 0% | < 5% |
| Build Time | < 4ms | 8ms |
| Paint Time | < 4ms | 8ms |

---

## 1. تحسين Build Phase

### المشكلة: إعادة البناء غير الضرورية

```dart
// ❌ خطأ: Widget ضخم يُعاد بناؤه بالكامل
class BadProductPage extends StatefulWidget {
  @override
  State<BadProductPage> createState() => _BadProductPageState();
}

class _BadProductPageState extends State<BadProductPage> {
  int _cartCount = 0;
  
  @override
  Widget build(BuildContext context) {
    print('Building entire page'); // يُطبع مع كل تغيير
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
        actions: [
          // عند تغيير _cartCount، يُعاد بناء الصفحة كاملة!
          Badge(
            label: Text('$_cartCount'),
            child: IconButton(
              icon: Icon(Icons.shopping_cart),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // كل هذا يُعاد بناؤه دون داعٍ
          ExpensiveProductList(),
          ExpensiveRecommendations(),
          ExpensiveReviews(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _cartCount++),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### الحل: تجزئة Widgets

```dart
// ✅ صحيح: تجزئة إلى widgets صغيرة ومستقلة
class GoodProductPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
        actions: [
          // Widget منفصل للـ cart badge
          CartBadge(),
        ],
      ),
      body: Column(
        children: [
          // كل widget تدير حالتها الخاصة
          ProductList(),
          Recommendations(),
          Reviews(),
        ],
      ),
      floatingActionButton: AddToCartButton(),
    );
  }
}

// Cart Badge منفصل
class CartBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // استخدام Selector لقراءة قيمة واحدة فقط
    return Selector<CartProvider, int>(
      selector: (_, cart) => cart.itemCount,
      builder: (context, count, child) {
        print('Building only CartBadge'); // يُطبع فقط عند تغيير count
        return Badge(
          label: Text('$count'),
          child: child,
        );
      },
      child: IconButton(
        icon: Icon(Icons.shopping_cart),
        onPressed: () => Navigator.pushNamed(context, '/cart'),
      ),
    );
  }
}
```

---

## 2. استخدام const Constructors

```dart
// ❌ خطأ: يُنشئ instances جديدة مع كل build
class BadExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16), // جديد كل مرة
          child: Text(
            'Welcome',
            style: TextStyle(fontSize: 24), // جديد كل مرة
          ),
        ),
        Icon(Icons.home, size: 48), // جديد كل مرة
        SizedBox(height: 16), // جديد كل مرة
      ],
    );
  }
}

// ✅ صحيح: استخدام const
class GoodExample extends StatelessWidget {
  const GoodExample({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16), // يُعاد استخدامه
          child: Text(
            'Welcome',
            style: TextStyle(fontSize: 24), // يُعاد استخدامه
          ),
        ),
        Icon(Icons.home, size: 48), // يُعاد استخدامه
        SizedBox(height: 16), // يُعاد استخدامه
      ],
    );
  }
}
```

### قاعدة const الذهبية

```dart
// إنشاء const widgets قابلة لإعادة الاستخدام
class AppConstants {
  AppConstants._();
  
  // Spacing
  static const smallGap = SizedBox(height: 8);
  static const mediumGap = SizedBox(height: 16);
  static const largeGap = SizedBox(height: 24);
  static const horizontalSmallGap = SizedBox(width: 8);
  static const horizontalMediumGap = SizedBox(width: 16);
  
  // Dividers
  static const thinDivider = Divider(height: 1);
  static const thickDivider = Divider(height: 2, thickness: 2);
  
  // Padding
  static const screenPadding = EdgeInsets.all(16);
  static const cardPadding = EdgeInsets.all(12);
  static const listItemPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
  
  // Common widgets
  static const loadingIndicator = Center(
    child: CircularProgressIndicator(),
  );
  
  static const emptyState = Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('No items found'),
      ],
    ),
  );
}

// الاستخدام
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Title'),
        AppConstants.mediumGap, // const معاد استخدامه
        const Text('Content'),
        AppConstants.largeGap,
        if (isLoading) AppConstants.loadingIndicator,
      ],
    );
  }
}
```

---

## 3. تحسين القوائم (ListView Optimization)

### Builder Pattern

```dart
// ❌ خطأ: إنشاء جميع العناصر دفعة واحدة
class BadList extends StatelessWidget {
  final List<Product> products; // 1000 منتج
  
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: products.map((p) => ProductCard(p)).toList(),
      // ^ ينشئ 1000 widget دفعة واحدة!
    );
  }
}

// ✅ صحيح: إنشاء العناصر عند الحاجة
class GoodList extends StatelessWidget {
  final List<Product> products;
  
  const GoodList({required this.products, super.key});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        // ينشئ فقط العناصر المرئية (~10-15 عادةً)
        return ProductCard(product: products[index]);
      },
    );
  }
}
```

### Separated Builder للقوائم مع فواصل

```dart
class ProductListWithDividers extends StatelessWidget {
  final List<Product> products;
  
  const ProductListWithDividers({required this.products, super.key});
  
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return ProductTile(product: products[index]);
      },
    );
  }
}
```

### استخدام itemExtent للأداء الأمثل

```dart
// ✅ أسرع: تحديد ارتفاع ثابت للعناصر
class OptimizedList extends StatelessWidget {
  final List<Item> items;
  
  const OptimizedList({required this.items, super.key});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemExtent: 72, // ارتفاع ثابت = تخطي حسابات Layout
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(items[index].name),
          subtitle: Text(items[index].description),
        );
      },
    );
  }
}

// أو استخدام prototypeItem
class PrototypeList extends StatelessWidget {
  final List<Item> items;
  
  const PrototypeList({required this.items, super.key});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      prototypeItem: const ListTile(
        title: Text('Prototype'),
        subtitle: Text('For measurement'),
      ),
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(items[index].name),
          subtitle: Text(items[index].description),
        );
      },
    );
  }
}
```

### Sliver للقوائم المعقدة

```dart
class ComplexScrollView extends StatelessWidget {
  final List<Category> categories;
  
  const ComplexScrollView({required this.categories, super.key});
  
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header مع تأثير collapse
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Products'),
            background: Image.network(
              'header.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // قسم البحث (ثابت)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SearchBar(),
          ),
        ),
        
        // فئات المنتجات
        for (final category in categories) ...[
          // عنوان الفئة
          SliverToBoxAdapter(
            child: CategoryHeader(category: category),
          ),
          
          // منتجات الفئة (grid)
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ProductCard(
                  product: category.products[index],
                );
              },
              childCount: category.products.length,
            ),
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ],
    );
  }
}
```

---

## 4. تحسين الصور في القوائم

```dart
class OptimizedImageList extends StatelessWidget {
  final List<ImageItem> images;
  
  const OptimizedImageList({required this.images, super.key});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) {
        return OptimizedNetworkImage(
          url: images[index].url,
          width: 300,
          height: 200,
        );
      },
    );
  }
}

class OptimizedNetworkImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  
  const OptimizedNetworkImage({
    required this.url,
    required this.width,
    required this.height,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        // تحديد حجم الـ cache
        cacheWidth: (width * MediaQuery.of(context).devicePixelRatio).toInt(),
        cacheHeight: (height * MediaQuery.of(context).devicePixelRatio).toInt(),
        // Placeholder أثناء التحميل
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        // صورة الخطأ
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image),
          );
        },
      ),
    );
  }
}
```

### استخدام CachedNetworkImage

```dart
// pubspec.yaml
// dependencies:
//   cached_network_image: ^3.3.0

import 'package:cached_network_image/cached_network_image.dart';

class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  
  const CachedImageWidget({required this.imageUrl, super.key});
  
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      // استخدام placeholder خفيف
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.error),
      ),
      // تخزين مؤقت محسن
      memCacheWidth: 300,
      memCacheHeight: 300,
      maxWidthDiskCache: 600,
      maxHeightDiskCache: 600,
      fadeInDuration: const Duration(milliseconds: 300),
    );
  }
}
```

---

## 5. تجنب Opacity و ClipRRect

```dart
// ❌ خطأ: Opacity يستهلك موارد كثيرة
Widget badOpacity() {
  return Opacity(
    opacity: 0.5,
    child: Container(
      width: 200,
      height: 200,
      color: Colors.blue,
      child: const Text('Expensive!'),
    ),
  );
}

// ✅ صحيح: استخدام Color مع alpha
Widget goodOpacity() {
  return Container(
    width: 200,
    height: 200,
    color: Colors.blue.withOpacity(0.5), // أو Color(0x800000FF)
    child: const Text('Efficient!'),
  );
}

// ❌ خطأ: ClipRRect على محتوى كبير
Widget badClip() {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: ExpensiveWidget(), // يُعاد قص كل frame
  );
}

// ✅ صحيح: استخدام decoration
Widget goodClip() {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
    ),
    child: const ExpensiveWidget(),
  );
}
```

### AnimatedOpacity بدل Opacity

```dart
class FadeInWidget extends StatefulWidget {
  final Widget child;
  
  const FadeInWidget({required this.child, super.key});
  
  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget> {
  bool _visible = false;
  
  @override
  void initState() {
    super.initState();
    // تأخير بسيط قبل الإظهار
    Future.microtask(() => setState(() => _visible = true));
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      // curve محسن للأداء
      curve: Curves.easeOut,
      child: widget.child,
    );
  }
}
```

---

## 6. RepaintBoundary للعزل

```dart
class ComplexPage extends StatelessWidget {
  const ComplexPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header ثابت - لا يحتاج إعادة رسم
        const RepaintBoundary(
          child: AppHeader(),
        ),
        
        // محتوى متحرك - يُعاد رسمه بشكل مستقل
        Expanded(
          child: RepaintBoundary(
            child: AnimatedContent(),
          ),
        ),
        
        // Footer ثابت
        const RepaintBoundary(
          child: AppFooter(),
        ),
      ],
    );
  }
}

// Widget معقد يستحق العزل
class ExpensiveChart extends StatelessWidget {
  final List<DataPoint> data;
  
  const ExpensiveChart({required this.data, super.key});
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: ChartPainter(data),
        size: const Size(400, 300),
      ),
    );
  }
}
```

### متى نستخدم RepaintBoundary

```
┌─────────────────────────────────────────────────────────────┐
│                   استخدم RepaintBoundary                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ✅ Widgets معقدة بصرياً (Charts, Maps)                     │
│  ✅ محتوى ثابت بجوار محتوى متحرك                            │
│  ✅ قوائم طويلة مع عناصر معقدة                              │
│  ✅ صور مع تأثيرات                                         │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                  لا تستخدم RepaintBoundary                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ❌ Widgets بسيطة (Text, Icon)                              │
│  ❌ كل widget في القائمة                                   │
│  ❌ المحتوى الذي يتغير مع كل frame                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. تحسين الرسوم المتحركة

### استخدام AnimatedBuilder

```dart
// ❌ خطأ: إعادة بناء كل شيء
class BadAnimation extends StatefulWidget {
  @override
  State<BadAnimation> createState() => _BadAnimationState();
}

class _BadAnimationState extends State<BadAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // كل شيء يُعاد بناؤه مع كل frame!
        return Transform.rotate(
          angle: _controller.value * 2 * pi,
          child: Column(
            children: [
              ExpensiveWidget1(),
              ExpensiveWidget2(),
              const Icon(Icons.refresh, size: 48),
            ],
          ),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ✅ صحيح: استخدام child parameter
class GoodAnimation extends StatefulWidget {
  const GoodAnimation({super.key});
  
  @override
  State<GoodAnimation> createState() => _GoodAnimationState();
}

class _GoodAnimationState extends State<GoodAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      // child يُبنى مرة واحدة فقط
      child: const Column(
        children: [
          ExpensiveWidget1(),
          ExpensiveWidget2(),
          Icon(Icons.refresh, size: 48),
        ],
      ),
      builder: (context, child) {
        // فقط Transform يُعاد بناؤه
        return Transform.rotate(
          angle: _controller.value * 2 * pi,
          child: child, // نفس الـ child
        );
      },
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### TweenAnimationBuilder للرسوم البسيطة

```dart
class SimpleScaleAnimation extends StatelessWidget {
  final bool isExpanded;
  final Widget child;
  
  const SimpleScaleAnimation({
    required this.isExpanded,
    required this.child,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: isExpanded ? 0.8 : 1.0,
        end: isExpanded ? 1.0 : 0.8,
      ),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: child, // لا يُعاد بناؤه
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
    );
  }
}
```

### Implicit Animations

```dart
class ImplicitAnimationExample extends StatefulWidget {
  const ImplicitAnimationExample({super.key});
  
  @override
  State<ImplicitAnimationExample> createState() => 
      _ImplicitAnimationExampleState();
}

class _ImplicitAnimationExampleState extends State<ImplicitAnimationExample> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _isExpanded ? 200 : 100,
        height: _isExpanded ? 200 : 100,
        decoration: BoxDecoration(
          color: _isExpanded ? Colors.blue : Colors.red,
          borderRadius: BorderRadius.circular(_isExpanded ? 16 : 8),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isExpanded ? Icons.close : Icons.add,
            key: ValueKey(_isExpanded),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
```

---

## 8. تحسين CustomPainter

```dart
class OptimizedChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  
  // إنشاء Paint مرة واحدة
  late final Paint _linePaint;
  late final Paint _fillPaint;
  
  // Caching للمسارات
  Path? _cachedPath;
  List<double>? _cachedValues;
  
  OptimizedChartPainter({
    required this.values,
    required this.color,
  }) {
    _linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    _fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    
    // استخدام المسار المخزن إذا لم تتغير القيم
    if (_cachedPath != null && _listEquals(_cachedValues, values)) {
      canvas.drawPath(_cachedPath!, _fillPaint);
      canvas.drawPath(_cachedPath!, _linePaint);
      return;
    }
    
    // بناء المسار
    final path = Path();
    final dx = size.width / (values.length - 1);
    final maxValue = values.reduce(max);
    
    for (var i = 0; i < values.length; i++) {
      final x = i * dx;
      final y = size.height - (values[i] / maxValue * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    // مسار التعبئة
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    
    canvas.drawPath(fillPath, _fillPaint);
    canvas.drawPath(path, _linePaint);
    
    // تخزين للاستخدام لاحقاً
    _cachedPath = path;
    _cachedValues = List.from(values);
  }
  
  @override
  bool shouldRepaint(OptimizedChartPainter oldDelegate) {
    // إعادة الرسم فقط عند تغير القيم
    return !_listEquals(values, oldDelegate.values) || 
           color != oldDelegate.color;
  }
  
  bool _listEquals(List<double>? a, List<double>? b) {
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
```

---

## 9. Keys الصحيحة

```dart
// ❌ خطأ: بدون keys - يُعاد بناء كل شيء
class BadKeyExample extends StatelessWidget {
  final List<Item> items;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) => ItemWidget(item: item)).toList(),
    );
  }
}

// ✅ صحيح: Keys للتعريف الفريد
class GoodKeyExample extends StatelessWidget {
  final List<Item> items;
  
  const GoodKeyExample({required this.items, super.key});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) => ItemWidget(
        key: ValueKey(item.id), // تعريف فريد
        item: item,
      )).toList(),
    );
  }
}

// للقوائم القابلة لإعادة الترتيب
class ReorderableListExample extends StatefulWidget {
  const ReorderableListExample({super.key});
  
  @override
  State<ReorderableListExample> createState() => _ReorderableListExampleState();
}

class _ReorderableListExampleState extends State<ReorderableListExample> {
  final List<Item> _items = [];
  
  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return ListTile(
          key: ValueKey(item.id), // مهم جداً للـ reordering
          title: Text(item.name),
          trailing: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
        );
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
        });
      },
    );
  }
}
```

---

## 10. تحسين Scrolling

```dart
class OptimizedScrollView extends StatefulWidget {
  const OptimizedScrollView({super.key});
  
  @override
  State<OptimizedScrollView> createState() => _OptimizedScrollViewState();
}

class _OptimizedScrollViewState extends State<OptimizedScrollView> {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = false;
  
  @override
  void initState() {
    super.initState();
    
    // استخدام listener بدلاً من NotificationListener
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    final showFab = _scrollController.offset > 200;
    if (showFab != _showFab) {
      setState(() => _showFab = showFab);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _scrollController,
          // تحسينات الأداء
          addAutomaticKeepAlives: false, // تعطيل للقوائم الطويلة
          addRepaintBoundaries: true, // عزل كل عنصر
          cacheExtent: 500, // زيادة منطقة التخزين المؤقت
          itemCount: 1000,
          itemBuilder: (context, index) {
            return ListTile(
              key: ValueKey(index),
              title: Text('Item $index'),
            );
          },
        ),
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
}
```

---

## 11. Web-Specific Optimizations

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

class WebOptimizedWidget extends StatelessWidget {
  const WebOptimizedWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? _buildWebVersion(context)
        : _buildMobileVersion(context);
  }
  
  Widget _buildWebVersion(BuildContext context) {
    return SelectionArea(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: _content(),
      ),
    );
  }
  
  Widget _buildMobileVersion(BuildContext context) {
    return GestureDetector(
      child: _content(),
    );
  }
  
  Widget _content() => const Text('Content');
}

// تحسين hover للويب
class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  
  const HoverCard({
    required this.child,
    required this.onTap,
    super.key,
  });
  
  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return GestureDetector(
        onTap: widget.onTap,
        child: widget.child,
      );
    }
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
```

---

## قائمة المراجعة

```
□ استخدام const constructors في كل مكان ممكن
□ تجزئة Widgets الكبيرة إلى widgets صغيرة
□ استخدام ListView.builder بدلاً من ListView
□ تحديد itemExtent للقوائم ذات الارتفاع الثابت
□ استخدام RepaintBoundary للمحتوى المعقد
□ استخدام child parameter في AnimatedBuilder
□ تجنب Opacity واستخدام Color.withOpacity
□ استخدام Keys صحيحة للقوائم الديناميكية
□ تحسين الصور مع cacheWidth/cacheHeight
□ اختبار الأداء مع DevTools
```

---

## الملفات ذات الصلة

- [02-bundle-optimization.md](02-bundle-optimization.md) - تحسين حجم الحزمة
- [08-tree-shaking.md](08-tree-shaking.md) - إزالة الكود غير المستخدم
- [12-state-management.md](12-state-management.md) - إدارة الحالة بكفاءة
- [13-measurement-tools.md](13-measurement-tools.md) - أدوات القياس
