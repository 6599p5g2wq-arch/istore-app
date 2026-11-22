import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _newest = [];
  List<Category> _cats = [];
  List<HeroSlide> _slides = [];
  String? _error;
  final _page = PageController(viewportFraction: 0.92);
  int _slideIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final newest = await api.getProducts(sort: 'newest', perPage: 8);
      final cats = await api.getCategories();
      final slides = await api.getHero();
      if (!mounted) return;
      setState(() {
        _newest = newest.items;
        _cats = cats.where((c) => c.showInMenu).toList();
        _slides = slides;
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
    final settings = context.watch<SettingsProvider>().settings;
    return Scaffold(
      appBar: AppBar(
        title: Text(settings?.storeName ?? 'آي ستور'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => context.go('/products')),
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () => context.push('/wishlist')),
        ],
      ),
      body: _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.accent2,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (_slides.isNotEmpty) _heroSlider(),
                  const SizedBox(height: 20),
                  if (_cats.isNotEmpty) ...[
                    _sectionTitle('تسوق حسب الفئة'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cats.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final c = _cats[i];
                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => context.go('/products?category=${c.slug}'),
                            child: Container(
                              width: 110,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(14), child: ProductImage(url: c.image))),
                                  const SizedBox(height: 6),
                                  Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _sectionTitle('أحدث المنتجات', action: () => context.go('/products')),
                  const SizedBox(height: 12),
                  if (_newest.isEmpty)
                    const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: _newest.length,
                      itemBuilder: (_, i) =>
                          ProductCard(product: _newest[i], onTap: () => context.push('/product/${_newest[i].slug}')),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t, {VoidCallback? action}) => Row(
        children: [
          Expanded(child: Text(t, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
          if (action != null)
            TextButton(onPressed: action, child: const Text('عرض الكل', style: TextStyle(color: AppTheme.accent2, fontWeight: FontWeight.w700))),
        ],
      );

  Widget _heroSlider() {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _page,
            onPageChanged: (i) => setState(() => _slideIndex = i),
            itemCount: _slides.length,
            itemBuilder: (_, i) {
              final s = _slides[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  onTap: () {
                    if (s.link.startsWith('/product')) context.push(s.link);
                    if (s.link.startsWith('/?') || s.link == '/') context.go('/products');
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProductImage(url: s.image),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppTheme.bg.withValues(alpha: 0.85)],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 18,
                        left: 18,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            if (s.subtitle.isNotEmpty)
                              Text(s.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppTheme.textDim, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _slides.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _slideIndex ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                gradient: i == _slideIndex ? AppTheme.primaryGradient : null,
                color: i == _slideIndex ? null : const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
