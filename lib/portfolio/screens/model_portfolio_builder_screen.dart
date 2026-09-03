import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/global_fab_overlay.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Controllers/portfolio_controller.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/portfolio/controllers/model_portfolio_controller.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_holding.dart';
import 'package:musaffa_terminal/portfolio/services/model_portfolio_enrichment.dart';
import 'package:musaffa_terminal/portfolio/services/portfolio_builder_session.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/portfolio/widgets/add_to_portfolio_dialog.dart';
import 'package:musaffa_terminal/portfolio/widgets/model_allocation_panel.dart';
import 'package:musaffa_terminal/portfolio/widgets/model_analytics_panel.dart';
import 'package:musaffa_terminal/portfolio/widgets/model_holdings_table.dart';
import 'package:musaffa_terminal/Screens/screener_screen.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:musaffa_terminal/portfolio/widgets/add_asset_modal.dart';

class ModelPortfolioBuilderScreen extends StatefulWidget {
  const ModelPortfolioBuilderScreen({super.key, this.portfolioId});

  final String? portfolioId;

  @override
  State<ModelPortfolioBuilderScreen> createState() =>
      _ModelPortfolioBuilderScreenState();
}

class _ModelPortfolioBuilderScreenState extends State<ModelPortfolioBuilderScreen> {
  final _session = PortfolioBuilderSession.ensureRegistered();
  final _modelController = Get.put(ModelPortfolioController());
  final _watchlistService = Get.find<GlobalWatchlistService>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _objectiveController;

  String _strategy = 'Balanced';
  String _risk = 'Moderate';
  String _benchmark = 'NIFTY 50';
  bool _isLoading = false;
  bool _isSaving = false;

