import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../widgets/common.dart';

class ProductsScreen extends StatefulWidget {
  final String? category;
  const ProductsScreen({super.key, this.category});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _searchFocus = FocusNode();
  List<Product> _items = [];
  List<Category> _cats = [];
  bool _loading = false;
  bool _done = false;
  String? _error;
  int _page = 1;
  String? _category;
  String _sort = 'newest';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _loadCats();
    _refresh();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _loadMore();
    });
  }

  Future<void> _loadCats() async {
    try {
      final cats = await api.getCategories();
      if (mounted) setState(() => _cats = cats.where((c) => c.showInMenu).toList());
    } catch (_) {}
  }

  Future<void> _refresh() async {
    setState(() {
      _items = [];
      _page = 1;
      _done = false;
      _error = null;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || _done) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await api.getProducts(page: _page, perPage: 12, category: _category, sort: _sort, q: _query.isEmpty ? null : _query);
      if (!mounted) return;
      setState(() {
        _items.addAll(r.items);
        _done = !r.hasMore;
        _page++;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scroll.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          textInputAction: TextInputAction.search,
          onSubmitted: (v) {
            _query = v.trim();
            _refresh();
          },
          decoration: InputDecoration(
            hintText: 'ابحث عن منتج...',
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      _query = '';
                      _refresh();
                    },
                  )
                : null,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                _chip(null, 'الكل'),
                ..._cats.map((c) => _chip(c.slug, c.name)),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _sortChip('newest', 'الأحدث'),
                _sortChip('popular', 'الأكثر مبيعاً'),
                _sortChip('price_asc', 'السعر: من الأقل'),
                _sortChip('price_desc', 'السعر: من الأعلى'),
              ],
            ),
          ),
          Expanded(
            child: _error != null && _items.isEmpty
                ? ErrorState(message: _error!, onRetry: _refresh)
                : _items.isEmpty && !_loading
                    ? const EmptyState(icon: Icons.search_off, message: 'لا توجد منتجات مطابقة')
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: GridView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.62,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: _items.length + (_loading ? 2 : 0),
                          itemBuilder: (_, i) {
                            if (i >= _items.length) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final p = _items[i];
                            return ProductCard(product: p, onTap: () => context.push('/product/${p.slug}'));
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String? slug, String label) {
    final active = _category == slug;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) {
          _category = active && slug != null ? null : slug;
          _refresh();
        },
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: active ? Colors.white : null),
        selectedColor: const Color(0xFF8B5CF6),
        backgroundColor: const Color(0x14FFFFFF),
        side: BorderSide(color: active ? Colors.transparent : const Color(0x1FFFFFFF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
    );
  }

  Widget _sortChip(String key, String label) {
    final active = _sort == key;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: GestureDetector(
        onTap: () {
          _sort = key;
          _refresh();
        },
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
            color: active ? const Color(0xFF22D3EE) : const Color(0x80FFFFFF),
          ),
        ),
      ),
    );
  }
}
