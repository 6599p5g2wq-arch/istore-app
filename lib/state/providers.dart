import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/models.dart';

/// عنصر سلة محلي
class CartItem {
  final Product product;
  int qty;
  CartItem({required this.product, required this.qty});

  Map<String, dynamic> toJson() => {
        'id': product.id,
        'qty': qty,
        'name': product.name,
        'slug': product.slug,
        'price': product.price,
        'image': product.image,
        'stock': product.stock,
      };
}

class AuthProvider extends ChangeNotifier {
  final ApiClient api;
  Customer? customer;
  bool loading = true;

  AuthProvider({ApiClient? client}) : api = client ?? sharedApi;

  bool get loggedIn => customer != null && api.token != null;

  Future<void> init() async {
    await api.init();
    if (api.token != null) {
      try {
        customer = await api.fetchAccount();
      } catch (_) {
        // توكن منتهي — يبقى زائراً
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    try {
      customer = await api.login(email, password);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> register(String name, String email, String phone, String password) async {
    try {
      customer = await api.register(name, email, phone, password);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    await api.logout();
    customer = null;
    notifyListeners();
  }
}

class CartProvider extends ChangeNotifier {
  final ApiClient api;
  final List<CartItem> items = [];

  CartProvider({ApiClient? client}) : api = client ?? sharedApi;

  double get total => items.fold(0, (s, i) => s + i.product.price * i.qty);
  double get subtotal => total;

  Future<void> setQtyAt(int index, int qty) async {
    if (index < 0 || index >= items.length) return;
    await setQty(items[index].product.id, qty);
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= items.length) return;
    await setQty(items[index].product.id, 0);
  }

  Future<void> clearLocal() async {
    items.clear();
    await _save();
    notifyListeners();
  }
  int get count => items.fold(0, (s, i) => s + i.qty);
  bool get isEmpty => items.isEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cart') ?? '[]';
    try {
      for (final j in jsonDecode(raw) as List) {
        items.add(CartItem(
          product: Product(
            id: j['id'], name: j['name'], slug: j['slug'], description: '',
            price: (j['price'] as num).toDouble(), stock: j['stock'] ?? 99,
            image: j['image'] ?? '', images: const [], badge: '', featured: false, rating: 0,
          ),
          qty: j['qty'] ?? 1,
        ));
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart', jsonEncode(items.map((i) => i.toJson()).toList()));
    notifyListeners();
  }

  Future<void> add(Product p, {int qty = 1}) async {
    final i = items.indexWhere((e) => e.product.id == p.id);
    if (i >= 0) {
      items[i].qty = (items[i].qty + qty).clamp(1, p.stock > 0 ? p.stock : 99);
    } else {
      items.add(CartItem(product: p, qty: qty));
    }
    await _save();
    if (api.token != null) {
      try {
        await api.cartSetQty(p.id, qty, add: true);
      } catch (_) {}
    }
  }

  Future<void> setQty(int productId, int qty) async {
    final i = items.indexWhere((e) => e.product.id == productId);
    if (i < 0) return;
    if (qty <= 0) {
      items.removeAt(i);
    } else {
      items[i].qty = qty.clamp(1, items[i].product.stock > 0 ? items[i].product.stock : 99);
    }
    await _save();
    if (api.token != null) {
      try {
        qty <= 0 ? await api.cartRemove(productId) : await api.cartSetQty(productId, qty);
      } catch (_) {}
    }
  }

  Future<void> clear() async {
    items.clear();
    await _save();
    if (api.token != null) {
      try {
        await api.cartClear();
      } catch (_) {}
    }
  }

  /// دمج سلة الخادم بعد تسجيل الدخول (الخادم يكسب عند التعارض)
  Future<void> syncFromServer() async {
    if (api.token == null) return;
    try {
      final remote = await api.fetchServerCart();
      for (final r in remote) {
        final i = items.indexWhere((e) => e.product.id == (r['id'] as num).toInt());
        if (i >= 0) {
          items[i].qty = (r['qty'] as num).toInt();
        } else {
          items.add(CartItem(product: Product.fromJson(r), qty: (r['qty'] as num).toInt()));
        }
      }
      await _save();
    } catch (_) {}
  }
}

class WishlistProvider extends ChangeNotifier {
  final ApiClient api;
  final List<Product> items = [];

  WishlistProvider({ApiClient? client}) : api = client ?? sharedApi;

  bool has(int id) => items.any((p) => p.id == id);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      for (final j in jsonDecode(prefs.getString('wishlist') ?? '[]') as List) {
        items.add(Product.fromJson(j));
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'wishlist',
        jsonEncode(items
            .map((p) => {'id': p.id, 'name': p.name, 'slug': p.slug, 'price': p.price, 'image': p.image, 'stock': p.stock, 'old_price': p.oldPrice, 'rating': p.rating, 'badge': p.badge})
            .toList()));
    notifyListeners();
  }

  Future<void> toggle(Product p) async {
    final i = items.indexWhere((e) => e.id == p.id);
    final added = i < 0;
    added ? items.insert(0, p) : items.removeAt(i);
    await _save();
    if (api.token != null) {
      try {
        added ? await api.wishlistAdd(p.id) : await api.wishlistRemove(p.id);
      } catch (_) {}
    }
  }
}

class SettingsProvider extends ChangeNotifier {
  final ApiClient api;
  StoreSettings? settings;
  String? error;

  SettingsProvider({ApiClient? client}) : api = client ?? sharedApi;

  Future<void> load({bool force = false}) async {
    if (settings != null && !force) return;
    try {
      settings = await api.fetchSettings();
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    }
    notifyListeners();
  }
}
