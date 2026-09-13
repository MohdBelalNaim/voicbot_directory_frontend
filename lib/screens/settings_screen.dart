import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:voicebot_directory/store/api_store.dart';
import 'package:voicebot_directory/store/app_page.dart';
import '../models/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    textController.text = context.read<ApiStore>().apiUrl;
  }

  updateUrl() {
    context.read<ApiStore>().updateApiUrl(textController.text);
    context.read<AppPage>().setPage(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text('API URL'),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                ),
                onEditingComplete: updateUrl,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: updateUrl,
                child: ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: Theme.of(context).primaryColor,
                    alignment: Alignment.center,
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'Settings',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
    );
  }
}
