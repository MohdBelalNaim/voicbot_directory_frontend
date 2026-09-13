import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_colors.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeroHeader(context),
                  _buildContactCard(),
                  _buildRecentActivity(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6D28D9), Color(0xFF7C3AED), Color(0xFF8B5CF6)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative ghost icons
              Positioned(
                top: 60,
                left: 20,
                child: Icon(Icons.phone_rounded, color: Colors.white.withValues(alpha: 0.07), size: 60),
              ),
              Positioned(
                top: 80,
                right: 30,
                child: Icon(Icons.chat_bubble_rounded, color: Colors.white.withValues(alpha: 0.07), size: 50),
              ),
              Positioned(
                bottom: 40,
                left: 100,
                child: Icon(Icons.person_rounded, color: Colors.white.withValues(alpha: 0.07), size: 70),
              ),
              Positioned(
                top: 40,
                right: 80,
                child: Icon(Icons.mic_rounded, color: Colors.white.withValues(alpha: 0.07), size: 45),
              ),
              // Status bar area
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.star_border_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.more_horiz, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -52,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFEDE9FE), width: 1),
                    ),
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDE9FE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Color(0xFF7C3AED),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.signal_cellular_alt_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 68, 24, 0),
      child: Column(
        children: [
          // Name + verified
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Jio Saarthi AI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.verified_rounded, color: Color(0xFF7C3AED), size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '+91 1800 896 9999',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          // Language badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language_rounded, color: Color(0xFF7C3AED), size: 13),
                const SizedBox(width: 6),
                Text(
                  'Hindi, English, Tamil & 2 more',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6D28D9),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Divider + CONNECT label
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),
          Text(
            'CONNECT',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9CA3AF),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionBtn(
                icon: Icons.phone_rounded,
                bg: const Color(0xFFF5F3FF),
                fg: const Color(0xFF7C3AED),
                isPrimary: false,
              ),
              const SizedBox(width: 16),
              _buildActionBtn(
                icon: Icons.chat_rounded,
                bg: const Color(0xFFECFDF5),
                fg: const Color(0xFF059669),
                isPrimary: false,
              ),
              const SizedBox(width: 16),
              _buildActionBtn(
                icon: Icons.mic_rounded,
                bg: const Color(0xFF7C3AED),
                fg: Colors.white,
                isPrimary: true,
              ),
              const SizedBox(width: 16),
              _buildActionBtn(
                icon: Icons.language_rounded,
                bg: const Color(0xFFEFF6FF),
                fg: const Color(0xFF2563EB),
                isPrimary: false,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required Color bg,
    required Color fg,
    required bool isPrimary,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: fg, size: 20),
    );
  }

  Widget _buildRecentActivity() {
    final List<Map<String, dynamic>> activities = [
      {
        'title': 'Voice Query (Plan & Bills)',
        'subtitle': 'Incoming Session',
        'time': '10:24 am',
        'icon': Icons.arrow_downward_rounded,
        'iconBg': const Color(0xFFF5F3FF),
        'iconColor': const Color(0xFF7C3AED),
        'titleColor': const Color(0xFF1F2937),
        'subtitleColor': const Color(0xFF6B7280),
      },
      {
        'title': 'Automated Update',
        'subtitle': 'Duration: 2m 14s',
        'time': 'Yesterday',
        'icon': Icons.arrow_upward_rounded,
        'iconBg': const Color(0xFFF8FAFC),
        'iconColor': const Color(0xFF64748B),
        'titleColor': const Color(0xFF1F2937),
        'subtitleColor': const Color(0xFF6B7280),
      },
      {
        'title': 'Payment Reminder',
        'subtitle': 'Missed Bot Alert',
        'time': 'May 20',
        'icon': Icons.phone_missed_rounded,
        'iconBg': const Color(0xFFFFF1F2),
        'iconColor': const Color(0xFFF43F5E),
        'titleColor': const Color(0xFFF43F5E),
        'subtitleColor': const Color(0xFFFB7185),
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'View All',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...activities.map((activity) => _buildActivityRow(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityRow(Map<String, dynamic> activity) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: activity['iconBg'] as Color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['iconColor'] as Color,
              size: 15,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: activity['titleColor'] as Color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['subtitle'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: activity['subtitleColor'] as Color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity['time'] as String,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Speak with Saarthi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 112,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
