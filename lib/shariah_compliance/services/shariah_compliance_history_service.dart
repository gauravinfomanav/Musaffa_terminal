import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:musaffa_terminal/config/api_config.dart';
import 'package:musaffa_terminal/shariah_compliance/models/compliance_history_item.dart';

class ShariahComplianceHistoryService {
  static const String _baseUrl = ApiConfig.musaffaApiBaseUrl;
  // TODO: replace with authenticated token from app session
  static const String _bearerToken =
      '1390072|ogVcdCibKOntX4Km7dm2cXDxMqoLMB7v4OfBDHnW3a67dd49';

  Future<List<ComplianceHistoryItem>> fetchHistory(String ticker) async {
    final String symbol = ticker.trim().toUpperCase();
    if (symbol.isEmpty) return const <ComplianceHistoryItem>[];

    final Uri uri = Uri.parse('$_baseUrl/api/compliance-history/$symbol');

    try {
      final http.Response response = await http.get(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': 'Bearer $_bearerToken',
          'Content-Type': 'application/json',
          'Device-Type': 'web',
        },
      );

      if (response.statusCode != 200) {
        return const <ComplianceHistoryItem>[];
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const <ComplianceHistoryItem>[];
      }

      final dynamic data = decoded['data'];
      if (data is! List) {
        return const <ComplianceHistoryItem>[];
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(ComplianceHistoryItem.fromJson)
          .toList();
    } catch (_) {
      return const <ComplianceHistoryItem>[];
    }
  }
}
