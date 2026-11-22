import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponCtrl = TextEditingController();
  CouponResult? _coupon;
  String? _couponError;

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;
    try {
      final r = await api.applyCoupon(code, context.read<CartProvider>().subtotal);
      setState(() {
        _coupon = r;
        _couponError = null;
      });
    } on ApiException catch (e) {
      setState(() {
        _coupon = null;
        _couponError = e.message;
      });
    }
  }

  double _discount(double subtotal) {
    if (_coupon == null) return 0;
    if (_coupon!.type == 'percent') return subtotal * _coupon!.value / 100;
    return _coupon!.value;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final subtotal = cart.subtotal;
    final discount = _discount(subtotal);
    final threshold = settings?.freeShippingThreshold ?? 0;
    final freeShip = threshold > 0 && (subtotal - discount) >= threshold;
    final total = subtotal - discount;

    return Scaffold(
      appBar: AppBar(title: const Text('سلة التسوق')),
      body: cart.items.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              message: 'سلتك فارغة',
              actionLabel: 'تصفح المنتجات',
              onAction: () => context.go('/products'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...cart.items.asMap().entries.map((e) => _cartTile(e.key, e.value, cart)),
                const SizedBox(height: 16),
                // كوبون
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('كوبون الخصم', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponCtrl,
                              decoration: const InputDecoration(hintText: 'أدخل الكود', isDense: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GlowButton(label: 'تطبيق', onPressed: _applyCoupon),
                        ],
                      ),
                      if (_couponError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_couponError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                        ),
                      if (_coupon != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('تم تطبيق الكوبون: ${_coupon!.code}',
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // الملخص
                GlassCard(
                  child: Column(
                    children: [
                      _row('المجموع الفرعي', fmtPrice(subtotal)),
                      if (discount > 0) _row('الخصم', '- ${fmtPrice(discount)}', color: Colors.greenAccent),
                      _row('الشحن', freeShip ? 'مجاني' : 'حسب المدينة', color: freeShip ? Colors.greenAccent : null),
                      const Divider(height: 24, color: AppTheme.border),
                      _row('الإجمالي', fmtPrice(total), bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlowButton(
                  label: 'إتمام الطلب',
                  icon: Icons.arrow_back,
                  onPressed: () => context.push('/checkout', extra: {'coupon': _coupon?.code}),
                ),
              ],
            ),
    );
  }

  Widget _cartTile(int i, CartItem item, CartProvider cart) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(14), child: ProductImage(url: item.product.image, width: 72, height: 72)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.4)),
                  if (item.variantLabel.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(item.variantLabel, style: const TextStyle(color: AppTheme.textFaint, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  const SizedBox(height: 6),
                  Text(fmtPrice(item.price * item.qty), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    _miniBtn(Icons.remove, () => cart.setQty(i, item.qty - 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                    _miniBtn(Icons.add, () => cart.setQty(i, item.qty + 1)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => cart.removeAt(i),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.border)),
          child: Icon(icon, size: 15),
        ),
      );

  Widget _row(String label, String value, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: color ?? AppTheme.textDim, fontSize: bold ? 16 : 14)),
            ),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color ?? Colors.white, fontSize: bold ? 18 : 14)),
          ],
        ),
      );
}
