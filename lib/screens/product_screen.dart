import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ProductScreen extends StatefulWidget {
  final String slug;
  const ProductScreen({super.key, required this.slug});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Product? _p;
  String? _error;
  int _imageIndex = 0;
  int _qty = 1;
  final Map<String, String> _selected = {};
  List<Review> _reviews = [];

  ProductVariant? _findVariant(Product p) {
    if (p.options.isEmpty) return null;
    if (_selected.length < p.options.length) return null;
    for (final v in p.variants) {
      var ok = true;
      for (final o in p.options) {
        if (v.options[o.name] != _selected[o.name]) { ok = false; break; }
      }
      if (ok) return v;
    }
    return null;
  }

  bool _comboAvailable(Product p, String optName, String value) {
    final probe = Map<String, String>.from(_selected)..[optName] = value;
    return p.variants.any((v) {
      for (final o in p.options) {
        final sel = probe[o.name];
        if (sel != null && v.options[o.name] != sel) return false;
      }
      return v.stock > 0;
    });
  }

  double _displayPrice(Product p) => _findVariant(p)?.price ?? p.price;
  int _displayStock(Product p) {
    final v = _findVariant(p);
    return v?.stock ?? p.stock;
  }
  final _page = PageController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final p = await api.getProduct(widget.slug);
      final rev = await api.getReviews(p.id).catchError((_) => <Review>[]);
      if (!mounted) return;
      setState(() {
        _p = p;
        _reviews = rev;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Scaffold(
      appBar: AppBar(
        title: Text(p?.name ?? 'المنتج'),
        actions: [
          if (p != null)
            Consumer<WishlistProvider>(
              builder: (_, wish, __) => IconButton(
                icon: Icon(wish.has(p.id) ? Icons.favorite : Icons.favorite_border,
                    color: wish.has(p.id) ? Colors.redAccent : null),
                onPressed: () => wish.toggle(p),
              ),
            ),
        ],
      ),
      body: _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : p == null
              ? const Center(child: CircularProgressIndicator())
              : _body(p),
      bottomNavigationBar: p == null ? null : _bottomBar(p),
    );
  }

  Widget _body(Product p) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // الصور
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: _page,
            onPageChanged: (i) => setState(() => _imageIndex = i),
            itemCount: p.images.isEmpty ? 1 : p.images.length,
            itemBuilder: (_, i) => ProductImage(url: p.images.isEmpty ? '' : p.images[i], fit: BoxFit.contain),
          ),
        ),
        if (p.images.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              p.images.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _imageIndex ? AppTheme.accent2 : const Color(0x33FFFFFF),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (p.badge.isNotEmpty)
                    Container(
                      margin: const EdgeInsetsDirectional.only(end: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(99)),
                      child: Text(p.badge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  if (p.brandLabel.isNotEmpty)
                    Text(p.brandLabel, style: const TextStyle(color: AppTheme.textFaint, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.4)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(fmtPrice(_displayPrice(p)), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.accent2)),
                  if (p.onSale) ...[
                    const SizedBox(width: 10),
                    Text(fmtPrice(p.oldPrice!),
                        style: const TextStyle(color: AppTheme.textFaint, decoration: TextDecoration.lineThrough, fontSize: 15)),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(_displayStock(p) <= 0 ? Icons.cancel_outlined : Icons.check_circle_outline,
                      size: 18, color: _displayStock(p) <= 0 ? Colors.redAccent : Colors.greenAccent),
                  const SizedBox(width: 6),
                  Text(_findVariant(p) != null && _displayStock(p) <= 0
                      ? 'هذه التوليفة نفدت'
                      : (_displayStock(p) <= 0 ? 'نفد من المخزون' : 'متوفر في المخزون'),
                      style: TextStyle(fontWeight: FontWeight.w700, color: _displayStock(p) <= 0 ? Colors.redAccent : Colors.greenAccent)),
                ],
              ),
              const SizedBox(height: 8),
              if (p.hasVariants) _variantPicker(p),
              // الكمية
              Row(
                children: [
                  const Text('الكمية', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 16),
                  _qtyBtn(Icons.remove, () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('$_qty', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  ),
                  _qtyBtn(Icons.add, () => setState(() => _qty++)),
                ],
              ),
              if (p.desc.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('الوصف', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 8),
                Text(p.desc, style: const TextStyle(color: AppTheme.textDim, height: 1.8, fontSize: 14)),
              ],
              const SizedBox(height: 24),
              Text('التقييمات (${_reviews.length})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 10),
              if (_reviews.isEmpty)
                const Text('لا توجد تقييمات بعد', style: TextStyle(color: AppTheme.textFaint))
              else
                ..._reviews.take(5).map((r) => GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                              ...List.generate(
                                  5,
                                  (i) => Icon(i < r.rating ? Icons.star : Icons.star_border,
                                      size: 16, color: Colors.amber)),
                            ],
                          ),
                          if (r.comment.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(r.comment, style: const TextStyle(color: AppTheme.textDim, fontSize: 13, height: 1.6)),
                          ],
                        ],
                      ),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _variantPicker(Product p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final o in p.options) ...[
          const SizedBox(height: 10),
          Text(o.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in o.values)
                Builder(builder: (_) {
                  final active = _selected[o.name] == v;
                  final avail = _comboAvailable(p, o.name, v);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (active) {
                        _selected.remove(o.name);
                      } else {
                        _selected[o.name] = v;
                      }
                      _qty = 1;
                      final pv = _findVariant(p);
                      if (pv?.image != null && pv!.image!.isNotEmpty) {
                        final idx = p.images.indexOf(pv.image!);
                        if (idx >= 0) _page.jumpToPage(idx);
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.accent2 : AppTheme.card,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: active ? AppTheme.accent2 : AppTheme.border),
                      ),
                      child: Text(
                        v,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: !avail && !active ? AppTheme.textFaint : (active ? Colors.black : AppTheme.text),
                          decoration: !avail && !active ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ],
        if (_selected.length < p.options.length)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('اختر ${p.options.map((o) => o.name).join(' و')} أولاً',
                style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(icon, size: 18),
        ),
      );

  Widget _bottomBar(Product p) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Row(
          children: [
            if (_displayStock(p) <= 0 && !p.hasVariants)
              Expanded(
                child: GlowButton(
                  label: 'أعلمني عند التوفر',
                  icon: Icons.notifications_none,
                  onPressed: () => _notifyMe(p),
                ),
              )
            else
              Expanded(
                child: Builder(builder: (_) {
                  final v = _findVariant(p);
                  final needsSelection = p.hasVariants && v == null;
                  final canAdd = !needsSelection && (v?.stock ?? p.stock) > 0;
                  return GlowButton(
                    label: needsSelection
                        ? 'اختر المواصفات أولاً'
                        : (canAdd ? 'أضف إلى السلة • ${fmtPrice(_displayPrice(p) * _qty)}' : 'نفدت الكمية'),
                    icon: Icons.shopping_bag_outlined,
                    onPressed: canAdd
                        ? () {
                            context.read<CartProvider>().add(
                                  p,
                                  qty: _qty,
                                  variantId: v?.id ?? 0,
                                  variantLabel: v?.label ?? '',
                                  priceOverride: v?.price,
                                  stockOverride: v?.stock,
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('أُضيف إلى السلة'),
                                action: SnackBarAction(label: 'عرض السلة', textColor: AppTheme.accent2, onPressed: () => context.go('/cart')),
                              ),
                            );
                          }
                        : null,
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }

  void _notifyMe(Product p) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('أعلمني عند التوفر'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'بريدك الإلكتروني'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              final email = ctrl.text.trim();
              Navigator.pop(ctx);
              try {
                await api.stockAlert(p.id, email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سنُعلمك فور توفر المنتج')));
                }
              } on ApiException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }
}
