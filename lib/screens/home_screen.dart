import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_settings.dart';
import '../utils/theme_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final themeStyles = getThemeStyles(settings.theme);
    final textStyles = getTextSizeStyles(settings.textSize);

    return Scaffold(
      // ✅ REAL APP NAVIGATION (FIXED)
      appBar: AppBar(
        title: const Text("PalmTalk"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: settings.theme == 'light'
                ? [const Color(0xFFE0F2FE), Colors.white]
                : [const Color(0xFF0C4A6E), const Color(0xFF082F49)],
          ),
        ),

        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🤟 Gesture → Text
                    _featureCard(
                      themeStyles: themeStyles,
                      textStyles: textStyles,
                      icon: Icons.videocam_outlined,
                      titleLine1: '🤟 Gesture →',
                      titleLine2: 'Text/Voice',
                      onTap: () {
                        Navigator.pushNamed(context, '/gesture-to-text');
                      },
                    ),

                    const SizedBox(height: 24),

                    // ⌨️ Text → Gesture
                    _featureCard(
                      themeStyles: themeStyles,
                      textStyles: textStyles,
                      icon: Icons.chat_bubble_outline,
                      titleLine1: '⌨️🎤 Text/Voice →',
                      titleLine2: 'Gesture',
                      onTap: () {
                        Navigator.pushNamed(context, '/text-to-gesture');
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // 🧩 FEATURE CARD WIDGET
  Widget _featureCard({
    required AppTheme themeStyles,
    required AppTextSizes textStyles,
    required IconData icon,
    required String titleLine1,
    required String titleLine2,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: themeStyles.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              color: Colors.black.withOpacity(
                themeStyles.isDark ? 0.4 : 0.08,
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            // ICON BOX
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeStyles.cameraBgStart,
                    themeStyles.cameraBgEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 40,
                color: themeStyles.iconColor,
              ),
            ),

            const SizedBox(width: 20),

            // TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleLine1,
                    style: TextStyle(
                      fontSize: textStyles.headingLarge,
                      fontWeight: FontWeight.w500,
                      color: themeStyles.text,
                    ),
                  ),
                  Text(
                    titleLine2,
                    style: TextStyle(
                      fontSize: textStyles.headingLarge,
                      fontWeight: FontWeight.w500,
                      color: themeStyles.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}