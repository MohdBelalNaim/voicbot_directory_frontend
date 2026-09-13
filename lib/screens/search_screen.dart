import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_colors.dart';
import '../models/customer.dart';
import '../services/api_service.dart';
import '../services/chat_history_store.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Customer> _customers = [];
  final _controller = TextEditingController();
  String _query = '';

  static const _bgs = [
    Color(0xFFEDE9FE), Color(0xFFD1FAE5), Color(0xFFFFE4E6),
    Color(0xFFFEF3C7), Color(0xFFDBEAFE), Color(0xFFFCE7F3),
  ];
  static const _fgs = [
    Color(0xFF6D28D9), Color(0xFF065F46), Color(0xFFBE123C),
    Color(0xFFB45309), Color(0xFF1D4ED8), Color(0xFFBE185D),
  ];

  Color _bg(int i) => _bgs[i % _bgs.length];
  Color _fg(int i) => _fgs[i % _fgs.length];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await ApiService.fetchCustomers();
      if (mounted) setState(() => _customers = customers);
    } catch (_) {}
  }

  List<Customer> get _filtered {
    if (_query.isEmpty) return _customers;
    final q = _query.toLowerCase();
    return _customers.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateTo(BuildContext context, Customer c, int colorIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(customer: c, colorIndex: colorIndex)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recents = ChatHistoryStore.instance.chats;
    final results = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (recents.isNotEmpty && _query.isEmpty) _buildRecentsSection(context, recents),
                  _buildResultsSection(context, results),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        'Search Bots',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 26, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Search bots...',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                ),
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textPrimary),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () { _controller.clear(); setState(() => _query = ''); },
                child: Container(
                  width: 20, height: 20,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                ),
              )
            else
              const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentsSection(BuildContext context, List<RecentChat> recents) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECENTS',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: const Color(0xFF9CA3AF), letterSpacing: 0.8)),
          const SizedBox(height: 12),
          SizedBox(
            height: 82,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recents.length,
              itemBuilder: (context, index) {
                final chat = recents[index];
                final c = Customer(id: chat.customerId, name: chat.customerName);
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => _navigateTo(context, c, chat.colorIndex),
                    child: Column(
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: _bg(chat.colorIndex),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _fg(chat.colorIndex).withValues(alpha: 0.15)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Center(
                            child: Text(c.initials,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: c.initials.length > 2 ? 10 : 13,
                                    fontWeight: FontWeight.w800, color: _fg(chat.colorIndex))),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 56,
                          child: Text(
                            chat.customerName.split(' ').first,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF374151)),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFE5E7EB)),
        ],
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context, List<Customer> results) {
    final label = _query.isEmpty
        ? 'ALL BOTS'
        : '${results.length} RESULT${results.length == 1 ? '' : 'S'} FOR "${_query.toUpperCase()}"';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: const Color(0xFF9CA3AF), letterSpacing: 0.6)),
          const SizedBox(height: 8),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(
                child: Text('No bots found',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textSecondary)),
              ),
            )
          else
            ...results.asMap().entries.map((e) {
              final colorIndex = _customers.indexOf(e.value);
              return _buildBotRow(context, e.value, colorIndex < 0 ? 0 : colorIndex);
            }),
        ],
      ),
    );
  }

  Widget _buildBotRow(BuildContext context, Customer c, int colorIndex) {
    return GestureDetector(
      onTap: () => _navigateTo(context, c, colorIndex),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateTo(context, c, colorIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: _bg(colorIndex), shape: BoxShape.circle),
                    child: Center(
                      child: Text(c.initials,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: c.initials.length > 2 ? 10 : 13,
                              fontWeight: FontWeight.w700, color: _fg(colorIndex))),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('AI Assistant',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Color(0xFF6B7280)),
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
