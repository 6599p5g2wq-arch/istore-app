import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    setState(() {
      _busy = true;
      _error = null;
    });
    String? err;
    if (_isLogin) {
      err = await auth.login(_email.text.trim(), _password.text);
    } else {
      err = await auth.register(_name.text.trim(), _email.text.trim(), _phone.text.trim(), _password.text);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isLogin ? 'مرحباً بعودتك' : 'تم إنشاء حسابك')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(auth.loggedIn ? 'حسابي' : 'تسجيل الدخول')),
      body: auth.loggedIn ? _profile(auth) : _authForm(),
    );
  }

  Widget _authForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_isLogin ? 'أهلاً بعودتك' : 'إنشاء حساب جديد',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل الاسم' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'أدخل بريداً صحيحاً' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'كلمة المرور'),
                  validator: (v) => (v == null || v.length < 6) ? '6 أحرف على الأقل' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 20),
                GlowButton(label: _isLogin ? 'دخول' : 'إنشاء الحساب', loading: _busy, onPressed: _submit),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setState(() {
                    _isLogin = !_isLogin;
                    _error = null;
                  }),
                  child: Text(
                    _isLogin ? 'ليس لديك حساب؟ سجل الآن' : 'لديك حساب؟ سجل الدخول',
                    style: const TextStyle(color: AppTheme.accent2, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _profile(AuthProvider auth) {
    final c = auth.customer!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
                child: Center(
                  child: Text(c.name.isNotEmpty ? c.name[0] : '؟',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text(c.email, style: const TextStyle(color: AppTheme.textDim, fontSize: 13)),
                    if (c.phone.isNotEmpty) Text(c.phone, style: const TextStyle(color: AppTheme.textFaint, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _tile(Icons.receipt_long, 'طلباتي', () => context.push('/track')),
        _tile(Icons.favorite_border, 'المفضلة', () => context.push('/wishlist')),
        _tile(Icons.lock_outline, 'تغيير كلمة المرور', () => _changePassword()),
        _tile(Icons.logout, 'تسجيل الخروج', () async {
          await context.read<AuthProvider>().logout();
        }, danger: true),
      ],
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: danger ? Colors.redAccent : AppTheme.accent2, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontWeight: FontWeight.w800, color: danger ? Colors.redAccent : Colors.white)),
            ),
            const Icon(Icons.chevron_left, color: AppTheme.textFaint),
          ],
        ),
      ),
    );
  }

  void _changePassword() {
    final current = TextEditingController();
    final next = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: 'الحالية')),
            const SizedBox(height: 10),
            TextField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'الجديدة')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await api.changePassword(current.text, next.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور')));
                }
              } on ApiException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
