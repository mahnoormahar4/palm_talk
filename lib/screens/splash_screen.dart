import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_settings.dart';
import '../utils/theme_styles.dart';
import '../services/tflite_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  final TFLiteService _tfliteService = TFLiteService();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();

    // 🚀 Load model then navigate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  Future<void> _initApp() async {
    try {
      // Load TFLite model
      await _tfliteService.loadModel();

      // Small delay for smooth UX
      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
        );
      }
    } catch (e) {
      debugPrint("Model loading failed: $e");

      // Prevent app crash
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    final themeStyles = getThemeStyles(
      settings.theme,
    );

    final textStyles = getTextSizeStyles(
      settings.textSize,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeStyles.background,
              settings.theme == 'light'
                  ? Colors.white
                  : const Color(0xFF082F49),
            ],
          ),
        ),

        child: Center(
          child: FadeTransition(
            opacity: _fade,

            child: ScaleTransition(
              scale: _scale,

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  // ================= LOGO =================
                  Container(
                    width: 160,
                    height: 160,

                    decoration: BoxDecoration(
                      color: themeStyles.cameraBgStart.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),

                    child: Center(
                      child: Text(
                        '🤟',
                        style: TextStyle(
                          fontSize: textStyles.emojiLarge,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ================= APP NAME =================
                  Text(
                    'PalmTalk',
                    style: TextStyle(
                      fontSize:
                      textStyles.headingLarge + 6,

                      fontWeight: FontWeight.bold,

                      color: settings.theme == 'light'
                          ? const Color(0xFF0284C7)
                          : const Color(0xFF7DD3FC),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ================= TAGLINE =================
                  Text(
                    'Breaking the Silence',
                    style: TextStyle(
                      fontSize: textStyles.bodyLarge,
                      color: themeStyles.primaryText,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ================= LOADING =================
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}