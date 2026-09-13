import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_colors.dart';
import '../services/favorites_store.dart';
import 'detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static const _bgs = [
    Color(0xFFEDE9FE), Color(0xFFD1FAE5), Color(0xFFFFE4E6),
    Color(0xFFFEF3C7), Color(0xFFDBEAFE), Color(0xFFFCE7F3),
  ];
  static const _fgs = [
    Color(0xFF6D28D9), Color(0xFF065F46), Color(0xFFBE123C),
    Color(0xFFB45309), Color(0xFF1D4ED8), Color(0xFFBE185D),
  ];

  static Color _bg(int i) => _bgs[i % _bgs.length];
  static Color _fg(int i) => _fgs[i % _fgs.length];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: FavoritesStore.instance,
          builder: (context, _) {
            final favorites = FavoritesStore.instance.favorites;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: favorites.isEmpty
                      ? _buildEmpty()
                      : _buildList(context, favorites),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Text(
        'Favorites',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 26, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
            child: const Icon(Icons.star_outline_rounded, color: Color(0xFFF59E0B), size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the ★ on any bot to save it here',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<FavoriteEntry> favorites) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: favorites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, index) => _buildRow(context, favorites[index]),
    );
  }

  Widget _buildRow(BuildContext context, FavoriteEntry entry) {
    final c = entry.customer;
    final ci = entry.colorIndex;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailScreen(customer: c, colorIndex: ci),
        ),
      ),
      child: Container(
        height: 70,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailScreen(customer: c, colorIndex: ci)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: _bg(ci), borderRadius: BorderRadius.circular(14)),
                    child: Center(
                      child: Text(
                        c.initials,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: c.initials.length > 2 ? 10 : 13,
                          fontWeight: FontWeight.w700, color: _fg(ci),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15, fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary, letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('AI Assistant',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => FavoritesStore.instance.toggle(c.id, c.name, ci),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
