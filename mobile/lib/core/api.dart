import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OneOpsApi {
  static const _configuredBaseUrl = String.fromEnvironment('ONEOPS_API');

  // Android emulator -> host machine for local mobile dev. Web release builds
  // should pass --dart-define=ONEOPS_API=https://your-backend.example.
  static final baseUrl = _configuredBaseUrl.isNotEmpty
      ? _configuredBaseUrl
      : kIsWeb
          ? Uri.base.origin
          : 'http://10.0.2.2:8787';

  static Future<Map<String, dynamic>> getState() async {
    final r = await http.get(Uri.parse('$baseUrl/api/state'));
    _ok(r);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> injectFailure() async {
    final r = await http.post(Uri.parse('$baseUrl/api/lab/inject-failure'));
    _ok(r);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> investigate() async {
    final r = await http.post(Uri.parse('$baseUrl/api/incidents/investigate'));
    _ok(r);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> reproduce() async {
    final r = await http.post(Uri.parse('$baseUrl/api/incidents/reproduce'));
    _ok(r);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> verifyFix() async {
    final r = await http.post(Uri.parse('$baseUrl/api/incidents/verify-fix'));
    _ok(r);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> approveAndRecover() async {
    final r =
        await http.post(Uri.parse('$baseUrl/api/incidents/approve-recover'));
    _ok(r);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> capture(
      {String? note, String? imageBase64}) async {
    final r = await http.post(Uri.parse('$baseUrl/api/incidents/capture'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'note': note, 'imageBase64': imageBase64}));
    _ok(r);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> requestCodeContext(
      {required String component, required String path}) async {
    final r = await http.post(Uri.parse('$baseUrl/api/incidents/code-context'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'component': component, 'path': path}));
    _ok(r);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> requestRagContext(
      {required String query, required String codeContext}) async {
    final r = await http.post(Uri.parse('$baseUrl/api/incidents/rag-context'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'query': query, 'codeContext': codeContext}));
    _ok(r);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> requestDiagnosis({
    required Map<String, dynamic> incident,
    required Map<String, dynamic> codeContext,
    required List<Map<String, dynamic>> ragResults,
  }) async {
    final r = await http.post(Uri.parse('$baseUrl/api/incidents/diagnose'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'incident': incident,
          'codeContext': codeContext,
          'ragResults': ragResults,
        }));
    _ok(r);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> requestFixProposal({
    required Map<String, dynamic> diagnosis,
    required Map<String, dynamic> codeContext,
    required Map<String, dynamic> incident,
    required List<Map<String, dynamic>> ragResults,
  }) async {
    final r = await http.post(Uri.parse('$baseUrl/api/incidents/propose-fix'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'diagnosis': diagnosis,
          'codeContext': codeContext,
          'incident': incident,
          'ragResults': ragResults,
        }));
    _ok(r);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> createPullRequest({
    required Map<String, dynamic> incident,
    required Map<String, dynamic> proposal,
    required Map<String, dynamic> codeContext,
  }) async {
    final r = await http.post(Uri.parse('$baseUrl/api/incidents/create-pr'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'incident': incident,
          'proposal': proposal,
          'codeContext': codeContext,
        }));
    _ok(r);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> evaluateChangeGate({
    required Map<String, dynamic> pr,
    required Map<String, dynamic> incident,
    required Map<String, dynamic> policy,
  }) async {
    final r = await http.post(Uri.parse('$baseUrl/api/incidents/change-gate'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'pr': pr,
          'incident': incident,
          'policy': policy,
        }));
    _ok(r);
    return jsonDecode(r.body);
  }

  static void _ok(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('HTTP ${r.statusCode}: ${r.body}');
    }
  }
}
