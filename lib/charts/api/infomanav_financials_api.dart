import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:musaffa_terminal/charts/models/financial_statement_type.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/charts/models/stock_quarterly_financials.dart';
import 'package:musaffa_terminal/config/infomanav_api_config.dart';

class InfomanavApiException implements Exception {
  InfomanavApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reusable client for Infomanav px_master.php Finnhub proxy endpoints.
class InfomanavFinancialsApi {
  const InfomanavFinancialsApi();

  static const Duration _quarterPriceBuffer = Duration(days: 7);

  /// Quarterly financials (`statement=ic|bs|cf`, `freq=quarterly`).
  Future<StockQuarterlyFinancialsResponse> fetchQuarterlyFinancials(
    String symbol,
    FinancialStatementType statement,
  ) async {
    final Uri uri = Uri.parse(InfomanavApiConfig.baseUrl).replace(
      queryParameters: <String, String>{
        'api': 'stock/financials',
        'symbol': symbol.trim().toUpperCase(),
        'statement': statement.apiValue,
        'freq': 'quarterly',
      },
    );

    final http.Response response = await http.get(
      uri,
      headers: const <String, String>{
        HttpHeaders.acceptHeader: 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InfomanavApiException(
        'Financials request failed (${response.statusCode})',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw InfomanavApiException('Unexpected financials response format');
    }

    return StockQuarterlyFinancialsResponse.fromJson(decoded);
  }

  /// Quarterly income statement (`statement=ic`, `freq=quarterly`).
  Future<StockQuarterlyFinancialsResponse> fetchQuarterlyIncomeStatement(
    String symbol,
  ) {
    return fetchQuarterlyFinancials(symbol, FinancialStatementType.ic);
  }

  /// Daily candles for the visible quarterly range.
  Future<List<PriceDataPoint>> fetchDailyPriceSeries(
    String symbol, {
    required DateTime from,
    required DateTime to,
  }) async {
    final DateTime start = from.toUtc().subtract(_quarterPriceBuffer);
    final DateTime end = to.toUtc().add(_quarterPriceBuffer);

    final Uri uri = Uri.parse(InfomanavApiConfig.baseUrl).replace(
      queryParameters: <String, String>{
        'api': 'stock/candle',
        'symbol': symbol.trim().toUpperCase(),
        'resolution': 'D',
        'from': (start.millisecondsSinceEpoch ~/ 1000).toString(),
        'to': (end.millisecondsSinceEpoch ~/ 1000).toString(),
      },
    );

    final http.Response response = await http.get(
      uri,
      headers: const <String, String>{
        HttpHeaders.acceptHeader: 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InfomanavApiException(
        'Price request failed (${response.statusCode})',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw InfomanavApiException('Unexpected price response format');
    }

    if (decoded['s'] != 'ok') {
      throw InfomanavApiException('No price data available for chart overlay');
    }

    final List<dynamic> closes = decoded['c'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> timestamps =
        decoded['t'] as List<dynamic>? ?? <dynamic>[];

    final int count = closes.length < timestamps.length
        ? closes.length
        : timestamps.length;

    final List<PriceDataPoint> priceData = <PriceDataPoint>[];
    for (int index = 0; index < count; index++) {
      final dynamic closeRaw = closes[index];
      final dynamic timestampRaw = timestamps[index];
      if (closeRaw is! num || timestampRaw is! num) {
        continue;
      }
      priceData.add(
        PriceDataPoint(
          date: DateTime.fromMillisecondsSinceEpoch(
            timestampRaw.toInt() * 1000,
            isUtc: true,
          ).toLocal(),
          value: closeRaw.toDouble(),
        ),
      );
    }

    return priceData;
  }
}
