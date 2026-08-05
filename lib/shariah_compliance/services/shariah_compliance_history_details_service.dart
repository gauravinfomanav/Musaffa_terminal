import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:musaffa_terminal/shariah_compliance/models/compliance_report_period.dart';
import 'package:musaffa_terminal/shariah_compliance/utils/nova_compliance_mapper.dart';

class ShariahComplianceHistoryDetailsService {
  static const String _endpoint =
      'https://novalive-api.musaffa.us/v3/api/get_compliance_history_details';

  Future<List<ComplianceReportPeriod>> fetchPeriods(String ticker) async {
    final String symbol = ticker.trim().toUpperCase();
    if (symbol.isEmpty) return const <ComplianceReportPeriod>[];

    try {
      final http.Response response = await http.post(
        Uri.parse(_endpoint),
        headers: const <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'symbol': symbol,
          'start_date': '',
          'end_date': '',
          'sort_by': '',
          'sort_order': '',
        }),
      );

      if (response.statusCode != 200) {
        return const <ComplianceReportPeriod>[];
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const <ComplianceReportPeriod>[];
      }

      final dynamic envelope = decoded['data'];
      if (envelope is! Map<String, dynamic>) {
        return const <ComplianceReportPeriod>[];
      }

      final dynamic rows = envelope['data'];
      if (rows is! List) {
        return const <ComplianceReportPeriod>[];
      }

      final List<Map<String, dynamic>> raw = rows
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

      return NovaComplianceMapper.toPeriods(raw);
    } catch (_) {
      return const <ComplianceReportPeriod>[];
    }
  }
}
