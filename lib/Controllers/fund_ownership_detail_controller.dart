import 'package:flutter/foundation.dart';
import 'package:musaffa_terminal/models/fund_ownership_model.dart';
import 'package:musaffa_terminal/models/institutional_investor_model.dart';
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

  bool get isLoading => _isLoading;
  String? get error => _error;
  InstitutionalInvestorProfile? get profile => _profile;
  InstitutionalPortfolioSnapshot? get portfolio => _portfolio;
  List<InstitutionalHolding> get holdings =>
      _portfolio?.holdings ?? const <InstitutionalHolding>[];

  Future<void> load({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _service.matchProfile(fund.name);

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
}
