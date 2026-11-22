/// نماذج البيانات المطابقة لردود api/v1.
library;

class Product {
  final int id;
  final String name;
  final String slug;
  final String description;
  final double price;
  final double? oldPrice;
  final int stock;
  final String image;
  final List<String> images;
  final String badge;
  final bool featured;
  final double rating;
  final String? category;
  final String? categoryName;
  final String? brand;
  final String? brandName;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    this.oldPrice,
    required this.stock,
    required this.image,
    required this.images,
    required this.badge,
    required this.featured,
    required this.rating,
    this.category,
    this.categoryName,
    this.brand,
    this.brandName,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: (j['id'] as num).toInt(),
        name: j['name'] ?? '',
        slug: j['slug'] ?? '',
        description: j['description'] ?? '',
        price: (j['price'] as num).toDouble(),
        oldPrice: j['old_price'] == null ? null : (j['old_price'] as num).toDouble(),
        stock: (j['stock'] as num).toInt(),
        image: j['image'] ?? '',
        images: (j['images'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        badge: j['badge'] ?? '',
        featured: j['featured'] == true,
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        category: j['category'],
        categoryName: j['category_name'],
        brand: j['brand'],
        brandName: j['brand_name'],
      );

  bool get onSale => oldPrice != null && oldPrice! > price;
  bool get outOfStock => stock <= 0;
  String get desc => description;
  String get brandLabel => brandName ?? brand ?? '';
}

class Category {
  final int id;
  final String name;
  final String slug;
  final String image;
  final int productsCount;
  Category({required this.id, required this.name, required this.slug, required this.image, required this.productsCount});
  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: (j['id'] as num).toInt(),
        name: j['name'] ?? '',
        slug: j['slug'] ?? '',
        image: j['image'] ?? '',
        productsCount: (j['products_count'] as num?)?.toInt() ?? 0,
      );
}

class Brand {
  final int id;
  final String name;
  final String slug;
  final String image;
  final int productsCount;
  Brand({required this.id, required this.name, required this.slug, required this.image, required this.productsCount});
  factory Brand.fromJson(Map<String, dynamic> j) => Brand(
        id: (j['id'] as num).toInt(),
        name: j['name'] ?? '',
        slug: j['slug'] ?? '',
        image: j['image'] ?? '',
        productsCount: (j['products_count'] as num?)?.toInt() ?? 0,
      );
}

class City {
  final String name;
  final double fee;
  City({required this.name, required this.fee});
  bool get active => true;
  factory City.fromJson(Map<String, dynamic> j) => City(name: j['name'] ?? '', fee: (j['fee'] as num).toDouble());
}

class HeroSlide {
  final String title;
  final String subtitle;
  final String ctaText;
  final String ctaLink;
  final String image;
  final String theme;
  HeroSlide({required this.title, required this.subtitle, required this.ctaText, required this.ctaLink, required this.image, required this.theme});
  String get link => ctaLink;
  factory HeroSlide.fromJson(Map<String, dynamic> j) => HeroSlide(
        title: j['title'] ?? '',
        subtitle: j['subtitle'] ?? '',
        ctaText: j['cta_text'] ?? '',
        ctaLink: j['cta_link'] ?? '',
        image: j['image'] ?? '',
        theme: j['theme'] ?? 'dark',
      );
}

class StoreSettings {
  final Map<String, String> values;
  final List<City> cities;
  final List<HeroSlide> slides;
  StoreSettings({required this.values, required this.cities, required this.slides});

  String get storeName => values['store_name'] ?? 'آي ستور';
  String get announcement => values['announcement'] ?? '';
  String get currency => values['currency'] ?? 'د.ل';
  String get whatsapp => values['whatsapp_number'] ?? '';
  double get freeShippingThreshold => double.tryParse(values['free_shipping_threshold'] ?? '0') ?? 0;
  String get deliveryPolicy => values['delivery_policy'] ?? '';
  String get returnsPolicy => values['returns_policy'] ?? '';
  String get aboutText => values['about_text'] ?? '';
  String get phone => values['phone'] ?? '';
  String get address => values['address'] ?? '';
  String get workingHours => values['working_hours'] ?? '';
}

class Customer {
  final int id;
  final String name;
  final String email;
  final String phone;
  Customer({required this.id, required this.name, required this.email, required this.phone});
  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: (j['id'] as num).toInt(),
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        phone: j['phone'] ?? '',
      );
}

class OrderSummary {
  final String code;
  final String status;
  final String statusLabel;
  final String city;
  final double total;
  final String createdAt;
  final List<Map<String, dynamic>> items;
  OrderSummary({required this.code, required this.status, required this.statusLabel, required this.city, required this.total, required this.createdAt, this.items = const []});
  factory OrderSummary.fromJson(Map<String, dynamic> j) => OrderSummary(
        code: j['code'] ?? '',
        status: j['status'] ?? '',
        statusLabel: j['status_label'] ?? j['status'] ?? '',
        city: j['city'] ?? '',
        total: (j['total'] as num).toDouble(),
        createdAt: j['created_at'] ?? '',
        items: (j['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [],
      );
  String get token => code;
  int get itemCount => items.fold(0, (s, i) => s + ((i['qty'] as num?)?.toInt() ?? 0));
}

class OrderLine {
  final String name;
  final int qty;
  final double price;
  OrderLine({required this.name, required this.qty, required this.price});
  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
        name: j['name'] ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 1,
        price: (j['price'] as num?)?.toDouble() ?? 0,
      );
}

class TrackedOrder {
  final String code;
  final String status;
  final String statusLabel;
  final String city;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String createdAt;
  final List<OrderLine> items;
  TrackedOrder({required this.code, required this.status, required this.statusLabel, required this.city, required this.subtotal, required this.discount, required this.deliveryFee, required this.total, required this.createdAt, required this.items});
  factory TrackedOrder.fromJson(Map<String, dynamic> j) => TrackedOrder(
        code: j['code'] ?? '',
        status: j['status'] ?? '',
        statusLabel: j['status_label'] ?? '',
        city: j['city'] ?? '',
        subtotal: (j['subtotal'] as num).toDouble(),
        discount: (j['discount'] as num).toDouble(),
        deliveryFee: (j['delivery_fee'] as num).toDouble(),
        total: (j['total'] as num).toDouble(),
        createdAt: j['created_at'] ?? '',
        items: (j['items'] as List?)?.map((e) => OrderLine.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
      );
  String get token => code;
}

class Review {
  final String customerName;
  final int rating;
  final String comment;
  final String createdAt;
  Review({required this.customerName, required this.rating, required this.comment, required this.createdAt});
  String get name => customerName;
  factory Review.fromJson(Map<String, dynamic> j) => Review(
        customerName: j['customer_name'] ?? '',
        rating: (j['rating'] as num).toInt(),
        comment: j['comment'] ?? '',
        createdAt: j['created_at'] ?? '',
      );
}
