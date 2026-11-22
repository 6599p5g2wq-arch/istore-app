import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config.dart';
import 'models.dart';

/// عميل API الموحد: يضيف توكن Bearer تلقائياً ويحوّل الأخطاء لرسائل عربية.
class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _token;

  ApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBase,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
        ));

  Future<void> init() async {
    _token = await _storage.read(key: 'token');
  }

  String? get token => _token;

  Future<void> _setToken(String? token) async {
    _token = token;
    if (token == null) {
      await _storage.delete(key: 'token');
    } else {
      await _storage.write(key: 'token', value: token);
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await _dio.request(
        path,
        queryParameters: query,
        data: body,
        options: Options(
          method: method,
          headers: {if (_token != null) 'Authorization': 'Bearer $_token'},
        ),
      );
      final data = res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : <String, dynamic>{};
      if (data['ok'] != true) throw ApiException(data['error']?.toString() ?? 'حدث خطأ', res.statusCode);
      return data;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) throw ApiException(data['error'].toString(), e.response?.statusCode);
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        throw ApiException('تعذر الاتصال بالخادم — تحقق من الإنترنت ورابط المتجر');
      }
      throw ApiException('حدث خطأ في الاتصال', e.response?.statusCode);
    }
  }

  // ---------- عامة ----------

  Future<StoreSettings> fetchSettings() async {
    final d = await _request('GET', '/settings.php');
    final rawSettings = (d['settings'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
    return StoreSettings(
      values: rawSettings,
      cities: (d['cities'] as List).map((e) => City.fromJson(e)).toList(),
      slides: (d['hero_slides'] as List).map((e) => HeroSlide.fromJson(e)).toList(),
    );
  }

  Future<({List<Product> products, int total, int pages})> fetchProducts({
    String? q,
    String? category,
    String? brand,
    bool featured = false,
    bool offers = false,
    String? sort,
    int page = 1,
    int perPage = 20,
  }) async {
    final d = await _request('GET', '/products.php', query: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (category != null) 'category': category,
      if (brand != null) 'brand': brand,
      if (featured) 'featured': '1',
      if (offers) 'offers': '1',
      if (sort != null) 'sort': sort,
      'page': '$page',
      'per_page': '$perPage',
    });
    final p = d['pagination'] as Map<String, dynamic>;
    return (
      products: (d['products'] as List).map((e) => Product.fromJson(e)).toList(),
      total: (p['total'] as num).toInt(),
      pages: (p['pages'] as num).toInt(),
    );
  }

  Future<({Product product, List<Review> reviews})> fetchProduct(String slug) async {
    final d = await _request('GET', '/products.php', query: {'slug': slug});
    return (
      product: Product.fromJson(d['product']),
      reviews: (d['reviews'] as List).map((e) => Review.fromJson(e)).toList(),
    );
  }

  Future<List<Category>> fetchCategories() async =>
      (await _request('GET', '/categories.php'))['categories'].map<Category>((e) => Category.fromJson(e)).toList();

  Future<List<Brand>> fetchBrands() async =>
      (await _request('GET', '/brands.php'))['brands'].map<Brand>((e) => Brand.fromJson(e)).toList();

  Future<double> validateCoupon(String code, double subtotal) async =>
      ((await _request('POST', '/coupons.php', body: {'code': code, 'subtotal': subtotal}))['discount'] as num).toDouble();

  // ---------- المصادقة ----------

  Future<Customer> login(String email, String password) async {
    final d = await _request('POST', '/auth.php', query: {'action': 'login'}, body: {'email': email, 'password': password});
    await _setToken(d['token'] as String);
    return Customer.fromJson(d['customer']);
  }

  Future<Customer> register(String name, String email, String phone, String password) async {
    final d = await _request('POST', '/auth.php', query: {'action': 'register'}, body: {'name': name, 'email': email, 'phone': phone, 'password': password});
    await _setToken(d['token'] as String);
    return Customer.fromJson(d['customer']);
  }

  Future<void> logout() async {
    try {
      await _request('POST', '/auth.php', query: {'action': 'logout'});
    } catch (_) {}
    await _setToken(null);
  }

  Future<Customer> fetchAccount() async => Customer.fromJson((await _request('GET', '/account.php'))['customer']);

  Future<Customer> updateAccount({String? name, String? phone}) async =>
      Customer.fromJson((await _request('PUT', '/account.php', body: {if (name != null) 'name': name, if (phone != null) 'phone': phone}))['customer']);

  Future<void> changePassword(String current, String next) async =>
      _request('PUT', '/account.php', body: {'current_password': current, 'new_password': next});

  // ---------- سلة ومفضلة الخادم ----------

  Future<List<Map<String, dynamic>>> fetchServerCart() async =>
      ((await _request('GET', '/cart.php'))['items'] as List).cast<Map<String, dynamic>>();

  Future<void> cartSetQty(int productId, int qty, {bool add = false, int variantId = 0}) async =>
      _request(add ? 'POST' : 'PUT', '/cart.php', body: {'product_id': productId, 'qty': qty, 'variant_id': variantId});

  Future<void> cartRemove(int productId, {int variantId = 0}) async =>
      _request('DELETE', '/cart.php', query: {'product_id': '$productId', 'variant_id': '$variantId'});

  Future<void> cartClear() => _request('DELETE', '/cart.php');

  Future<List<Product>> fetchWishlist() async =>
      ((await _request('GET', '/wishlist.php'))['items'] as List).map((e) => Product.fromJson(e)).toList();

  Future<void> wishlistAdd(int productId) => _request('POST', '/wishlist.php', body: {'product_id': productId});

  Future<void> wishlistRemove(int productId) => _request('DELETE', '/wishlist.php', query: {'product_id': '$productId'});

  // ---------- الطلبات ----------

  Future<({String code, double total})> createOrder({
    required String name,
    required String phone,
    required String city,
    String address = '',
    String notes = '',
    String coupon = '',
    required List<({int id, int qty, int variantId})> items,
  }) async {
    final d = await _request('POST', '/orders.php', body: {
      'name': name,
      'phone': phone,
      'city': city,
      'address': address,
      'notes': notes,
      'coupon': coupon,
      'items': items.map((i) => {'id': i.id, 'qty': i.qty, 'variant_id': i.variantId}).toList(),
    });
    return (code: d['code'] as String, total: (d['total'] as num).toDouble());
  }

  Future<List<OrderSummary>> fetchMyOrders() async =>
      ((await _request('GET', '/orders.php'))['orders'] as List).map((e) => OrderSummary.fromJson(e)).toList();

  Future<TrackedOrder> trackOrder(String code, String phone) async =>
      TrackedOrder.fromJson((await _request('GET', '/orders.php', query: {'code': code, 'phone': phone}))['order']);

  // ---------- متفرقات ----------

  Future<void> addStockAlert(int productId, String contact) =>
      _request('POST', '/stock-alerts.php', body: {'product_id': productId, 'contact': contact});

  Future<void> addReview({required int productId, required String name, required int rating, String comment = '', required String phone, required String orderCode}) =>
      _request('POST', '/reviews.php', body: {
        'product_id': productId,
        'name': name,
        'rating': rating,
        'comment': comment,
        'phone': phone,
        'order_code': orderCode,
      });
}


