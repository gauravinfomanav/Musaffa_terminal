import 'dart:convert';
import 'package:musaffa_terminal/models/super_investor_model.dart';
import 'package:musaffa_terminal/web_service.dart';

class SuperInvestorService {
  static final SuperInvestorService _instance = SuperInvestorService._internal();

  factory SuperInvestorService() {
    return _instance;
  }

  SuperInvestorService._internal();

  /// Fetch portfolio data filtered by stock symbol
  Future<List<SuperInvestorPortfolio>> fetchPortfolioBySymbol(String symbol) async {
    try {
      final queryParams = {
        'q': '*',
        'filter_by': 'symbol:=[$symbol]',
        'per_page': '250',
        'page': '1',
        'sort_by': 'value:desc',
      };

      final response = await WebService.getTypesense(
        ['collections', 'super_investors_portfolio', 'documents', 'search'],
        queryParams,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> hits = data['hits'] ?? [];
        print('🟢 SuperInvestor: Portfolio hits=${hits.length}');

        return hits
            .map((hit) => SuperInvestorPortfolio.fromJson(hit['document']))
            .toList();
      } else {
        throw Exception(
            'Failed to fetch portfolio data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching portfolio data: $e');
    }
  }

  /// Fetch investor names using cik values
  Future<List<SuperInvestor>> fetchInvestorsByCik(List<String> cikIds) async {
    if (cikIds.isEmpty) {
      return [];
    }

    try {
      // Build filter with proper Typesense syntax for multiple values
      final cikValues = cikIds.join(', ');
      final queryParams = {
        'q': '*',
        'filter_by': 'cik:=[$cikValues]',
        'per_page': '250',
      };

      final response = await WebService.getTypesense(
        ['collections', 'super_investors', 'documents', 'search'],
        queryParams,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> hits = data['hits'] ?? [];
        print('🟢 SuperInvestor: Investor hits=${hits.length}');

        return hits
            .map((hit) => SuperInvestor.fromJson(hit['document']))
            .toList();
      } else {
        throw Exception(
            'Failed to fetch investors data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching investors data: $e');
    }
  }

  /// Fetch and merge super investor data for a given symbol
  Future<List<MergedSuperInvestor>> fetchMergedData(String symbol) async {
    try {
      // Step 1: Fetch portfolio data
      final portfolios = await fetchPortfolioBySymbol(symbol);

      if (portfolios.isEmpty) {
        return [];
      }

      // Step 2: Extract unique cik_id values
      final Set<String> cikSet = {};
      for (final portfolio in portfolios) {
        if (portfolio.cikId != null && portfolio.cikId!.isNotEmpty) {
          cikSet.add(portfolio.cikId!);
        }
      }

      if (cikSet.isEmpty) {
        return [];
      }

      // Step 3: Fetch investor names
      final investors = await fetchInvestorsByCik(cikSet.toList());

      // Step 4 & 5: Merge both responses
      final Map<String, SuperInvestor> investorMap = {};
      for (final investor in investors) {
        if (investor.cik != null) {
          investorMap[investor.cik!] = investor;
        }
      }

      final merged = <MergedSuperInvestor>[];
      for (final portfolio in portfolios) {
        if (portfolio.cikId != null && investorMap.containsKey(portfolio.cikId!)) {
          final investor = investorMap[portfolio.cikId!]!;
          merged.add(MergedSuperInvestor.merge(portfolio, investor));
        }
      }

      return merged;
    } catch (e) {
      throw Exception('Error merging super investor data: $e');
    }
  }
}
