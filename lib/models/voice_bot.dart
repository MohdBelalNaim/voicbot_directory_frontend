import 'package:flutter/material.dart';
import '../models/app_colors.dart';

class VoiceBot {
  final String name;
  final String phoneNumber;
  final String category;
  final String initials;
  final Color avatarBg;
  final Color avatarText;
  final String? languages;

  const VoiceBot({
    required this.name,
    required this.phoneNumber,
    required this.category,
    required this.initials,
    required this.avatarBg,
    required this.avatarText,
    this.languages,
  });
}

final List<VoiceBot> voiceBots = [
  const VoiceBot(
    name: 'Airtel Voice Bot (Asha)',
    phoneNumber: '+91 98101 98101',
    category: 'Telecom',
    initials: 'AA',
    avatarBg: Color(0xFFCCFBF1),
    avatarText: Color(0xFF0F766E),
    languages: 'Hindi, English, Tamil',
  ),
  const VoiceBot(
    name: 'CRED Support Bot',
    phoneNumber: '+91 80456 78900',
    category: 'Fintech',
    initials: 'CR',
    avatarBg: Color(0xFFFCE7F3),
    avatarText: Color(0xFFBE185D),
  ),
  const VoiceBot(
    name: 'Flipkart Voice Assistant',
    phoneNumber: '+91 1800 208 9898',
    category: 'Retail',
    initials: 'FK',
    avatarBg: Color(0xFFD1FAE5),
    avatarText: Color(0xFF065F46),
  ),
  const VoiceBot(
    name: 'HDFC Bank EVA',
    phoneNumber: '+91 1800 202 6161',
    category: 'Banking',
    initials: 'EVA',
    avatarBg: Color(0xFFFFE4E6),
    avatarText: Color(0xFFBE123C),
  ),
  const VoiceBot(
    name: 'IndiGo 6Eskai Bot',
    phoneNumber: '+91 124 617 3838',
    category: 'Airlines',
    initials: '6E',
    avatarBg: Color(0xFFCCFBF1),
    avatarText: Color(0xFF0F766E),
  ),
  const VoiceBot(
    name: 'MakeMyTrip Myra',
    phoneNumber: '+91 124 462 8747',
    category: 'Travel',
    initials: 'MM',
    avatarBg: Color(0xFFFCE7F3),
    avatarText: Color(0xFFBE185D),
  ),
  const VoiceBot(
    name: 'Swiggy Genie AI',
    phoneNumber: '+91 80 6746 6729',
    category: 'Delivery',
    initials: 'SG',
    avatarBg: Color(0xFFFEF3C7),
    avatarText: Color(0xFFB45309),
  ),
  const VoiceBot(
    name: 'Tata Neu Assistant',
    phoneNumber: '+91 1800 258 2555',
    category: 'SuperApp',
    initials: 'NEU',
    avatarBg: Color(0xFFFFE4E6),
    avatarText: Color(0xFFBE123C),
  ),
  const VoiceBot(
    name: 'Zomato FoodBot',
    phoneNumber: '+91 11 3959 5000',
    category: 'Dining',
    initials: 'ZO',
    avatarBg: Color(0xFFCCFBF1),
    avatarText: Color(0xFF0F766E),
  ),
];

const VoiceBot featuredBot = VoiceBot(
  name: 'Jio Saarthi AI',
  phoneNumber: '+91 1800 896 9999',
  category: 'Telecom',
  initials: 'JS',
  avatarBg: AppColors.primaryLight,
  avatarText: Colors.white,
  languages: 'Hindi, English, Tamil & 2 more',
);

final List<VoiceBot> searchBots = [
  const VoiceBot(
    name: 'Airtel Asha Assistant',
    phoneNumber: '',
    category: 'Telecom',
    initials: 'AA',
    avatarBg: Color(0xFFFFE4E6),
    avatarText: Color(0xFFB91C1C),
    languages: 'Hindi, English, Tamil',
  ),
  const VoiceBot(
    name: 'Axis AHA Voicebot',
    phoneNumber: '',
    category: 'Banking',
    initials: 'AH',
    avatarBg: Color(0xFFFECDD3),
    avatarText: Color(0xFF9F1239),
    languages: 'Hindi, English',
  ),
  const VoiceBot(
    name: 'Air India Maharaja AI.g',
    phoneNumber: '',
    category: 'Airlines',
    initials: 'AI',
    avatarBg: Color(0xFFFFEDD5),
    avatarText: Color(0xFFC2410C),
    languages: 'Multilingual (8)',
  ),
  const VoiceBot(
    name: 'Apollo Health Assist',
    phoneNumber: '',
    category: 'Healthcare',
    initials: 'AP',
    avatarBg: Color(0xFFCCFBF1),
    avatarText: Color(0xFF115E59),
    languages: 'Hindi, English, Telugu',
  ),
  const VoiceBot(
    name: 'Amazon Pay Voice Assist',
    phoneNumber: '',
    category: 'Fintech & Bills',
    initials: 'AZ',
    avatarBg: Color(0xFFEDE9FE),
    avatarText: Color(0xFF5B21B6),
    languages: 'Hindi, English',
  ),
  const VoiceBot(
    name: 'Angel One SmartTalk',
    phoneNumber: '',
    category: 'Trading',
    initials: 'AO',
    avatarBg: Color(0xFFD1FAE5),
    avatarText: Color(0xFF064E3B),
    languages: 'Hindi, Gujarati, English',
  ),
];
