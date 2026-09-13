import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:voicebot_directory/store/api_store.dart';
import '../models/app_colors.dart';
import '../models/customer.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';
import 'recent_chats_screen.dart';

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
    Color(0xFFEDE9FE),
    Color(0xFFD1FAE5),
    Color(0xFFFFE4E6),
    Color(0xFFFEF3C7),
    Color(0xFFDBEAFE),
    Color(0xFFFCE7F3),
  ];
  static const _avatarFgs = [
    Color(0xFF6D28D9),
    Color(0xFF065F46),
    Color(0xFFBE123C),
    Color(0xFFB45309),
    Color(0xFF1D4ED8),
    Color(0xFFBE185D),
  ];

  Color _bg(int i) => _avatarBgs[i % _avatarBgs.length];
  Color _fg(int i) => _avatarFgs[i % _avatarFgs.length];

  @override
  void initState() {
    super.initState();
  }

  bool _initialized = false;

  late ApiService apiService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      final apiStore = context.read<ApiStore>();
      apiService = ApiService(apiStore);

      _initialized = true;
      _loadCustomers();
    }
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _loading = true;
    });

    try {
      final customers = await apiService.fetchCustomers();
      if (mounted) {
        setState(() {
          _customers = customers;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            if (_loading)
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 400,
                  child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary)),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(child: _buildError(context))
            else if (_customers.isEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 300,
                  child: Center(
                    child: Text(
                      'No bots available',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                sliver: _buildCustomerSliver(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Contacts',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _iconBtn(
            Icons.history_rounded,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RecentChatsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ],
        ),
        child: Icon(icon, color: const Color(0xFF475569), size: 20),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: Color(0xFFBE123C), size: 28),
            const SizedBox(height: 8),
            Text('Could not connect to server',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFBE123C))),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadCustomers();
              },
              child: Text('Tap to retry',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSliver(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final c = _customers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        DetailScreen(customer: c, colorIndex: index)),
              ),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              DetailScreen(customer: c, colorIndex: index)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                                color: _bg(index),
                                borderRadius: BorderRadius.circular(14)),
                            child: Center(
                              child: Text(
                                c.initials,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: c.initials.length > 2 ? 10 : 13,
                                  fontWeight: FontWeight.w700,
                                  color: _fg(index),
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
                                Text(
                                  c.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'AI Assistant',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text('BOT',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        childCount: _customers.length,
      ),
    );
  }
}
