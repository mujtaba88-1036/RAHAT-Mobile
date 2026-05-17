import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://rahat-production.up.railway.app';

  static Future<Map<String, dynamic>> analyzeCrisis(List<dynamic> inputs) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'inputs': inputs, 'mode': 'manual'}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> autoScan() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auto-scan'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pipeline-status'));
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }
}
