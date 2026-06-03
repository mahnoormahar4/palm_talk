import 'package:flutter/material.dart';
import '../utils/theme_styles.dart';

class StatusBar extends StatelessWidget {
  final AppTheme themeStyles;

  const StatusBar({super.key, required this.themeStyles});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '9:41',
            style: TextStyle(fontSize: 14, color: themeStyles.text),
          ),
          Container(
            width: 64,
            height: 4,
            decoration: BoxDecoration(
              color: themeStyles.isDark
                  ? const Color(0xFF4B5563)
                  : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Row(
            children: [
              // Signal bars
              Row(
                children: List.generate(4, (i) {
                  final active = i < 3;
                  return Container(
                    width: 4,
                    height: 12,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: active
                          ? themeStyles.text
                          : themeStyles.textSecondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 4),
              // Battery
              Container(
                width: 24,
                height: 12,
                decoration: BoxDecoration(
                  color: themeStyles.text,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