  static const _strategies = [
    'Growth',
    'Value',
    'Income',
    'Balanced',
    'Tactical',
    'Capital Preservation',
    'Custom',
  ];
  static const _risks = [
    'Conservative',
    'Moderate',
    'Balanced',
    'Aggressive',
    'Tactical',
    'Income',
  ];
  static const _benchmarks = [
    'NIFTY 50',
    'NIFTY 500',
    'S&P 500',
    'NASDAQ 100',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.modelPortfolio);
    }
    _nameController = TextEditingController(text: _session.portfolioName);
    _codeController = TextEditingController(text: _session.portfolioCode);
    _objectiveController = TextEditingController(text: _session.objective);
    _strategy = _session.strategyType;
    _risk = _session.riskProfile;
    _benchmark = _session.benchmark;

    if (widget.portfolioId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadPortfolio(widget.portfolioId!);
      });
    } else if (_session.screenerReturnPending.value) {
      _session.screenerReturnPending.value = false;
    }
  }

  Future<void> _loadPortfolio(String id) async {
    setState(() => _isLoading = true);
    try {
      final portfolio = await Get.find<PortfolioController>().getPortfolio(id);
      if (!mounted) return;
      if (portfolio != null) {
        _session.loadFromPortfolio(portfolio);
        _syncControllersFromSession();
        await enrichModelPortfolioHoldings(_session.holdings);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to load portfolio: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _syncControllersFromSession() {
    _nameController.text = _session.portfolioName;
    _codeController.text = _session.portfolioCode;
    _objectiveController.text = _session.objective;
    _strategy = _strategies.contains(_session.strategyType)
        ? _session.strategyType
        : 'Balanced';
    _risk = _risks.contains(_session.riskProfile)
        ? _session.riskProfile
        : 'Moderate';
    _benchmark = _benchmarks.contains(_session.benchmark)
        ? _session.benchmark
        : 'NIFTY 50';
    setState(() {});
  }

  void _syncSessionFromControllers() {
    _session.portfolioName = _nameController.text.trim();
    _session.portfolioCode = _codeController.text.trim();
    _session.objective = _objectiveController.text.trim();
    _session.strategyType = _strategy;
    _session.riskProfile = _risk;
    _session.benchmark = _benchmark;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _objectiveController.dispose();
    super.dispose();
  }

  void _toggleWatchlist() => _watchlistService.toggleWatchlist();

  Future<void> _openAddAsset() async {
    _syncSessionFromControllers();
    final portfolioName = _session.portfolioName.trim().isNotEmpty
        ? _session.portfolioName.trim()
        : 'Model Portfolio';

    await AddAssetModal.show(
      context: context,
      portfolioName: portfolioName,
      existingHoldings: () => _session.holdings.toList(),
      onAddTicker: _addTickerFromSearch,
      onAddManual: _addManualAsset,
    );
    if (mounted) setState(() {});
  }

  Future<bool> _addTickerFromSearch(TickerModel model) async {
    final symbol = (model.symbol ?? model.ticker ?? '').trim().toUpperCase();
    if (symbol.isEmpty) return false;

    if (_session.holdings.any(
      (h) => h.ticker.trim().toUpperCase() == symbol,
    )) {
      return false;
    }

    final holding = ModelPortfolioHolding.fromTicker(model);
    await enrichModelPortfolioHoldings([holding]);
    _session.addOrUpdateHolding(holding);
    if (mounted) setState(() {});
    return true;
  }

  Future<bool> _addManualAsset(ModelPortfolioHolding holding) async {
    _session.addOrUpdateHolding(holding);
    if (mounted) setState(() {});
    return true;
  }

  Future<void> _openScreener() async {
    _syncSessionFromControllers();
    _session.screenerReturnPending.value = true;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final tickersBefore = _session.holdings
        .map((h) => h.ticker.trim().toUpperCase())
        .toSet();
    await Get.to(() => const ScreenerScreen(portfolioPickMode: true));
    await enrichModelPortfolioHoldings(_session.holdings);
    if (!mounted) return;
    final added = _session.holdings
        .where((h) => !tickersBefore.contains(h.ticker.trim().toUpperCase()))
        .length;
    if (added > 0) {
      SnackBarUtils.showSuccess(
        context,
        'Added $added holding${added == 1 ? '' : 's'} to portfolio',
      );
    }
    setState(() {});
  }

  Future<void> _saveDraft() async {
    if (_nameController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Portfolio name is required');
      return;
    }
    _syncSessionFromControllers();
    setState(() => _isSaving = true);
    final result = await _modelController.saveSessionAsDraft(_session);
    setState(() => _isSaving = false);
    if (result != null) {
      _session.portfolioId = result.id;
      _session.loadFromPortfolio(result);
      _syncControllersFromSession();
      await enrichModelPortfolioHoldings(_session.holdings);
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Draft saved');
      await _modelController.fetchModels();
    } else if (mounted) {
      SnackBarUtils.showError(
        context,
        _modelController.portfolioController.saveError.value.isNotEmpty
            ? _modelController.portfolioController.saveError.value
            : 'Failed to save draft',
      );
    }
  }

  Future<void> _publish() async {
    if (_nameController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Portfolio name is required');
      return;
    }
    if (!_session.isAllocationValid) {
      SnackBarUtils.showError(
        context,
        'Allocation must equal 100% before publishing',
      );
      return;
    }
    _syncSessionFromControllers();
    setState(() => _isSaving = true);
    final result = await _modelController.publishSession(_session);
    setState(() => _isSaving = false);
    if (result != null) {
      _session.portfolioId = result.id;
      _session.loadFromPortfolio(result);
      _syncControllersFromSession();
      await enrichModelPortfolioHoldings(_session.holdings);
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Model portfolio published');
      await _modelController.fetchModels();
      if (mounted) Get.back();
    } else if (mounted) {
      SnackBarUtils.showError(
        context,
        _modelController.portfolioController.saveError.value.isNotEmpty
            ? _modelController.portfolioController.saveError.value
            : 'Failed to publish',
      );
    }
  }

  void _updateTargetPercent(ModelPortfolioHolding holding, double percent) {
    holding.targetPercent = percent;
    _session.holdings.refresh();
    setState(() {});
  }

  Future<void> _editHolding(ModelPortfolioHolding holding) async {
    final result = await showDialog<ModelPortfolioHolding>(
      context: context,
      builder: (ctx) => AddToPortfolioDialog(
        ticker: holding.ticker,
        tickerModel: holding.tickerModel,
      ),
    );
    if (result != null) {
      result.id = holding.id;
      _session.addOrUpdateHolding(result);
      setState(() {});
    }
  }

  void _removeHolding(ModelPortfolioHolding holding) {
    _session.removeHolding(holding.ticker);
    setState(() {});
  }

  Future<void> _replaceHolding(ModelPortfolioHolding holding) async {
    _syncSessionFromControllers();
    _session.screenerReturnPending.value = true;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final tickersBefore = _session.holdings
        .map((h) => h.ticker.trim().toUpperCase())
        .toSet();
    await Get.to(() => ScreenerScreen(
          portfolioPickMode: true,
          replaceTicker: holding.ticker,
        ));
    await enrichModelPortfolioHoldings(_session.holdings);
    if (!mounted) return;
    final added = _session.holdings
        .where((h) => !tickersBefore.contains(h.ticker.trim().toUpperCase()))
        .length;
    if (added > 0) {
      SnackBarUtils.showSuccess(context, 'Holding replaced');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FeatureGuard(
      featureKey: FeatureKeys.portfolios,
      child: Scaffold(
        backgroundColor: HomeUi.pageBg(isDark),
        body: Stack(
          children: [
            Column(
              children: [
                Obx(() => HomeTabBar(
                      showBackButton: true,
                      isWatchlistOpen: _watchlistService.isWatchlistOpen.value,
                      onWatchlistToggle: _toggleWatchlist,
                      onThemeToggle: () {
                        Get.changeThemeMode(
                          isDark ? ThemeMode.light : ThemeMode.dark,
                        );
                      },
                    )),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: HomeUi.accent(isDark),
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Padding(
                            padding: LayoutConstants.screenPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(isDark),
                                const SizedBox(height: 20),
                                _buildInfoSection(isDark),
                                const SizedBox(height: 20),
                                _buildHoldingsAndAllocationSection(isDark),
                                const SizedBox(height: 20),
                                Obx(
                                  () => ModelAnalyticsPanel(
                                    isDark: isDark,
                                    holdings: _session.holdings.toList(),
                                    totalPercent: _session.totalAllocationPercent,
                                    benchmarkLabel: _session.benchmark,
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
            Obx(() {
              if (!_watchlistService.isWatchlistOpen.value) {
                return const SizedBox.shrink();
              }
              return Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: WatchlistSidebar(
                  isDarkMode: isDark,
                  onClose: () => _watchlistService.closeWatchlist(),
                ),
              );
            }),
            const GlobalFABOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Model Portfolio', style: HomeUi.heading(isDark)),
              const SizedBox(height: 4),
              Text(
                'Define the investment strategy, asset allocation, holdings and research.',
                style: HomeUi.subtitle(isDark),
              ),
            ],
          ),
        ),
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        HomeUi.ghostAction(
          label: 'Save Draft',
          icon: Icons.save_outlined,
          dark: isDark,
          onTap: _isSaving ? null : _saveDraft,
        ),
        const SizedBox(width: 8),
        HomeUi.primaryAction(
          label: 'Publish Portfolio',
          icon: Icons.publish_rounded,
          onTap: _isSaving ? () {} : _publish,
        ),
      ],
    );
  }

  Widget _buildInfoSection(bool isDark) {
    return Container(
      decoration: HomeUi.cardDecoration(isDark),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Portfolio Information', style: HomeUi.sectionTitle(isDark)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 720;
              return Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(isDark, _nameController, 'Portfolio Name',
                        hint: 'Balanced Growth'),
                  ),
                  if (wide) const SizedBox(width: 16),
                  if (!wide) const SizedBox(height: 12),
                  Expanded(
                    child: _field(isDark, _codeController, 'Portfolio Code',
                        hint: 'BG-001'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 900;
              return Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                children: [
                  Expanded(
                    child: _dropdown(isDark, 'Strategy Type', _strategy,
                        _strategies, (v) => setState(() => _strategy = v)),
                  ),
                  if (wide) const SizedBox(width: 12),
                  if (!wide) const SizedBox(height: 12),
                  Expanded(
                    child: _dropdown(isDark, 'Risk Profile', _risk, _risks,
                        (v) => setState(() => _risk = v)),
                  ),
                  if (wide) const SizedBox(width: 12),
                  if (!wide) const SizedBox(height: 12),
                  Expanded(
                    child: _dropdown(isDark, 'Benchmark', _benchmark,
                        _benchmarks, (v) => setState(() => _benchmark = v)),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          FilterTextField(
            dark: isDark,
            label: 'Objective',
            controller: _objectiveController,
            hintText:
                'Long-term wealth creation through diversified exposure…',
            minLines: 3,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingsAndAllocationSection(bool isDark) {
    final holdings = _session.holdings.toList();
    final totalPercent = _session.totalAllocationPercent;
    const sectionMinHeight = 560.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 960;

        final holdingsPanel = ModelHoldingsTable(
          isDark: isDark,
          holdings: holdings,
          totalPercent: totalPercent,
          onEdit: _editHolding,
          onRemove: _removeHolding,
          onReplace: _replaceHolding,
          onOpenScreener: _openScreener,
          onTargetPercentChanged: _updateTargetPercent,
          onAddAsset: _openAddAsset,
        );

        final allocationPanel = ModelAllocationPanel(
          isDark: isDark,
          holdings: holdings,
          totalPercent: totalPercent,
        );

        if (isWide) {
          return SizedBox(
            height: sectionMinHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 7, child: holdingsPanel),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: allocationPanel),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: sectionMinHeight * 0.65, child: holdingsPanel),
            const SizedBox(height: 20),
            SizedBox(height: sectionMinHeight * 0.55, child: allocationPanel),
          ],
        );
      },
    );
  }

  Widget _field(
    bool isDark,
    TextEditingController controller,
    String label, {
    String? hint,
  }) {
    return FilterTextField(
      dark: isDark,
      label: label,
      controller: controller,
      hintText: hint,
    );
  }

  Widget _dropdown(
    bool isDark,
    String label,
    String value,
    List<String> items,
    void Function(String) onChanged,
  ) {
    return FilterDropdown<String>(
      dark: isDark,
      label: label,
      value: value,
      items: items
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
