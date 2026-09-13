import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_colors.dart';
import '../models/customer.dart';
import '../services/api_service.dart';
import '../services/chat_history_store.dart';
import '../services/favorites_store.dart';
import 'call_screen.dart';

class _ChatMessage {
  final String role;
  String text;
  _ChatMessage({required this.role, required this.text});
}

class DetailScreen extends StatefulWidget {
  final Customer customer;
  final int colorIndex;

  const DetailScreen({
    super.key,
    required this.customer,
    this.colorIndex = 0,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _messages = <_ChatMessage>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  static const _avatarBgs = [
    Color(0xFFEDE9FE), Color(0xFFD1FAE5), Color(0xFFFFE4E6),
    Color(0xFFFEF3C7), Color(0xFFDBEAFE), Color(0xFFFCE7F3),
  ];
  static const _avatarFgs = [
    Color(0xFF6D28D9), Color(0xFF065F46), Color(0xFFBE123C),
    Color(0xFFB45309), Color(0xFF1D4ED8), Color(0xFFBE185D),
  ];

  Color get _bg => _avatarBgs[widget.colorIndex % _avatarBgs.length];
  Color get _fg => _avatarFgs[widget.colorIndex % _avatarFgs.length];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: text));
      _messages.add(_ChatMessage(role: 'assistant', text: ''));
      _isSending = true;
    });
    _scrollToBottom();
    ChatHistoryStore.instance.record(widget.customer.id, widget.customer.name, widget.colorIndex, text);

    try {
      await for (final chunk in ApiService.streamChat(widget.customer.id, text)) {
        if (mounted) {
          setState(() => _messages.last.text += chunk);
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _messages.last.text = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeroHeader(context),
          _buildContactInfo(),
          Expanded(child: _buildChatArea()),
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 160,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF6D28D9), Color(0xFF7C3AED), Color(0xFF8B5CF6)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      widget.customer.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      ListenableBuilder(
                        listenable: FavoritesStore.instance,
                        builder: (context, _) {
                          final isFav = FavoritesStore.instance.isFavorite(widget.customer.id);
                          return GestureDetector(
                            onTap: () => FavoritesStore.instance.toggle(
                              widget.customer.id, widget.customer.name, widget.colorIndex,
                            ),
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                color: isFav ? const Color(0xFFFBBF24) : Colors.white,
                                size: 18,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CallScreen(
                              customer: widget.customer,
                              avatarBg: _bg,
                              avatarFg: _fg,
                            ),
                          ),
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.call_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -44,
          left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.2), blurRadius: 20, spreadRadius: 2)],
              ),
              child: Container(
                width: 76, height: 76,
                decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    widget.customer.initials,
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: _fg),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 58, 24, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  widget.customer.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, letterSpacing: -0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.verified_rounded, color: Color(0xFF7C3AED), size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'AI Assistant',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
              child: Icon(Icons.chat_bubble_outline_rounded, color: _fg, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'Ask me anything about\n${widget.customer.name}',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildBubble(_messages[index]),
    );
  }

  Widget _buildBubble(_ChatMessage message) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  widget.customer.initials.isNotEmpty ? widget.customer.initials[0] : '?',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: _fg),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: message.text.isEmpty && !isUser
                  ? _buildTypingDots()
                  : Text(
                      message.text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, size: 16, color: Color(0xFF7C3AED)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
        ),
      )),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                enabled: !_isSending,
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textPrimary),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isSending ? null : _send,
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _isSending ? const Color(0xFFD1D5DB) : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: _isSending ? null : [
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(
                _isSending ? Icons.hourglass_top_rounded : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
