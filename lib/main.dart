import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'screens/account_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/home_screen.dart';
import 'screens/product_screen.dart';
import 'screens/products_screen.dart';
import 'screens/track_screen.dart';
import 'screens/wishlist_screen.dart';
import 'state/providers.dart';
import 'theme.dart';
import 'widgets/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => CartProvider()..init()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()..init()),
      ],
      child: const IStoreApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/products',
          builder: (_, state) => ProductsScreen(category: state.uri.queryParameters['category']),
        ),
        GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
        GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
      ],
    ),
    GoRoute(path: '/product/:slug', builder: (_, state) => ProductScreen(slug: state.pathParameters['slug']!)),
    GoRoute(
      path: '/checkout',
      builder: (_, state) {
        final extra = state.extra is Map ? state.extra as Map : const {};
        return CheckoutScreen(coupon: extra['coupon'] as String?);
      },
    ),
    GoRoute(
      path: '/order-success',
      builder: (_, state) => OrderSuccessScreen(order: (state.extra as Map?)?.cast<String, dynamic>() ?? const {}),
    ),
    GoRoute(
      path: '/track',
      builder: (_, state) => TrackScreen(token: state.uri.queryParameters['token']),
    ),
    GoRoute(path: '/wishlist', builder: (_, __) => const WishlistScreen()),
  ],
);

class IStoreApp extends StatelessWidget {
  const IStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'آي ستور',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: _router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    );
  }
}

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = ['/', '/products', '/cart', '/account'];

  int _indexOf(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    final i = _tabs.indexWhere((t) => t == loc);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _indexOf(context);
    final cartCount = context.watch<CartProvider>().count;
    final settings = context.watch<SettingsProvider>().settings;
    return Scaffold(
      body: Column(
        children: [
          if (settings != null && settings.announcement.isNotEmpty)
            SafeArea(bottom: false, child: AnnouncementBar(text: settings.announcement)),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.accent.withValues(alpha: 0.25),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          const NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'المنتجات'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag),
            ),
            label: 'السلة',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}
