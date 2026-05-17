import 'package:flutter/material.dart';

class AppTheme {
  // Core Colors
  static const Color background = Color(0xFF080B14);
  static const Color surface = Color(0xFF0F1624);
  static const Color surfaceElevated = Color(0xFF161E30);
  static const Color border = Color(0xFF1E2A40);

  static const Color crimson = Color(0xFFDC2626);
  static const Color crimsonDark = Color(0xFF991B1B);
  static const Color crimsonGlow = Color(0x33DC2626);

  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldGlow = Color(0x2210B981);

  static const Color amber = Color(0xFFF59E0B);
  static const Color amberGlow = Color(0x22F59E0B);

  static const Color electric = Color(0xFF3B82F6);
  static const Color electricGlow = Color(0x223B82F6);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);
  static const Color terminalGreen = Color(0xFF4ADE80);

  // Severity Colors
  static Color severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFDC2626);
      case 'HIGH':
        return const Color(0xFFEA580C);
      case 'MEDIUM':
        return const Color(0xFFF59E0B);
      case 'LOW':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  // Priority Colors
  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC2626);
      case 'high':
        return const Color(0xFFEA580C);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  // Crisis Type Icons
  static String crisisEmoji(String type) {
    final t = type.toLowerCase();
    if (t.contains('flood')) return '🌊';
    if (t.contains('fire')) return '🔥';
    if (t.contains('accident')) return '🚗';
    if (t.contains('road') || t.contains('block')) return '🚧';
    if (t.contains('heat')) return '🌡️';
    if (t.contains('earthquake')) return '⚠️';
    return '🚨';
  }

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        fontFamily: 'monospace',
        colorScheme: const ColorScheme.dark(
          primary: crimson,
          surface: surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      );
}
