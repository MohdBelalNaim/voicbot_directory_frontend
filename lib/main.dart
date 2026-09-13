import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/contacts_screen.dart';

void main() {
  runApp(const VoiceBotApp());
}

class VoiceBotApp extends StatelessWidget {
  const VoiceBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Bots Directory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          primary: const Color(0xFF7C3AED),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F3F7),
      ),
      home: const ContactsScreen(),
    );
  }
}
