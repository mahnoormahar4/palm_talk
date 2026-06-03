import 'package:flutter/material.dart';

// ─── Theme ───────────────────────────────────────────────────────────────────

class AppTheme {
  final Color background;
  final Color phoneBackground;
  final Color cardBg;
  final Color text;
  final Color textSecondary;
  final Color primaryText;
  final Color iconColor;
  final Color buttonBg;
  final Color cameraBgStart;
  final Color cameraBgEnd;
  final Color inputBorder;
  final Color inputFocusBorder;
  final bool isDark;

  const AppTheme({
    required this.background,
    required this.phoneBackground,
    required this.cardBg,
    required this.text,
    required this.textSecondary,
    required this.primaryText,
    required this.iconColor,
    required this.buttonBg,
    required this.cameraBgStart,
    required this.cameraBgEnd,
    required this.inputBorder,
    required this.inputFocusBorder,
    required this.isDark,
  });
}

AppTheme getThemeStyles(String theme) {
  if (theme == 'light') {
    return const AppTheme(
      background: Color(0xFFE0F2FE),
      phoneBackground: Color(0xFFDBEAFE),
      cardBg: Colors.white,
      text: Color(0xFF111827),
      textSecondary: Color(0xFF4B5563),
      primaryText: Color(0xFF0369A1),
      iconColor: Color(0xFF0284C7),
      buttonBg: Color(0xFF0284C7),
      cameraBgStart: Color(0xFFBAE6FD),
      cameraBgEnd: Color(0xFF7DD3FC),
      inputBorder: Color(0xFFBAE6FD),
      inputFocusBorder: Color(0xFF0284C7),
      isDark: false,
    );
  } else {
    return const AppTheme(
      background: Color(0xFF0C4A6E),
      phoneBackground: Color(0xFF0369A1),
      cardBg: Color(0xFF0C4A6E),
      text: Colors.white,
      textSecondary: Color(0xFFD1D5DB),
      primaryText: Color(0xFF7DD3FC),
      iconColor: Color(0xFF7DD3FC),
      buttonBg: Color(0xFF0369A1),
      cameraBgStart: Color(0xFF0369A1),
      cameraBgEnd: Color(0xFF0284C7),
      inputBorder: Color(0xFF0369A1),
      inputFocusBorder: Color(0xFF7DD3FC),
      isDark: true,
    );
  }
}

// ─── Text Sizes ───────────────────────────────────────────────────────────────

class AppTextSizes {
  final double heading;
  final double headingLarge;
  final double body;
  final double bodyLarge;
  final double small;
  final double button;
  final double emoji;
  final double emojiLarge;

  const AppTextSizes({
    required this.heading,
    required this.headingLarge,
    required this.body,
    required this.bodyLarge,
    required this.small,
    required this.button,
    required this.emoji,
    required this.emojiLarge,
  });
}

AppTextSizes getTextSizeStyles(double scale) {
  return AppTextSizes(
    heading: 20 * scale,
    headingLarge: 24 * scale,
    body: 16 * scale,
    bodyLarge: 18 * scale,
    small: 14 * scale,
    button: 16 * scale,
    emoji: 30 * scale,
    emojiLarge: 80 * scale,
  );
}
