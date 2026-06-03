import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'utils/app_settings.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/gesture_to_text_screen.dart';
import 'screens/text_to_gesture_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppSettings(),

      child: Builder(
        builder: (context) {
          final settings = context.watch<AppSettings>();

          return MaterialApp(
            debugShowCheckedModeBanner: false,

            // 🌙 THEME CONTROL
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode:
            settings.theme == 'dark' ? ThemeMode.dark : ThemeMode.light,

            // 🔠 GLOBAL TEXT SCALING
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(settings.textSize),
                ),
                child: child!,
              );
            },

            // 🚀 START ROUTE
            initialRoute: '/',

            // 🧭 ROUTES
            routes: {
              '/': (context) => const SplashScreen(),
              '/home': (context) => const HomeScreen(),
              '/gesture-to-text': (context) => const GestureToTextVoiceScreen(),
              '/text-to-gesture': (context) => const TextToGestureScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}