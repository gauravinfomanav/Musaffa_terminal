import 'dart:convert';

import 'package:http/http.dart' as http;

class ShariahComplianceApiService {
  static const String _baseUrl =
      'https://0bs2hegi5nmtad4op.a1.typesense.net';
  static const String _apiKey = 'GRhZdTOnzVKId4Ln9G1PIvuIgn1TK0fH';
  static const String _collection = 'compliance_collection_3';
  static const String _etfCollection = 'etf_compliance_detailed_collection_2';

  Future<ShariahComplianceResult> fetchEtfCompliance(String symbol) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      return ShariahComplianceResult.error('ETF symbol is required.');
    }

    final Uri uri = Uri.parse(
      '$_baseUrl/collections/$_etfCollection/documents/$normalized',
    );

    try {
      final http.Response response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-TYPESENSE-API-KEY': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ShariahComplianceResult.success(decoded);
        }
        return ShariahComplianceResult.error('Unexpected response format.');
      }

      if (response.statusCode == 404) {
        return ShariahComplianceResult.error(
          'No compliance data found for $normalized.',
        );
      }

      return ShariahComplianceResult.error(
        'Request failed (${response.statusCode}).',
      );
    } catch (e) {
      return ShariahComplianceResult.error('Failed to load ETF compliance data.');
    }
  }

  Future<ShariahComplianceResult> fetchCompliance(String ticker) async {
    final String symbol = ticker.trim().toUpperCase();
    if (symbol.isEmpty) {
      return ShariahComplianceResult.error('Ticker symbol is required.');
    }

    final Uri uri = Uri.parse(
      '$_baseUrl/collections/$_collection/documents/$symbol',
    );

    try {
      final http.Response response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-TYPESENSE-API-KEY': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ShariahComplianceResult.success(decoded);
        }
        return ShariahComplianceResult.error('Unexpected response format.');
      }

      if (response.statusCode == 404) {
        return ShariahComplianceResult.error(
          'No compliance data found for $symbol.',
        );
      }

      return ShariahComplianceResult.error(
        'Request failed (${response.statusCode}).',
      );
    } catch (e) {
      return ShariahComplianceResult.error('Failed to load compliance data.');
    }
  }
}

class ShariahComplianceResult {
  const ShariahComplianceResult._({
    this.data,
    this.errorMessage,
  });

  final Map<String, dynamic>? data;
  final String? errorMessage;

  bool get isSuccess => data != null;

  factory ShariahComplianceResult.success(Map<String, dynamic> data) {
    return ShariahComplianceResult._(data: data);
  }

  factory ShariahComplianceResult.error(String message) {
    return ShariahComplianceResult._(errorMessage: message);
  }

  String get formattedJson {
    if (data == null) return '';
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}
