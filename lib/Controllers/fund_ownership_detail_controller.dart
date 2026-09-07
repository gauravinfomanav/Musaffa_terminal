import 'package:flutter/foundation.dart';
import 'package:musaffa_terminal/Controllers/search_service.dart';
import 'package:musaffa_terminal/models/fund_ownership_model.dart';
import 'package:musaffa_terminal/models/institutional_investor_model.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/services/finnhub/institutional_investor_service.dart';

class FundOwnershipDetailController extends ChangeNotifier {
  FundOwnershipDetailController({
    required this.fund,
    required this.holdingSymbol,
    required this.holdingName,
    this.currentPrice,
    InstitutionalInvestorService? service,
  }) : _service = service ?? InstitutionalInvestorService();

  final FundOwnershipModel fund;
  final String holdingSymbol;
  final String holdingName;
  final double? currentPrice;
  final InstitutionalInvestorService _service;

  bool _isLoading = true;
  String? _error;
  InstitutionalInvestorProfile? _profile;
  InstitutionalPortfolioSnapshot? _portfolio;
  List<TickerModel> _relatedTickers = <TickerModel>[];

  bool get isLoading => _isLoading;
  String? get error => _error;
  InstitutionalInvestorProfile? get profile => _profile;
  InstitutionalPortfolioSnapshot? get portfolio => _portfolio;
  List<TickerModel> get relatedTickers => _relatedTickers;
  List<InstitutionalHolding> get holdings =>
      _portfolio?.holdings ?? const <InstitutionalHolding>[];

  Future<void> load({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<Object?> results = await Future.wait<Object?>(<Future<Object?>>[
        _service.matchProfile(fund.name),
        _searchRelatedTickers(),
      ]);

      _profile = results[0] as InstitutionalInvestorProfile?;
      _relatedTickers = (results[1] as List<TickerModel>?) ?? <TickerModel>[];

      final String? cik = _profile?.cik.isNotEmpty == true
          ? _profile!.cik
          : fund.cik;
      if (cik != null && cik.trim().isNotEmpty) {
        try {
          _portfolio = await _service.fetchPortfolio(cik);
        } catch (_) {
          _portfolio = null;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<TickerModel>> _searchRelatedTickers() async {
    final Set<String> seen = <String>{holdingSymbol.trim().toUpperCase()};
    final List<TickerModel> merged = <TickerModel>[];

    Future<void> addQuery(String query) async {
      if (query.trim().isEmpty) return;
      final List<TickerModel> results = await SearchService.searchStocks(query);
      for (final TickerModel ticker in results) {
        final String symbol =
            (ticker.symbol ?? ticker.ticker ?? '').trim().toUpperCase();
        if (symbol.isEmpty || seen.contains(symbol)) continue;
        seen.add(symbol);
        merged.add(ticker);
      }
    }

    if ((fund.symbol ?? '').trim().isNotEmpty) {
      await addQuery(fund.symbol!);
    }
    await addQuery(_searchQuery(fund.name));

    if (merged.length <= 20) return merged;
    return merged.take(20).toList();
  }

  static String _searchQuery(String name) {
    final String cleaned = name
        .replaceAll(RegExp(r'[,.]'), ' ')
        .replaceAll(
          RegExp(
            r'\b(the|inc|incorporated|corp|corporation|llc|lp|ltd|limited|co|company|group|holdings|n/?a)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return name.trim();
    final List<String> parts = cleaned.split(' ');
    if (parts.length == 1) return parts.first;
    return parts.take(2).join(' ');
  }
}
