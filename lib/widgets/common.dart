import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/models.dart';
import '../state/providers.dart';
import '../theme.dart';

/// بطاقة زجاجية
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppTheme.border),
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: card);
  }
}

/// زر متدرج رئيسي
class GlowButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  const GlowButton({super.key, required this.label, this.onPressed, this.loading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: loading ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loading)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  else ...[
                    if (icon != null) ...[Icon(icon, color: Colors.white, size: 19), const SizedBox(width: 8)],
                    Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// صورة منتج مع تحميل مؤقت
class ProductImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  const ProductImage({super.key, required this.url, this.width, this.height, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: const Color(0xFF221E45),
        child: const Icon(Icons.phone_iphone, color: AppTheme.textFaint, size: 36),
      );
}

/// بطاقة منتج في الشبكة
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final wish = context.watch<WishlistProvider>();
    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: ProductImage(url: product.image)),
                if (product.badge.isNotEmpty)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(99)),
                      child: Text(product.badge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: IconButton(
                    icon: Icon(wish.has(product.id) ? Icons.favorite : Icons.favorite_border,
                        color: wish.has(product.id) ? Colors.redAccent : AppTheme.textDim),
                    onPressed: () => context.read<WishlistProvider>().toggle(product),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.4)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fmtPrice(product.price), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          if (product.onSale)
                            Text(fmtPrice(product.oldPrice!),
                                style: const TextStyle(fontSize: 11, color: AppTheme.textFaint, decoration: TextDecoration.lineThrough)),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(99),
                      onTap: product.outOfStock
                          ? null
                          : () {
                              cart.add(product);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أُضيف إلى السلة'), duration: Duration(seconds: 1)));
                            },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: product.outOfStock ? const Color(0x1FFFFFFF) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.shopping_bag_outlined, size: 19, color: product.outOfStock ? AppTheme.textFaint : AppTheme.bg),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// حالة فارغة موحدة
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.icon, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppTheme.textFaint),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textDim, fontWeight: FontWeight.w700, fontSize: 16)),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              GlowButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// خطأ مع إعادة المحاولة
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => EmptyState(icon: Icons.cloud_off, message: message, actionLabel: 'إعادة المحاولة', onAction: onRetry);
}

/// شريط إعلانات متحرك أعلى الشاشة
class AnnouncementBar extends StatelessWidget {
  final String text;
  const AnnouncementBar({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}
