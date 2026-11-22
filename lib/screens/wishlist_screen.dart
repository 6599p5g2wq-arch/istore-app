import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/providers.dart';
import '../widgets/common.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wish = context.watch<WishlistProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: wish.items.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border,
              message: 'لا توجد منتجات في المفضلة',
              actionLabel: 'تصفح المنتجات',
              onAction: () => context.go('/products'),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: wish.items.length,
              itemBuilder: (_, i) {
                final p = wish.items[i];
                return ProductCard(product: p, onTap: () => context.push('/product/${p.slug}'));
              },
            ),
    );
  }
}
