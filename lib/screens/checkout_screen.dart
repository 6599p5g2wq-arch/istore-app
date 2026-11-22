import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

class CheckoutScreen extends StatefulWidget {
  final String? coupon;
  const CheckoutScreen({super.key, this.coupon});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  List<City> _cities = [];
  String? _city;
  bool _placing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCities();
    final c = context.read<AuthProvider>().customer;
    if (c != null) {
      _name.text = c.name;
      _phone.text = c.phone;
    }
  }

  Future<void> _loadCities() async {
    try {
      final cities = await api.getCities();
      if (mounted) {
        setState(() {
          _cities = cities.where((c) => c.active).toList();
          _city = _cities.isNotEmpty ? _cities.first.name : null;
        });
      }
    } catch (_) {}
  }

  Future<void> _placeOrder() async {
    if (!_form.currentState!.validate()) return;
    if (_city == null) return;
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) return;
    setState(() {
      _placing = true;
      _error = null;
    });
    try {
      final res = await api.submitOrder({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'city': _city,
        'address': _address.text.trim(),
        'notes': _notes.text.trim(),
        if (widget.coupon != null) 'coupon': widget.coupon,
        'items': [
          for (final it in cart.items)
            {
              'id': it.product.id,
              'qty': it.qty,
              'variant_id': it.variantId,
            }
        ],
      });
      if (!mounted) return;
      cart.clearLocal();
      context.go('/order-success', extra: res);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _placing = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    return Scaffold(
      appBar: AppBar(title: const Text('إتمام الطلب')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('بيانات التوصيل', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل الاسم' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'رقم الهاتف', hintText: '09XXXXXXXX'),
                    validator: (v) => (v == null || v.trim().length < 9) ? 'أدخل رقم هاتف صحيح' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _city,
                    decoration: const InputDecoration(labelText: 'المدينة'),
                    items: _cities.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                    onChanged: (v) => setState(() => _city = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(labelText: 'العنوان بالتفصيل'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل العنوان' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, color: AppTheme.accent2),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الدفع عند الاستلام', style: TextStyle(fontWeight: FontWeight.w800)),
                        Text(
                          ((settings?.freeShippingThreshold ?? 0) > 0 && cart.subtotal >= settings!.freeShippingThreshold)
                              ? 'شحن مجاني لطلبك'
                              : 'شحن مجاني للطلبات فوق ${fmtPrice(settings?.freeShippingThreshold ?? 500)}',
                          style: const TextStyle(color: AppTheme.textFaint, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 20),
            GlowButton(
              label: 'تأكيد الطلب • ${fmtPrice(cart.subtotal)}',
              loading: _placing,
              onPressed: cart.items.isEmpty ? null : _placeOrder,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class OrderSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final token = order['token']?.toString() ?? '';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 46),
                ),
                const SizedBox(height: 22),
                const Text('شكراً لك!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('تم استلام طلبك بنجاح وسنتواصل معك قريباً',
                    textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textDim, fontWeight: FontWeight.w600)),
                const SizedBox(height: 18),
                GlassCard(
                  child: Column(
                    children: [
                      const Text('رمز تتبع الطلب', style: TextStyle(color: AppTheme.textFaint, fontSize: 13)),
                      const SizedBox(height: 6),
                      SelectableText(token,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppTheme.accent2)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GlowButton(label: 'تتبع الطلب', onPressed: () => context.push('/track?token=$token')),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('العودة للرئيسية', style: TextStyle(color: AppTheme.textDim, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
