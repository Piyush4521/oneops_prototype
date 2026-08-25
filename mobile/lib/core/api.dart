import 'dart:convert';
import 'package:http/http.dart' as http;

class OneOpsApi {
  // Android emulator -> host machine. For a physical phone, replace with the laptop LAN IP.
  static const baseUrl = String.fromEnvironment('ONEOPS_API', defaultValue: 'http://10.0.2.2:8787');

  static Future<Map<String, dynamic>> getState() async {
    final r = await http.get(Uri.parse('$baseUrl/api/state'));
    _ok(r);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> injectFailure() async {
    final r = await http.post(Uri.parse('$baseUrl/api/lab/inject-failure'));
    _ok(r); return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> investigate() async {
    final r = await http.post(Uri.parse('$baseUrl/api/incidents/investigate'));
    _ok(r); return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> reproduce() async {
    final r = await http.post(Uri.parse('$baseUrl/api/incidents/reproduce'));
    _ok(r); return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> verifyFix() async {
    final r = await http.post(Uri.parse('$baseUrl/api/incidents/verify-fix'));
    _ok(r); return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> approveAndRecover() async {
    final r = await http.post(Uri.parse('$baseUrl/api/incidents/approve-recover'));
    _ok(r); return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> capture({String? note, String? imageBase64}) async {
    final r = await http.post(Uri.parse('$baseUrl/api/incidents/capture'), headers: {'content-type':'application/json'}, body: jsonEncode({'note':note,'imageBase64':imageBase64}));
    _ok(r); return jsonDecode(r.body);
  }

  static void _ok(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) throw Exception('HTTP ${r.statusCode}: ${r.body}');
  }
}
