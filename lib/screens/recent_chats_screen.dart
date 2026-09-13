import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_colors.dart';
import '../models/customer.dart';
import '../services/chat_history_store.dart';
import 'detail_screen.dart';

class RecentChatsScreen extends StatefulWidget {
  const RecentChatsScreen({super.key});

  @override
  State<RecentChatsScreen> createState() => _RecentChatsScreenState();
}

class _RecentChatsScreenState extends State<RecentChatsScreen> {
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final chats = ChatHistoryStore.instance.chats;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: chats.isEmpty ? _buildEmpty() : _buildList(chats),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: const Icon(Icons.chevron_left, color: Color(0xFF475569), size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Recent Chats',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary, letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF7C3AED), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'No recent chats yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start a conversation with any bot',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<RecentChat> chats) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: chats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, index) => _buildChatRow(context, chats[index]),
    );
  }

  Widget _buildChatRow(BuildContext context, RecentChat chat) {
    final initials = Customer(id: chat.customerId, name: chat.customerName).initials;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailScreen(
            customer: Customer(id: chat.customerId, name: chat.customerName),
            colorIndex: chat.colorIndex,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailScreen(
                  customer: Customer(id: chat.customerId, name: chat.customerName),
                  colorIndex: chat.colorIndex,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: _bg(chat.colorIndex), borderRadius: BorderRadius.circular(14)),
                    child: Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: initials.length > 2 ? 10 : 13,
                          fontWeight: FontWeight.w700, color: _fg(chat.colorIndex),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat.customerName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          chat.lastMessage,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _timeAgo(chat.updatedAt),
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF9CA3AF)),
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
