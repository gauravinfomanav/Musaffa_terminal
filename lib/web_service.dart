import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class WebService {
  static const String _typesenseUrl =
      'https://0bs2hegi5nmtad4op.a1.typesense.net';
  static const String _typesenseKey =
      'GRhZdTOnzVKId4Ln9G1PIvuIgn1TK0fH';
      
  // New Typesense instance for infomanav
  static const String _typesenseInfomanavUrl =
      'https://typesense.infomanav.in';
  static const String _typesenseInfomanavKey =
      'v0R3WozafhWeECu5MVuKr6HPcXI0hLPh';

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

  static Future<http.Response> getTypesense_infomanav(
      List<String> path, [Map<String, dynamic>? params]) async {
    final headers = {
      'X-TYPESENSE-API-KEY': _typesenseInfomanavKey,
      'Content-Type': 'application/json',
    };

    final uri = Uri.parse(_typesenseInfomanavUrl)
        .replace(pathSegments: path, queryParameters: params);

    try {
      final resp = await http.get(uri, headers: headers);
      return resp;
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  Future<http.Response> postTypeSense(
      List<String> path, String body, Map<String, dynamic>? params) async {
    var typesenseUrl = _typesenseUrl;
    var typesenseKey = _typesenseKey;

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
      'X-TYPESENSE-API-KEY': typesenseKey,
    };

    var requestUrl = Uri.parse(typesenseUrl)
        .replace(pathSegments: path, queryParameters: params);

    try {
      var resp = await http.post(requestUrl, headers: headers, body: body);

      return resp;
    } catch (_) {
      return Future(() {
        return http.Response('', 404);
      });
    }
  }
}
