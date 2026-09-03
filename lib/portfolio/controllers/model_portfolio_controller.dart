import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/portfolio_controller.dart';
import 'package:musaffa_terminal/models/portfolio_model.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_enums.dart';
import 'package:musaffa_terminal/portfolio/services/portfolio_builder_session.dart';

class ModelPortfolioController extends GetxController {
  final PortfolioController _portfolioController = Get.put(PortfolioController());

  PortfolioController get portfolioController => _portfolioController;

  bool isModelPortfolio(PortfolioSummary summary) {
    return summary.clientName == kModelPortfolioClientMarker ||
        summary.clientName.trim().isEmpty;
  }

  List<PortfolioSummary> get publishedModels {
    return _portfolioController.activePortfolios
        .where(isModelPortfolio)
        .toList();
  }

  List<PortfolioSummary> get draftModels {
    return _portfolioController.draftPortfolios
        .where(isModelPortfolio)
        .toList();
  }

  Future<void> fetchModels() async {
    await _portfolioController.fetchActivePortfolios();
    await _portfolioController.fetchDraftPortfolios();
  }

  Future<Portfolio?> saveSessionAsDraft(PortfolioBuilderSession session) async {
    final holdings =
        session.holdings.map((h) => h.toApiHolding()).toList(growable: false);

    if (session.portfolioId != null) {
      return _portfolioController.updatePortfolio(
        portfolioId: session.portfolioId!,
        portfolioName: session.portfolioName,
        clientName: kModelPortfolioClientMarker,
        initialCapital: kModelApiNominalCapital,
        holdings: holdings,
        riskProfile: session.riskProfile,
        strategyType: session.strategyType,
        benchmark: session.benchmark,
        objective: session.objective,
        investmentHorizon: session.investmentHorizon,
        commentary: session.commentary,
        portfolioType: 'model',
      );
    }

    return _portfolioController.saveDraft(
      portfolioName: session.portfolioName,
      clientName: kModelPortfolioClientMarker,
      initialCapital: kModelApiNominalCapital,
      holdings: holdings,
      riskProfile: session.riskProfile,
      strategyType: session.strategyType,
      benchmark: session.benchmark,
      objective: session.objective,
      investmentHorizon: session.investmentHorizon,
      commentary: _mergeCommentary(session),
      portfolioType: 'model',
    );
  }

  Future<Portfolio?> publishSession(PortfolioBuilderSession session) async {
    if (!session.isAllocationValid) return null;

    final holdings =
        session.holdings.map((h) => h.toApiHolding()).toList(growable: false);

    if (session.portfolioId != null) {
      final updated = await _portfolioController.updatePortfolio(
        portfolioId: session.portfolioId!,
        portfolioName: session.portfolioName,
        clientName: kModelPortfolioClientMarker,
        initialCapital: kModelApiNominalCapital,
        holdings: holdings,
        riskProfile: session.riskProfile,
        strategyType: session.strategyType,
        benchmark: session.benchmark,
        objective: session.objective,
        investmentHorizon: session.investmentHorizon,
        commentary: _mergeCommentary(session),
        portfolioType: 'model',
      );
      if (updated != null && updated.status != 'active') {
        await _portfolioController.convertDraftToActive(session.portfolioId!);
      }
      return updated;
    }

    return _portfolioController.createPortfolio(
      portfolioName: session.portfolioName,
      clientName: kModelPortfolioClientMarker,
      initialCapital: kModelApiNominalCapital,
      holdings: holdings,
      riskProfile: session.riskProfile,
      strategyType: session.strategyType,
      benchmark: session.benchmark,
      objective: session.objective,
      investmentHorizon: session.investmentHorizon,
      commentary: _mergeCommentary(session),
      portfolioType: 'model',
    );
  }

  String _mergeCommentary(PortfolioBuilderSession session) {
    final parts = <String>[];
    if (session.portfolioCode.isNotEmpty) {
      parts.add('Code: ${session.portfolioCode}');
    }
    if (session.marketOutlook.isNotEmpty) {
      parts.add('Outlook: ${session.marketOutlook}');
    }
    if (session.commentary.isNotEmpty) {
      parts.add(session.commentary);
    }
    return parts.join('\n\n');
  }
}
