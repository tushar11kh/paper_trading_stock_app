// app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/bottom_nav_controller.dart';
import 'screens/home_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/order_screen.dart';
import 'screens/profile_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';



class PaperTradeApp extends ConsumerWidget {
  final Widget child;
  const PaperTradeApp({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    final screens = [
      const HomeScreen(),
      const PortfolioScreen(),
      const OrderScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) async{
          ref.read(bottomNavIndexProvider.notifier).state = index;
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/portfolio');
              break;
            case 2:
              context.go('/order');
              break;
            case 3:
              context.go('/profile');
                 final secureStorage = const FlutterSecureStorage();
                 final userId = await secureStorage.read(key: 'auth_user_id');
               print("User id: $userId");
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Portfolio'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_document), label: 'Order'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
