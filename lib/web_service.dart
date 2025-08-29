import 'dart:convert';
import 'package:http/http.dart' as http;

class WebService {
  static const String _typesenseUrl =
      'https://0bs2hegi5nmtad4op.a1.typesense.net';
  static const String _typesenseKey =
      'GRhZdTOnzVKId4Ln9G1PIvuIgn1TK0fH';

  static Future<http.Response> getTypesense(
      List<String> path, [Map<String, dynamic>? params]) async {
    final headers = {
      'X-TYPESENSE-API-KEY': _typesenseKey,
      'Content-Type': 'application/json',
    };

    final uri = Uri.parse(_typesenseUrl)
        .replace(pathSegments: path, queryParameters: params);

    try {
      final resp = await http.get(uri, headers: headers);
      return resp;
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }
}
