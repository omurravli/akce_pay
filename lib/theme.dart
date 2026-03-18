import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF137FEC);
  static const primaryLight = Color(0xFF1A9BFF);
  static const primaryDark = Color(0xFF0F66BE);
  static const backgroundLight = Color(0xFFF6F7F8);
  static const backgroundDark = Color(0xFF101922);
  static const surfaceLight = Colors.white;
  static const surfaceDark = Color(0xFF1A2634);
  static const cardDark = Color(0xFF1E2D3D);
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);
  static const green400 = Color(0xFF4ADE80);
  static const green500 = Color(0xFF22C55E);
  static const green600 = Color(0xFF16A34A);
  static const orange100 = Color(0xFFFFEDD5);
  static const orange600 = Color(0xFFEA580C);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue600 = Color(0xFF2563EB);
  static const purple100 = Color(0xFFF3E8FF);
  static const purple600 = Color(0xFF9333EA);
  static const red100 = Color(0xFFFFE4E6);
  static const red500 = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        surface: AppColors.surfaceLight,
        background: AppColors.backgroundLight,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surfaceDark,
        background: AppColors.backgroundDark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

// Mock contact data
class MockContact {
  final String name;
  final String initials;
  final Color avatarColor;

  const MockContact({
    required this.name,
    required this.initials,
    required this.avatarColor,
  });
}

const List<MockContact> mockContacts = [
  MockContact(name: 'Emma', initials: 'EJ', avatarColor: Color(0xFFEC4899)),
  MockContact(name: 'Michael', initials: 'MS', avatarColor: Color(0xFF3B82F6)),
  MockContact(name: 'Sarah', initials: 'SL', avatarColor: Color(0xFF8B5CF6)),
  MockContact(name: 'David', initials: 'DJ', avatarColor: Color(0xFF10B981)),
  MockContact(name: 'Ayşe', initials: 'AK', avatarColor: Color(0xFFF59E0B)),
  MockContact(name: 'Mehmet', initials: 'MY', avatarColor: Color(0xFFEF4444)),
];
