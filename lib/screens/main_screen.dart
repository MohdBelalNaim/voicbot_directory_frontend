import 'package:flutter/material.dart';
import '../models/app_colors.dart';
import 'contacts_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          ContactsScreen(),
          SearchScreen(),
          FavoritesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0x1F7C3AED),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Color(0xFF9CA3AF)),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined, color: Color(0xFF9CA3AF)),
            selectedIcon: Icon(Icons.search_rounded, color: AppColors.primary),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline_rounded, color: Color(0xFF9CA3AF)),
            selectedIcon: Icon(Icons.star_rounded, color: AppColors.primary),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}
