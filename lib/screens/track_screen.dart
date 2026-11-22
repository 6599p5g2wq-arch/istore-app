import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _statusSteps = ['pending', 'confirmed', 'processing', 'shipped', 'delivered'];
const _statusAr = {
  'pending': 'قيد المراجعة',
  'confirmed': 'تم التأكيد',
  'processing': 'قيد التجهيز',
  'shipped': 'تم الشحن',
  'delivered': 'تم التوصيل',
  'cancelled': 'ملغي',
};

class TrackScreen extends StatefulWidget {
  final String? token;
  const TrackScreen({super.key, this.token});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final _tokenCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  TrackedOrder? _order;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tokenCtrl.text = widget.token ?? '';
    if (widget.token != null) _track();
  }

  Future<void> _track() async {
    setState(() {
      _loading = true;
      _error = null;
      _order = null;
    });
    try {
      final o = await api.trackOrder(_tokenCtrl.text.trim(), _phoneCtrl.text.trim());
      if (mounted) setState(() => _order = o);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تتبع الطلب')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _tokenCtrl,
                  decoration: const InputDecoration(labelText: 'رمز التتبع', hintText: 'IST-XXXXXXXX'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف المستخدم في الطلب'),
                ),
                const SizedBox(height: 16),
                GlowButton(label: 'تتبع', loading: _loading, onPressed: _track),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
          if (_order != null) ...[
            const SizedBox(height: 20),
            _orderCard(_order!),
          ],
          const SizedBox(height: 24),
          _myOrders(),
        ],
      ),
    );
  }

  Widget _orderCard(TrackedOrder o) {
    final stepIdx = _statusSteps.indexOf(o.status);
    final cancelled = o.status == 'cancelled';
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('طلب ${o.token}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: cancelled ? Colors.redAccent.withValues(alpha: 0.15) : AppTheme.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(_statusAr[o.status] ?? o.status,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: cancelled ? Colors.redAccent : AppTheme.accent2)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!cancelled)
            Row(
              children: List.generate(_statusSteps.length, (i) {
                final done = i <= stepIdx;
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          gradient: done ? AppTheme.primaryGradient : null,
                          color: done ? null : const Color(0x1FFFFFFF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_statusAr[_statusSteps[i]]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10, fontWeight: done ? FontWeight.w800 : FontWeight.w600, color: done ? Colors.white : AppTheme.textFaint)),
                    ],
                  ),
                );
              }),
            ),
          const SizedBox(height: 14),
          ...o.items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(it.variantLabel.isNotEmpty ? '${it.name} · ${it.variantLabel} × ${it.qty}' : '${it.name} × ${it.qty}', style: const TextStyle(fontSize: 13, color: AppTheme.textDim))),
                    Text(fmtPrice(it.price * it.qty), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              )),
          const Divider(height: 22, color: AppTheme.border),
          Row(
            children: [
              const Expanded(child: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.w900))),
              Text(fmtPrice(o.total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.accent2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _myOrders() {
    final auth = context.watch<AuthProvider>();
    if (!auth.loggedIn) return const SizedBox.shrink();
    return FutureBuilder<List<OrderSummary>>(
      future: api.myOrders(),
      builder: (_, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('طلباتي السابقة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 10),
            ...snap.data!.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    onTap: () {
                      _tokenCtrl.text = o.token;
                      _track();
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.token, style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text('${o.itemCount} منتج • ${o.createdAt}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textFaint)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(fmtPrice(o.total), style: const TextStyle(fontWeight: FontWeight.w900)),
                            Text(_statusAr[o.status] ?? o.status,
                                style: const TextStyle(fontSize: 12, color: AppTheme.accent2, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }
}
