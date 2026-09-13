import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_colors.dart';
import '../models/customer.dart';
import '../services/api_service.dart';
import 'search_screen.dart';
import 'detail_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Customer> _customers = [];
  bool _loading = true;
  String? _error;

  static const _avatarBgs = [
    Color(0xFFEDE9FE), Color(0xFFD1FAE5), Color(0xFFFFE4E6),
    Color(0xFFFEF3C7), Color(0xFFDBEAFE), Color(0xFFFCE7F3),
  ];
  static const _avatarFgs = [
    Color(0xFF6D28D9), Color(0xFF065F46), Color(0xFFBE123C),
    Color(0xFFB45309), Color(0xFF1D4ED8), Color(0xFFBE185D),
  ];

  Color _bg(int i) => _avatarBgs[i % _avatarBgs.length];
  Color _fg(int i) => _avatarFgs[i % _avatarFgs.length];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await ApiService.fetchCustomers();
      if (mounted) setState(() { _customers = customers; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _navigateTo(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(customer: _customers[index], colorIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Text(
                      'Recents',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary, letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildFeaturedCard(context)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
                  sliver: _buildList(context),
                ),
              ],
            ),
            _buildFAB(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Contacts',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary, letterSpacing: -0.5,
            ),
          ),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: const Icon(Icons.add, color: Color(0xFF475569), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 8),
        child: SizedBox(
          height: 140,
          child: Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Color(0xFFBE123C), size: 28),
              const SizedBox(height: 8),
              Text(
                'Could not connect to server',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFBE123C),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () { setState(() { _loading = true; _error = null; }); _loadCustomers(); },
                child: Text(
                  'Tap to retry',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF7C3AED),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_customers.isEmpty) return const SizedBox.shrink();

    final c = _customers[0];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: GestureDetector(
        onTap: () => _navigateTo(context, 0),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF6D28D9), Color(0xFF7C3AED), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Center(
                          child: Text(
                            c.initials,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF34D399),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: const Color(0xFF7C3AED), width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                c.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                              child: Text('BOT', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AI Assistant',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w400, color: const Color(0xFFDDD6FE)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'QUICK CONNECT',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFFDDD6FE), letterSpacing: 0.8),
                  ),
                  Row(
                    children: [
                      _quickBtn(Icons.message_rounded), const SizedBox(width: 10),
                      _quickBtn(Icons.phone_rounded), const SizedBox(width: 10),
                      _quickBtn(Icons.mic_rounded), const SizedBox(width: 10),
                      _quickBtn(Icons.language_rounded),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickBtn(IconData icon) => Container(
    width: 32, height: 32,
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
    child: Icon(icon, color: Colors.white, size: 15),
  );

  Widget _buildList(BuildContext context) {
    if (_loading || _error != null || _customers.length <= 1) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final listCustomers = _customers.sublist(1);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final c = listCustomers[index];
          final colorIdx = index + 1;
          return GestureDetector(
            onTap: () => _navigateTo(context, colorIdx),
            child: Container(
              height: 68,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _navigateTo(context, colorIdx),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: _bg(colorIdx), borderRadius: BorderRadius.circular(14)),
                          child: Center(
                            child: Text(
                              c.initials,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: c.initials.length > 2 ? 10 : 12,
                                fontWeight: FontWeight.w700, color: _fg(colorIdx),
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
                              Text(c.name, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.2)),
                              const SizedBox(height: 2),
                              Text('AI Assistant', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(20)),
                          child: Text('BOT', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        childCount: listCustomers.length,
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Positioned(
      bottom: 28, right: 24,
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
        child: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
