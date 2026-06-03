import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LanguageSelectionScreen extends StatefulWidget {
  final String detectedText;

  const LanguageSelectionScreen({
    super.key,
    required this.detectedText,
  });

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  bool isLoading = false;

  String translatedText = "";

  // 🧠 ONLY 3 TEXT TRANSLATION LANGUAGES
  final Map<String, String> languageCodes = {
    "English": "en",
    "Urdu": "ur",
    "Sindhi": "sd",
  };

  String selectedVoiceLang = "English";

  // ================= TRANSLATION =================
  Future<String> translateText(String text, String targetLang) async {
    try {
      // 🔥 IMPORTANT FIX: encode text properly
      final encodedText = Uri.encodeComponent(text);

      final url =
          "https://translate.googleapis.com/translate_a/single"
          "?client=gtx"
          "&sl=auto"
          "&tl=$targetLang"
          "&dt=t"
          "&q=$encodedText";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 🧠 safe extraction
        final translated = data[0][0][0].toString();

        debugPrint("TRANSLATED: $translated");

        return translated;
      } else {
        debugPrint("ERROR CODE: ${response.statusCode}");
        return text;
      }
    } catch (e) {
      debugPrint("TRANSLATION ERROR: $e");
      return text;
    }
  }

  // ================= HANDLE TRANSLATION =================
  void handleTranslate(String langName) async {
    setState(() => isLoading = true);

    final langCode = languageCodes[langName];

    // 🧠 safety check
    if (langCode == null) {
      setState(() => isLoading = false);
      return;
    }

    final translated = await translateText(
      widget.detectedText,
      langCode,
    );

    setState(() {
      translatedText = translated;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🌐 Translate To"),
      ),

      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📝 ORIGINAL
                const Text(
                  "Original:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(widget.detectedText),

                const SizedBox(height: 20),

                // 🌍 TRANSLATED
                const Text(
                  "Translated:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),

                Text(
                  translatedText.isEmpty
                      ? "No translation yet"
                      : translatedText,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Select Language (Text Translation)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                // 🌍 LANGUAGE LIST
                Expanded(
                  child: ListView(
                    children: languageCodes.keys.map((lang) {
                      return Card(
                        child: ListTile(
                          title: Text(lang),
                          trailing: const Icon(Icons.translate),
                          onTap: () => handleTranslate(lang),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const Divider(),

                const Text(
                  "🔊 Voice Language (Separate Feature)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                DropdownButton<String>(
                  value: selectedVoiceLang,
                  isExpanded: true,
                  items: const [
                    "English",
                    "Urdu",
                    "Punjabi",
                    "Pashto",
                  ]
                      .map(
                        (lang) => DropdownMenuItem(
                      value: lang,
                      child: Text(lang),
                    ),
                  )
                      .toList(),
                  onChanged: (val) {
                    setState(() => selectedVoiceLang = val!);
                  },
                ),
              ],
            ),
          ),

          // 🔄 LOADING
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}