/// عميل مشترك لكل التطبيق
final ApiClient sharedApi = ApiClient();
final ApiClient api = sharedApi;

class PagedProducts {
  final List<Product> items;
  final bool hasMore;
  PagedProducts(this.items, this.hasMore);
}

class CouponResult {
  final String code;
  final String type; // percent | fixed
  final double value;
  final double discount;
  CouponResult(this.code, this.type, this.value, this.discount);
}

/// واجهة مبسطة تستخدمها الشاشات
extension AppApi on ApiClient {
  Future<PagedProducts> getProducts({int page = 1, int perPage = 12, String? category, String sort = 'newest', String? q}) async {
    final r = await fetchProducts(page: page, perPage: perPage, category: category, sort: sort, q: q);
    return PagedProducts(r.products, page < r.pages);
  }

  Future<List<Category>> getCategories() => fetchCategories();

  Future<List<HeroSlide>> getHero() async => (await fetchSettings()).slides;

  Future<List<City>> getCities() async => (await fetchSettings()).cities;

  Future<Product> getProduct(String slug) async => (await fetchProduct(slug)).product;

  Future<List<Review>> getReviews(int productId) async {
    final d = await _request('GET', '/reviews.php', query: {'product_id': '$productId'});
    return (d['reviews'] as List).map((e) => Review.fromJson(e)).toList();
  }

  Future<CouponResult> applyCoupon(String code, double subtotal) async {
    final d = await _request('POST', '/coupons.php', body: {'code': code, 'subtotal': subtotal});
    return CouponResult(code, d['kind']?.toString() ?? 'fixed', (d['value'] as num).toDouble(), (d['discount'] as num).toDouble());
  }

  Future<void> stockAlert(int productId, String contact) => addStockAlert(productId, contact);

  Future<List<OrderSummary>> myOrders() => fetchMyOrders();

  Future<Map<String, dynamic>> submitOrder(Map<String, dynamic> body) => _request('POST', '/orders.php', body: body);
}
