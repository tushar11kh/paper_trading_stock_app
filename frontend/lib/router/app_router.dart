// router/app_router.dart
import 'package:PaperTradeApp/screens/login.dart';
import 'package:PaperTradeApp/screens/splashscreen.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/portfolio_screen.dart';
import '../screens/order_screen.dart';
import '../screens/profile_screen.dart';
import '../app.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => PaperTradeApp(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/portfolio',
          name: 'portfolio',
          builder: (context, state) => const PortfolioScreen(),
        ),
        GoRoute(
          path: '/order',
          name: 'order',
          builder: (context, state) => const OrderScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
