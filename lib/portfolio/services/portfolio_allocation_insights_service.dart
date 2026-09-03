import 'package:musaffa_terminal/models/basic_financials_model.dart';
import 'package:musaffa_terminal/models/stock_profile_model.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_enums.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_holding.dart';
import 'package:musaffa_terminal/portfolio/models/portfolio_allocation_insights.dart';
import 'package:musaffa_terminal/services/finnhub/basic_financials_service.dart';
import 'package:musaffa_terminal/services/finnhub/stock_profile_service.dart';

/// Loads Finnhub market cap / volume snapshots for model portfolio holdings.
class PortfolioAllocationInsightsService {
  PortfolioAllocationInsightsService({
    StockProfileService? profileService,
    BasicFinancialsService? financialsService,
  })  : _profileService = profileService ?? StockProfileService(),
        _financialsService = financialsService ?? BasicFinancialsService();

  final StockProfileService _profileService;
  final BasicFinancialsService _financialsService;

  Future<PortfolioAllocationInsights> load(
    List<ModelPortfolioHolding> holdings,
  ) async {
    final eligible = holdings
        .where(
          (h) =>
              h.targetPercent > 0 &&
              ModelPortfolioHolding.isSearchableAsset(h.assetType),
        )
        .toList();

    if (eligible.isEmpty) {
      return PortfolioAllocationInsights.empty;
    }

    final snapshots = <PortfolioHoldingMarketData>[];
    var loaded = 0;

    for (final holding in eligible) {
      final snapshot = await _loadHolding(holding);
      snapshots.add(snapshot);
      if (snapshot.marketCapMillions != null || snapshot.avgDailyVolume != null) {
        loaded++;
      }
    }

    double capWeight = 0;
    double capSum = 0;
    double volWeight = 0;
    double volSum = 0;
    double peWeight = 0;
    double peSum = 0;
    double divWeight = 0;
    double divSum = 0;

    for (var i = 0; i < eligible.length; i++) {
      final weight = eligible[i].targetPercent;
      if (weight <= 0) continue;

      final cap = snapshots[i].marketCapMillions ??
          _holdingMarketCapMillions(eligible[i]);
      if (cap != null && cap > 0) {
        capSum += weight * cap;
        capWeight += weight;
      }

      final vol = snapshots[i].avgDailyVolume;
      if (vol != null && vol > 0) {
        volSum += weight * vol;
        volWeight += weight;
      }

      final pe = snapshots[i].peTTM;
      if (pe != null && pe > 0) {
        peSum += weight * pe;
        peWeight += weight;
      }

      final div = snapshots[i].dividendYield;
      if (div != null && div >= 0) {
        divSum += weight * div;
        divWeight += weight;
      }
    }

    return PortfolioAllocationInsights(
      holdingData: snapshots,
      weightedAvgMarketCapMillions:
          capWeight > 0 ? capSum / capWeight : null,
      weightedAvgDailyVolume: volWeight > 0 ? volSum / volWeight : null,
      weightedAvgPe: peWeight > 0 ? peSum / peWeight : null,
      weightedAvgDividendYield: divWeight > 0 ? divSum / divWeight : null,
      finnhubLoadedCount: loaded,
      finnhubEligibleCount: eligible.length,
    );
  }

  Future<PortfolioHoldingMarketData> _loadHolding(
    ModelPortfolioHolding holding,
  ) async {
    final ticker = holding.ticker.trim().toUpperCase();
    StockProfileModel? profile;
    BasicFinancialsModel? financials;

    try {
      profile = await _profileService.fetchProfile2(ticker);
    } catch (_) {}

    try {
      financials = await _financialsService.fetchAll(ticker);
    } catch (_) {}

    return PortfolioHoldingMarketData(
      ticker: ticker,
      marketCapMillions: profile?.marketCapitalization?.toDouble(),
      avgDailyVolume: _extractAvgVolume(financials),
      industry: profile?.finnhubIndustry?.trim(),
      peTTM: _extractPe(financials),
      dividendYield: _extractDividendYield(financials),
      country: profile?.country?.trim(),
    );
  }

  double? _extractPe(BasicFinancialsModel? financials) {
    if (financials == null) return null;
    const keys = <String>['peTTM', 'peBasicExclExtraTTM', 'peNormalizedAnnual'];
    for (final key in keys) {
      final value = financials.metricNum(key);
      if (value != null && value > 0) return value.toDouble();
    }
    return null;
  }

  double? _extractDividendYield(BasicFinancialsModel? financials) {
    if (financials == null) return null;
    const keys = <String>[
      'dividendYieldIndicatedAnnual',
      'currentDividendYieldTTM',
      'dividendYield',
    ];
    for (final key in keys) {
      final value = financials.metricNum(key);
      if (value != null && value >= 0) return value.toDouble();
    }
    return null;
  }

  double? _holdingMarketCapMillions(ModelPortfolioHolding holding) {
    final cap = holding.marketCap;
    if (cap == null || cap <= 0) return null;
    if (holding.assetType == ModelAssetType.etf) {
      return cap / 1e6;
    }
    return cap;
  }

  double? _extractAvgVolume(BasicFinancialsModel? financials) {
    if (financials == null) return null;
    const keys = <String>[
      '10DayAverageTradingVolume',
      '3MonthAverageTradingVolume',
      'volume',
    ];
    for (final key in keys) {
      final value = financials.metricNum(key);
      if (value != null && value > 0) return value.toDouble();
    }
    return null;
  }
}
