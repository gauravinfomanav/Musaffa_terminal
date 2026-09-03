import 'package:get/get.dart';
import 'package:musaffa_terminal/models/portfolio_model.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_enums.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_holding.dart';
import 'package:musaffa_terminal/portfolio/utils/allocation_format.dart';

/// In-memory draft for model portfolio builder + screener handoff.
class PortfolioBuilderSession extends GetxService {
  String? portfolioId;
  String portfolioName = '';
  String portfolioCode = '';
  String strategyType = 'Balanced';
  String riskProfile = 'Moderate';
  String investmentHorizon = '5 Years';
  String benchmark = 'NIFTY 50';
  String objective = '';
  String marketOutlook = '';
  String commentary = '';
  int version = 1;
  ModelPortfolioStatus status = ModelPortfolioStatus.draft;

  final RxList<ModelPortfolioHolding> holdings = <ModelPortfolioHolding>[].obs;
  final RxBool screenerReturnPending = false.obs;

  double get totalAllocationPercent =>
      holdings.fold(0.0, (sum, h) => sum + h.targetPercent);

  double get remainingPercent =>
      allocationRemainingPercent(totalAllocationPercent);

  bool get isAllocationValid =>
      isAllocationBalanced(totalAllocationPercent) && holdings.isNotEmpty;

  bool get isOverAllocated => isAllocationOver(totalAllocationPercent);

  void clear() {
    portfolioId = null;
    portfolioName = '';
    portfolioCode = '';
    strategyType = 'Balanced';
    riskProfile = 'Moderate';
    investmentHorizon = '5 Years';
    benchmark = 'NIFTY 50';
    objective = '';
    marketOutlook = '';
    commentary = '';
    version = 1;
    status = ModelPortfolioStatus.draft;
    holdings.clear();
    screenerReturnPending.value = false;
  }

  void loadFromPortfolio(Portfolio portfolio) {
    portfolioId = portfolio.id;
    portfolioName = portfolio.portfolioName;
    portfolioCode = portfolio.portfolioCode ?? '';
    strategyType = portfolio.strategyType ?? 'Balanced';
    riskProfile = portfolio.riskProfile ?? 'Moderate';
    investmentHorizon = portfolio.investmentHorizon ?? '5 Years';
    benchmark = portfolio.benchmark ?? 'NIFTY 50';
    objective = portfolio.objective ?? '';
    marketOutlook = portfolio.marketOutlook ?? '';
    commentary = portfolio.commentary ?? '';
    version = portfolio.version ?? 1;
    status = ModelPortfolioStatus.fromApi(portfolio.status);
    holdings.assignAll(
      portfolio.holdings.map(ModelPortfolioHolding.fromPortfolioHolding),
    );
  }

  void addOrUpdateHolding(ModelPortfolioHolding holding) {
    final idx = holdings.indexWhere(
      (h) => h.ticker.toUpperCase() == holding.ticker.toUpperCase(),
    );
    if (idx >= 0) {
      holdings[idx] = holding;
    } else {
      holdings.add(holding);
    }
    holdings.refresh();
  }

  void removeHolding(String ticker) {
    holdings.removeWhere(
      (h) => h.ticker.toUpperCase() == ticker.toUpperCase(),
    );
    holdings.refresh();
  }

  static PortfolioBuilderSession ensureRegistered() {
    if (Get.isRegistered<PortfolioBuilderSession>()) {
      return Get.find<PortfolioBuilderSession>();
    }
    return Get.put(PortfolioBuilderSession(), permanent: true);
  }
}
