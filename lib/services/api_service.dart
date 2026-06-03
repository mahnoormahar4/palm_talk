// FIXED: http ^1.x changes — Uri.parse() is now required (was already used),
// and response body is now a String directly. No API breaking changes for
// basic GET/POST usage, but the package import is the same.
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {

  final String baseUrl;

  ApiService({required this.baseUrl});

  /// POST request — returns decoded JSON map or null on error.
  Future<Map<String, dynamic>?> post(
      String endpoint,
      Map<String, dynamic> body,
      ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// GET request — returns decoded JSON or null on error.
  Future<dynamic> get(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
