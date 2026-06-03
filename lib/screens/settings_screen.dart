import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_settings.dart';
import '../utils/theme_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final textStyles = getTextSizeStyles(settings.textSize);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(fontSize: textStyles.headingLarge),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 Theme Toggle
          SwitchListTile(
            title: Text(
              "Dark Mode",
              style: TextStyle(fontSize: textStyles.bodyLarge),
            ),
            subtitle: Text(
              "Switch app theme",
              style: TextStyle(fontSize: textStyles.small),
            ),
            value: settings.theme == 'dark',
            onChanged: (val) {
              settings.setTheme(val ? 'dark' : 'light');
            },
          ),

          const Divider(),

          // 🔹 Text Size
          ListTile(
            title: Text(
              "Text Size",
              style: TextStyle(fontSize: textStyles.bodyLarge),
            ),
            subtitle: Text(
              "Adjust UI text scaling",
              style: TextStyle(fontSize: textStyles.small),
            ),
          ),

          Slider(
            value: settings.textSize,
            min: 0.8,
            max: 1.5,
            divisions: 7,
            label: settings.textSize.toStringAsFixed(1),
            onChanged: (val) {
              settings.setTextSize(val);
            },
          ),

          const Divider(),

          // 🔹 Debug Mode
          SwitchListTile(
            title: Text(
              "Debug Mode",
              style: TextStyle(fontSize: textStyles.bodyLarge),
            ),
            subtitle: Text(
              "Show logs and backend info",
              style: TextStyle(fontSize: textStyles.small),
            ),
            value: settings.debugMode,
            onChanged: (val) {
              settings.setDebugMode(val);
            },
          ),

          const Divider(),

          // 🔹 Backend Status
          ListTile(
            title: Text(
              "Backend Status",
              style: TextStyle(fontSize: textStyles.bodyLarge),
            ),
            subtitle: Text(
              settings.backendConnected ? "Connected" : "Not Connected",
              style: TextStyle(fontSize: textStyles.small),
            ),
            trailing: Icon(
              settings.backendConnected
                  ? Icons.cloud_done
                  : Icons.cloud_off,
            ),
          ),
        ],
      ),
    );
  }
}