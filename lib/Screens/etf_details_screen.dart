import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/add_to_watchlist_button.dart';
import 'package:musaffa_terminal/Components/simple_news_widget.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Components/trading_view_widget.dart';
import 'package:musaffa_terminal/Components/global_fab_overlay.dart';
import 'package:musaffa_terminal/Components/research_notes_panel_content.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Controllers/etf_details_controller.dart';
import 'package:musaffa_terminal/Controllers/research_notes_controller.dart';
import 'package:musaffa_terminal/Controllers/trading_view_controller.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/models/etfs_data.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';

class EtfDetailsScreen extends StatefulWidget {
  final TickerModel ticker;

  const EtfDetailsScreen({
    Key? key,
    required this.ticker,
  }) : super(key: key);

  @override
  State<EtfDetailsScreen> createState() => _EtfDetailsScreenState();
}

class _EtfDetailsScreenState extends State<EtfDetailsScreen> {
  late WatchlistController watchlistController;
  late EtfDetailsController controller;
  late TradingViewController tradingViewController;
  late ResearchNotesController researchNotesController;
  final GlobalWatchlistService _watchlistService =
      Get.find<GlobalWatchlistService>();
  bool _isInWatchlist = false;
  bool _isResearchNotesOpen = false;
  StreamSubscription<dynamic>? _watchlistStocksSubscription;

  @override
  void initState() {
    super.initState();
    watchlistController = Get.put(WatchlistController());
    controller = Get.put(EtfDetailsController());
    tradingViewController = TradingViewController();
    researchNotesController = Get.put(ResearchNotesController());

    _watchlistStocksSubscription =
        watchlistController.watchlistStocks.listen((_) {
      _checkIfInWatchlist();
    });
    _checkIfInWatchlist();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchEtfDetails(widget.ticker.symbol ?? '');
      controller.fetchEtfHoldings(widget.ticker.symbol ?? '');
      if ((widget.ticker.symbol ?? '').isNotEmpty) {
        researchNotesController.fetchNotes(widget.ticker.symbol!);
      }
    });
  }

  @override
  void dispose() {
    _watchlistStocksSubscription?.cancel();
    tradingViewController.dispose();
    super.dispose();
  }

  void _checkIfInWatchlist() {
    final String currentTicker = widget.ticker.symbol ?? '';
    final bool isInCurrentWatchlist = watchlistController.watchlistStocks
        .any((stock) => stock.ticker == currentTicker);

    if (!mounted) return;
    setState(() {
      _isInWatchlist = isInCurrentWatchlist;
    });
  }

  void _showSuccessSnackBar(String message) {
    SnackBarUtils.showSuccess(context, message);
  }

  void _showErrorSnackBar(String message) {
    SnackBarUtils.showError(context, message);
  }

  Future<void> _openResearchNotesPanel() async {
    final ticker = widget.ticker.symbol ?? '';
    if (ticker.isNotEmpty) {
      await researchNotesController.fetchNotes(ticker);
    }
    if (!mounted) return;
    setState(() => _isResearchNotesOpen = true);
  }

  void _closeResearchNotesPanel() {
    if (!_isResearchNotesOpen || !mounted) return;
    setState(() => _isResearchNotesOpen = false);
  }

  void _toggleWatchlist() {
    if (!_watchlistService.isWatchlistOpen.value) {
      watchlistController.resetToDefaultWatchlist();
    }
    _watchlistService.toggleWatchlist();
  }

  String _formatSymbolForTradingView(EtfsData etfData) {
    final symbol = widget.ticker.symbol ?? etfData.symbol ?? '';

    // If symbol already has exchange prefix, return as-is
    if (symbol.contains(':')) {
      return symbol;
    }

    // Return just the symbol without exchange prefix
    // TradingView will automatically resolve the correct exchange
    // This works for most US stocks and ETFs
    return symbol;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FeatureGuard(
      featureKey: FeatureKeys.etfDetails,
      child: Scaffold(
        backgroundColor: HomeUi.pageBg(isDarkMode),
        body: Stack(
          children: [
            Column(
              children: [
                Obx(() => HomeTabBar(
                      showBackButton: true,
                      isWatchlistOpen: _watchlistService.isWatchlistOpen.value,
                      onWatchlistToggle: _toggleWatchlist,
                      onThemeToggle: () {
                        final currentTheme = Theme.of(context).brightness;
                        Get.changeThemeMode(
                          currentTheme == Brightness.dark
                              ? ThemeMode.light
                              : ThemeMode.dark,
                        );
                      },
                    )),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      const Spacer(),
                      _buildResearchNotesButton(isDarkMode),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (controller.errorMessage.isNotEmpty) {
                      return Center(
                        child: Text(
                          controller.errorMessage.value,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                      );
                    }

                    if (controller.etfData.value == null) {
                      return Center(
                        child: Text(
                          'No data available',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                      );
                    }

                    final etfData = controller.etfData.value!;
                    return _buildEtfContent(etfData, isDarkMode);
                  }),
                ),
              ],
            ),

            // Watchlist sidebar overlay
            Obx(() {
              if (!_watchlistService.isWatchlistOpen.value) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleWatchlist,
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: WatchlistSidebar(
                            isDarkMode: isDarkMode,
                            onClose: _toggleWatchlist,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (_isResearchNotesOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeResearchNotesPanel,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.24),
                  ),
                ),
              ),
            if (_isResearchNotesOpen)
              Positioned(
                top: 112,
                right: 20,
                child: _EtfResearchNotesOverlayCard(
                  isDarkMode: isDarkMode,
                  title: 'Research Notes',
                  subtitle: widget.ticker.symbol ?? '',
                  onClose: _closeResearchNotesPanel,
                  child: ResearchNotesPanelContent(
                    ticker: widget.ticker.symbol ?? '',
                    controller: researchNotesController,
                    onAddNote: () => _showAddResearchNoteDialog(isDarkMode),
                  ),
                ),
              ),
            // Global FAB Overlay
            const GlobalFABOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildEtfContent(EtfsData etfData, bool isDarkMode) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildEtfHeader(etfData, isDarkMode),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate heatmap height dynamically based on available width
              final availableWidth =
                  (constraints.maxWidth - 8) / 2; // Half width minus spacing
              final cellWidth = (availableWidth - 20 - 8) /
                  3; // Container width - padding - spacing
              final cellHeight = cellWidth / 2; // aspectRatio is 2
              final gridHeight =
                  (cellHeight * 3) + (4 * 2); // 3 rows + 2 spacings
              final heatmapHeight =
                  20 + 26 + gridHeight; // padding + header + grid

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TradingViewWidget(
                      symbol: _formatSymbolForTradingView(etfData),
                      controller: tradingViewController,
                      height: heatmapHeight, // Dynamic height to match heatmap
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPerformanceHeatmap(
                        etfData, isDarkMode, heatmapHeight),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // ETF Key Metrics
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTradingData(etfData, isDarkMode)),
              const SizedBox(width: 8),
              Expanded(child: _buildKeyMetrics(etfData, isDarkMode)),
              const SizedBox(width: 8),
              Expanded(child: _buildReturnsData(etfData, isDarkMode)),
            ],
          ),
          const SizedBox(height: 16),

          // Charts Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCapExposureChart(etfData, isDarkMode)),
              const SizedBox(width: 16),
              Expanded(child: _buildSectorExposureChart(etfData, isDarkMode)),
            ],
          ),
          const SizedBox(height: 16),

          // Holdings Table
          _buildHoldingsTable(isDarkMode),
          const SizedBox(height: 16),
          _buildHoldingsPaginationControls(),
          const SizedBox(height: 16),
          SimpleNewsWidget(
            symbol: widget.ticker.symbol ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildResearchNotesButton(bool isDarkMode) {
    return Obx(() {
      final hasNotes = researchNotesController.hasNotes;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          HomeUi.ghostAction(
            label: 'Research Notes',
            dark: isDarkMode,
            icon: Icons.sticky_note_2_outlined,
            onTap: _openResearchNotesPanel,
          ),
          if (hasNotes)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: HomeUi.accent(isDarkMode),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: HomeUi.pageBg(isDarkMode),
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  void _showAddResearchNoteDialog(bool isDarkMode) {
    _EtfAddResearchNoteDialog.show(
      context: context,
      ticker: widget.ticker.symbol ?? '',
      notesController: researchNotesController,
      onSaved: () {
        _showSuccessSnackBar('Note added successfully');
        setState(() => _isResearchNotesOpen = true);
      },
    );
  }

  Widget _buildEtfHeader(EtfsData etfData, bool isDarkMode) {
    final String ticker = etfData.symbol ?? widget.ticker.symbol ?? 'TICKER';
    final String etfName = etfData.etfProfile?.name ??
        widget.ticker.name ??
        widget.ticker.companyName ??
        'ETF Name';
    final double price = etfData.currentPrice?.toDouble() ?? 0.0;
    final double? change = etfData.change1DPercent?.toDouble();
    final bool isUp = change != null && change >= 0;

    return Container(
      decoration: HomeUi.cardDecoration(isDarkMode),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 11,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: HomeUi.elevatedBg(isDarkMode),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: HomeUi.borderLight(isDarkMode),
                            ),
                          ),
                          child: showLogo(
                            ticker,
                            widget.ticker.logo ?? '',
                            sideWidth: 28,
                            name: ticker,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                etfName,
                                style: HomeUi.sectionTitle(isDarkMode)
                                    .copyWith(fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ticker,
                                style: HomeUi.overline(isDarkMode).copyWith(
                                  letterSpacing: 1.2,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        AddToWatchlistButton(
                          ticker: ticker,
                          currentPrice: price,
                          isDarkMode: isDarkMode,
                          isInWatchlist: _isInWatchlist,
                          onSuccess: () {
                            _showSuccessSnackBar('$ticker added to watchlist');
                            _checkIfInWatchlist();
                          },
                          onError: () {
                            _showErrorSnackBar(
                              'Failed to add $ticker to watchlist',
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'CURRENT PRICE',
                                style: HomeUi.overline(isDarkMode).copyWith(
                                  fontSize: 10,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                etfData.currentPrice != null
                                    ? '\$${price.toStringAsFixed(2)}'
                                    : '--',
                                style: HomeUi.display(isDarkMode).copyWith(
                                  fontSize: 24,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            change == null
                                ? '--'
                                : '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                            style: HomeUi.tableNumeric(
                              isDarkMode,
                              positiveValue: change == null ? null : isUp,
                            ).copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _headerKv(
                      isDarkMode,
                      'Volume',
                      '${((etfData.volume ?? 0) / 1000000).toStringAsFixed(1)}M',
                    ),
                    _headerKv(
                      isDarkMode,
                      '52W High',
                      etfData.d52WeekHigh != null
                          ? '\$${etfData.d52WeekHigh!.toStringAsFixed(2)}'
                          : '--',
                    ),
                    _headerKv(
                      isDarkMode,
                      '52W Low',
                      etfData.d52WeekLow != null
                          ? '\$${etfData.d52WeekLow!.toStringAsFixed(2)}'
                          : '--',
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: HomeUi.borderLight(isDarkMode),
            ),
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    HomeUi.tableToolbarHeader(
                      isDarkMode,
                      icon: Icons.public_outlined,
                      title: 'Fund Information',
                    ),
                    const SizedBox(height: 12),
                    _headerKv(
                      isDarkMode,
                      'Exchange',
                      etfData.exchange ?? '--',
                    ),
                    _headerKv(
                      isDarkMode,
                      'Domicile',
                      etfData.domicile ?? '--',
                    ),
                    _headerKv(
                      isDarkMode,
                      'Asset Class',
                      etfData.assetClass ?? '--',
                    ),
                    _headerKv(
                      isDarkMode,
                      'Segment',
                      etfData.investmentSegment ?? '--',
                      maxLines: 2,
                    ),
                    _headerKv(
                      isDarkMode,
                      'Inception',
                      etfData.inceptionDate ?? '--',
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: HomeUi.borderLight(isDarkMode),
            ),
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    HomeUi.tableToolbarHeader(
                      isDarkMode,
                      icon: Icons.auto_graph_outlined,
                      title: 'Key Metrics',
                    ),
                    const SizedBox(height: 12),
                    _headerKv(
                      isDarkMode,
                      'Holdings',
                      etfData.numberOfHoldings?.toString() ?? '--',
                    ),
                    _headerKv(
                      isDarkMode,
                      'Expense Ratio',
                      etfData.expenseRatio != null
                          ? '${etfData.expenseRatio!.toStringAsFixed(2)}%'
                          : '--',
                    ),
                    _headerKv(
                      isDarkMode,
                      'NAV',
                      etfData.nav != null
                          ? '\$${etfData.nav!.toStringAsFixed(2)}'
                          : '--',
                    ),
                    _headerKv(
                      isDarkMode,
                      'AUM',
                      Constants.getShortenedMarketCapV2(etfData.aum),
                    ),
                    _headerKv(
                      isDarkMode,
                      'Dividend',
                      etfData.dividentAmount != null &&
                              etfData.dividentAmount! > 0
                          ? '\$${etfData.dividentAmount!.toStringAsFixed(2)}'
                          : '--',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerKv(
    bool isDarkMode,
    String label,
    String value, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              label,
              style:
                  HomeUi.tableCellSecondary(isDarkMode).copyWith(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style:
                  HomeUi.tableCellEmphasis(isDarkMode).copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradingData(EtfsData etfData, bool isDarkMode) {
    final data = [
      ['Open', '\$${etfData.open?.toStringAsFixed(2) ?? '--'}'],
      ['High', '\$${etfData.high?.toStringAsFixed(2) ?? '--'}'],
      ['Low', '\$${etfData.low?.toStringAsFixed(2) ?? '--'}'],
      ['Close', '\$${etfData.close?.toStringAsFixed(2) ?? '--'}'],
      ['Prev Close', '\$${etfData.previousClose?.toStringAsFixed(2) ?? '--'}'],
      ['Volume', '${((etfData.volume ?? 0) / 1000000).toStringAsFixed(1)}M'],
    ];

    return _buildCompactTable('Trading Data', data, isDarkMode);
  }

  Widget _buildKeyMetrics(EtfsData etfData, bool isDarkMode) {
    // Format ETF Total Assets
    String etfTotalAssetsFormatted = '--';
    if (etfData.etfTotalAssets != null && etfData.etfTotalAssets! > 0) {
      etfTotalAssetsFormatted =
          Constants.getShortenedMarketCapV2(etfData.etfTotalAssets!);
    }

    // Format Avg Volume 10D
    String avgVolume10DFormatted = '--';
    if (etfData.avgVolume10days != null && etfData.avgVolume10days! > 0) {
      avgVolume10DFormatted =
          '${((etfData.avgVolume10days! / 1000000).toStringAsFixed(1))}M';
    }

    final data = [
      ['P/E Ratio', etfData.priceToEarnings?.toStringAsFixed(2) ?? '--'],
      ['P/B Ratio', etfData.priceToBook?.toStringAsFixed(2) ?? '--'],
      ['ETF Total Assets', etfTotalAssetsFormatted],
      ['Avg Volume 10D', avgVolume10DFormatted],
      [
        'Interest Assets',
        '${etfData.interestBearingAssetsRatio?.toStringAsFixed(1) ?? '--'}%'
      ],
      [
        'Interest Debt',
        '${etfData.interestBearingDebtRatio?.toStringAsFixed(1) ?? '--'}%'
      ],
    ];

    return _buildCompactTable('Key Metrics', data, isDarkMode);
  }

  Widget _buildReturnsData(EtfsData etfData, bool isDarkMode) {
    final data = [
      ['Return 1M', '${etfData.totalReturn1M?.toStringAsFixed(2) ?? '--'}%'],
      ['Return 1Y', '${etfData.totalReturn1Y?.toStringAsFixed(2) ?? '--'}%'],
      ['Return 3Y', '${etfData.totalReturn3Y?.toStringAsFixed(2) ?? '--'}%'],
      ['Return 5Y', '${etfData.totalReturn5Y?.toStringAsFixed(2) ?? '--'}%'],
      ['Return 6M', '${etfData.totalReturn6M?.toStringAsFixed(2) ?? '--'}%'],
      ['Return 1W', '${etfData.totalReturn1W?.toStringAsFixed(2) ?? '--'}%'],
    ];

    return _buildCompactTable('Total Returns', data, isDarkMode);
  }

  Widget _buildCapExposureChart(EtfsData etfData, bool isDarkMode) {
    final capData = {
      'Mega Cap': etfData.megacapExposure ?? 0,
      'Large Cap': etfData.largecapExposure ?? 0,
      'Mid Cap': etfData.midcapExposure ?? 0,
      'Small Cap': etfData.smallcapExposure ?? 0,
      'Micro Cap': etfData.microcapExposure ?? 0,
      'Nano Cap': etfData.nanocapExposure ?? 0,
    };

    // Filter out zero values
    final filteredData = Map.fromEntries(
      capData.entries.where((entry) => entry.value > 0),
    );

    return _buildPieChartContainer(
      title: 'Market Cap Exposure',
      data: filteredData,
      isDarkMode: isDarkMode,
    );
  }

  Widget _buildSectorExposureChart(EtfsData etfData, bool isDarkMode) {
    if (etfData.sectorExposure == null || etfData.sectorExposure!.isEmpty) {
      return _buildPieChartContainer(
        title: 'Sector Exposure',
        data: {},
        isDarkMode: isDarkMode,
      );
    }

    // Convert sector exposure to Map<String, num> and sort by value (descending)
    final sectorData = <String, num>{};
    etfData.sectorExposure!.forEach((key, value) {
      if (value is num && value > 0) {
        sectorData[key] = value;
      }
    });

    // Sort by value in descending order (highest first)
    final sortedEntries = sectorData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedSectorData = <String, num>{};
    for (final entry in sortedEntries) {
      sortedSectorData[entry.key] = entry.value;
    }

    return _buildPieChartContainer(
      title: 'Sector Exposure',
      data: sortedSectorData,
      isDarkMode: isDarkMode,
    );
  }

  Widget _buildPieChartContainer({
    required String title,
    required Map<String, num> data,
    required bool isDarkMode,
  }) {
    return Container(
      padding: HomeUi.cardPadding,
      decoration: HomeUi.cardDecoration(isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeUi.tableToolbarHeader(
            isDarkMode,
            icon: Icons.donut_large_rounded,
            title: title,
            subtitleText: 'Allocation breakdown',
          ),
          const SizedBox(height: 14),
          if (data.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No data available',
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                // Pie Chart
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildInteractivePieChart(data, isDarkMode),
                  ),
                ),
                const SizedBox(width: 16),

                // Legend
                Expanded(
                  flex: 3,
                  child: _buildChartLegend(data, isDarkMode),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(Map<String, num> data, bool isDarkMode) {
    final colors = _getChartColors();
    final entries = data.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        entries.length,
        (index) {
          final entry = entries[index];
          final color = colors[index % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 6, right: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _etfSliceGradient(color, isDarkMode),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      color: isDarkMode
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${entry.value.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    color: isDarkMode
                        ? const Color(0xFFE5E7EB)
                        : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInteractivePieChart(Map<String, num> data, bool isDarkMode) {
    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            final center = Offset(box.size.width / 2, box.size.height / 2);
            final radius = box.size.width / 2 * 0.8;

            // Calculate which segment was tapped
            final dx = localPosition.dx - center.dx;
            final dy = localPosition.dy - center.dy;
            final distance = math.sqrt(dx * dx + dy * dy);

            if (distance <= radius && distance >= radius * 0.5) {
              final angle = math.atan2(dy, dx);
              final normalizedAngle = (angle + math.pi / 2) % (2 * math.pi);

              final total =
                  data.values.fold<num>(0, (sum, value) => sum + value);
              double currentAngle = 0;

              for (final entry in data.entries) {
                final sweepAngle = (entry.value / total) * 2 * math.pi;
                if (normalizedAngle >= currentAngle &&
                    normalizedAngle <= currentAngle + sweepAngle) {
                  _showTooltip(
                      context, entry.key, entry.value, details.globalPosition);
                  break;
                }
                currentAngle += sweepAngle;
              }
            }
          },
          child: CustomPaint(
            painter: PieChartPainter(
              data: data,
              isDarkMode: isDarkMode,
            ),
          ),
        );
      },
    );
  }

  void _showTooltip(
      BuildContext context, String label, num value, Offset position) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 50,
        top: position.dy - 40,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${value.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove tooltip after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Widget _buildHoldingsTable(bool isDarkMode) {
    return Obx(() {
      if (controller.isLoadingHoldings.value) {
        return Container(
          padding: HomeUi.cardPadding,
          decoration: HomeUi.cardDecoration(isDarkMode),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }

      if (controller.holdingsErrorMessage.value.isNotEmpty) {
        return Container(
          padding: HomeUi.cardPadding,
          decoration: HomeUi.cardDecoration(isDarkMode),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                controller.holdingsErrorMessage.value,
                style: TextStyle(
                  color: isDarkMode
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                  fontSize: 12,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                ),
              ),
            ),
          ),
        );
      }

      final enrichedHoldings = controller.enrichedHoldings;
      if (enrichedHoldings.isEmpty) {
        return Container(
          padding: HomeUi.cardPadding,
          decoration: HomeUi.cardDecoration(isDarkMode),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                'No holdings data available',
                style: TextStyle(
                  color: isDarkMode
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                  fontSize: 12,
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                ),
              ),
            ),
          ),
        );
      }

      final tableRows = enrichedHoldings.map((enrichedHolding) {
        final holding = enrichedHolding.holding;
        final stockData = enrichedHolding.stockData;
        final companyProfile = enrichedHolding.companyProfile;

        return SimpleRowModel(
          symbol: holding.symbol,
          name: companyProfile?.name ?? holding.name,
          logo: companyProfile?.logo,
          price: stockData?.currentPrice,
          changePercent: stockData?.priceChange1DPercent,
          currency: 'USD',
          fields: {
            'weight': '${holding.percent.toStringAsFixed(2)}%',
            'value': Constants.getShortenedMarketCapV2(holding.value),
            'currentPrice': stockData?.currentPrice != null
                ? '\$${stockData!.currentPrice!.toStringAsFixed(2)}'
                : '--',
            'change': stockData?.priceChange1D != null
                ? '${stockData!.priceChange1D!.toStringAsFixed(2)}'
                : '--',
            'changePercent': stockData?.priceChange1DPercent != null
                ? '${stockData!.priceChange1DPercent!.toStringAsFixed(2)}%'
                : '--',
            'volume': stockData?.volume != null
                ? '${((stockData!.volume! / 1000000).toStringAsFixed(1))}M'
                : '--',
            'marketCap': stockData?.usdMarketCap != null
                ? Constants.getShortenedMarketCapV2(stockData!.usdMarketCap!)
                : '--',
            'pe': stockData?.peTTM != null
                ? '${stockData!.peTTM!.toStringAsFixed(1)}'
                : '--',
            'pb': stockData?.pbAnnual != null
                ? '${stockData!.pbAnnual!.toStringAsFixed(2)}'
                : '--',
            'ps': stockData?.psTTM != null
                ? '${stockData!.psTTM!.toStringAsFixed(1)}'
                : '--',
            'eps': stockData?.epsTTM != null
                ? '\$${stockData!.epsTTM!.toStringAsFixed(2)}'
                : '--',
            'dividend': stockData?.currentDividendYieldTTM != null
                ? '${stockData!.currentDividendYieldTTM!.toStringAsFixed(2)}%'
                : '--',
            'beta': stockData?.beta != null
                ? '${stockData!.beta!.toStringAsFixed(2)}'
                : '--',
            'roe': stockData?.rOE != null
                ? '${stockData!.rOE!.toStringAsFixed(1)}%'
                : '--',
            'margin': stockData?.netProfitMarginTTM != null
                ? '${stockData!.netProfitMarginTTM!.toStringAsFixed(1)}%'
                : '--',
            'debt': stockData?.longTermDebtEquityAnnual != null
                ? '${stockData!.longTermDebtEquityAnnual!.toStringAsFixed(1)}%'
                : '--',
            '52wHigh': stockData?.d52WeekHigh != null
                ? '\$${stockData!.d52WeekHigh!.toStringAsFixed(2)}'
                : '--',
            '52wLow': stockData?.d52WeekLow != null
                ? '\$${stockData!.d52WeekLow!.toStringAsFixed(2)}'
                : '--',
            'return1Y': stockData?.priceChange1YPercent != null
                ? '${stockData!.priceChange1YPercent!.toStringAsFixed(1)}%'
                : '--',
            'return3Y': stockData?.priceChange3YPercent != null
                ? '${stockData!.priceChange3YPercent!.toStringAsFixed(1)}%'
                : '--',
          },
          changeColor: stockData?.priceChange1D != null
              ? (stockData!.priceChange1D! >= 0 ? Colors.green : Colors.red)
              : null,
        );
      }).toList();

      final totalHoldings = controller.holdingsData.value?.holdings.length ?? 0;

      return DynamicTable(
        title: 'Top Holdings',
        subtitle: 'Constituents inside this ETF · $totalHoldings holdings',
        toolbarLeadingIcon: Icons.account_balance_outlined,
        showOuterShadow: true,
        columns: const [
          SimpleColumn(label: 'WEIGHT', fieldName: 'weight', isNumeric: true),
          SimpleColumn(label: 'VALUE', fieldName: 'value', isNumeric: true),
          SimpleColumn(
              label: 'PRICE', fieldName: 'currentPrice', isNumeric: true),
          SimpleColumn(label: 'CHANGE', fieldName: 'change', isNumeric: true),
          SimpleColumn(
              label: 'CHANGE %', fieldName: 'changePercent', isNumeric: true),
          SimpleColumn(label: 'VOLUME', fieldName: 'volume', isNumeric: true),
          SimpleColumn(
              label: 'MKT CAP', fieldName: 'marketCap', isNumeric: true),
          SimpleColumn(label: 'P/E', fieldName: 'pe', isNumeric: true),
          SimpleColumn(label: 'P/B', fieldName: 'pb', isNumeric: true),
          SimpleColumn(label: 'P/S', fieldName: 'ps', isNumeric: true),
          SimpleColumn(label: 'EPS', fieldName: 'eps', isNumeric: true),
          SimpleColumn(
              label: 'DIV YIELD', fieldName: 'dividend', isNumeric: true),
          SimpleColumn(label: 'BETA', fieldName: 'beta', isNumeric: true),
          SimpleColumn(label: 'ROE', fieldName: 'roe', isNumeric: true),
          SimpleColumn(label: 'MARGIN', fieldName: 'margin', isNumeric: true),
          SimpleColumn(
              label: 'DEBT/EQUITY', fieldName: 'debt', isNumeric: true),
          SimpleColumn(
              label: '52W HIGH', fieldName: '52wHigh', isNumeric: true),
          SimpleColumn(label: '52W LOW', fieldName: '52wLow', isNumeric: true),
          SimpleColumn(
              label: '1Y RETURN', fieldName: 'return1Y', isNumeric: true),
          SimpleColumn(
              label: '3Y RETURN', fieldName: 'return3Y', isNumeric: true),
        ],
        rows: tableRows,
        showFixedColumn: true,
        tickerHeaderLabel: 'COMPANY',
        considerPadding: false,
        columnSpacing: 12,
        fixedColumnWidth: 280,
        enableDragging: true,
        enableLivePrices: true,
        zebraStripes: true,
        enableColumnCustomization: true,
        showColumnActionMenu: true,
        showColumnResizeHandle: true,
        compactHeaderText: true,
        tableId: 'etf_holdings_table',
        onDragStarted: () {},
        onDragEnd: () {},
      );
    });
  }

  Widget _buildHoldingsPaginationControls() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.totalHoldingsPages.value <= 1) {
        return const SizedBox.shrink();
      }

      final int currentPage = controller.currentHoldingsPage.value;
      final int totalPages = controller.totalHoldingsPages.value;
      final int currentDisplayPage = currentPage + 1;
      final int totalHoldings =
          controller.holdingsData.value?.holdings.length ?? 0;
      final List<int?> visiblePages =
          _holdingsPageItems(currentDisplayPage, totalPages);

      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12.5),
                  children: [
                    const TextSpan(text: 'Page '),
                    TextSpan(
                      text: '$currentDisplayPage',
                      style: HomeUi.tableCell(isDarkMode).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                    const TextSpan(text: ' of '),
                    TextSpan(
                      text: '$totalPages',
                      style: HomeUi.tableCell(isDarkMode).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                    TextSpan(text: '  ·  $totalHoldings holdings'),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _EtfPaginationIconButton(
                  icon: Icons.chevron_left_rounded,
                  enabled: controller.hasPreviousHoldingsPage,
                  isDarkMode: isDarkMode,
                  onTap: () => controller.previousHoldingsPage(),
                ),
                const SizedBox(width: 6),
                ...visiblePages.map((int? page) {
                  if (page == null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '…',
                        style: HomeUi.subtitle(isDarkMode).copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _EtfPaginationPageButton(
                      page: page,
                      selected: page == currentDisplayPage,
                      isDarkMode: isDarkMode,
                      onTap: () => controller.goToHoldingsPage(page - 1),
                    ),
                  );
                }),
                const SizedBox(width: 6),
                _EtfPaginationIconButton(
                  icon: Icons.chevron_right_rounded,
                  enabled: controller.hasNextHoldingsPage,
                  isDarkMode: isDarkMode,
                  onTap: () => controller.nextHoldingsPage(),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  List<int?> _holdingsPageItems(int current, int total) {
    if (total <= 7) {
      return [for (var i = 1; i <= total; i++) i];
    }
    final set = <int>{1, total, current};
    if (current - 1 > 1) set.add(current - 1);
    if (current + 1 < total) set.add(current + 1);
    if (current <= 3) set.addAll({2, 3, 4});
    if (current >= total - 2) set.addAll({total - 3, total - 2, total - 1});
    final sorted = set.toList()..sort();
    final out = <int?>[];
    int? prev;
    for (final page in sorted) {
      if (prev != null && page - prev > 1) out.add(null);
      out.add(page);
      prev = page;
    }
    return out;
  }

  List<Color> _getChartColors() => _etfChartPalette;

  Widget _buildCompactTable(
      String title, List<List<String>> data, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: HomeUi.cardDecoration(isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeUi.tableToolbarHeader(
            isDarkMode,
            icon: Icons.grid_view_rounded,
            title: title,
            subtitleText: 'Snapshot view',
          ),
          const SizedBox(height: 12),
          ...data
              .map((row) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: HomeUi.elevatedBg(isDarkMode),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: HomeUi.borderLight(isDarkMode)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            row[0],
                            style: HomeUi.subtitle(isDarkMode)
                                .copyWith(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          row[1],
                          style: HomeUi.bodyText(isDarkMode).copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildPerformanceHeatmap(
      EtfsData etfData, bool isDarkMode, double height) {
    final performanceData = {
      '1D': etfData.change1DPercent ?? 0,
      '1W': etfData.priceChange1WPercent ?? 0,
      '1M': etfData.priceChange1MPercent ?? 0,
      '3M': etfData.priceChange3MPercent ?? 0,
      '6M': etfData.priceChange6MPercent ?? 0,
      '1Y': etfData.priceChange1YPercent ?? 0,
      '3Y': etfData.priceChange3YPercent ?? 0,
      '5Y': etfData.priceChange5YPercent ?? 0,
      'YTD': etfData.priceChangeYTDPercent ?? 0,
    };

    return Container(
      width: double.infinity,
      height: height,
      padding: HomeUi.cardPadding,
      decoration: HomeUi.cardDecoration(isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeUi.tableToolbarHeader(
            isDarkMode,
            icon: Icons.auto_graph_rounded,
            title: 'Performance Heatmap',
            subtitleText: 'Return trends across timeframes',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 2,
              ),
              itemCount: performanceData.length,
              itemBuilder: (context, index) {
                final period = performanceData.keys.elementAt(index);
                final value = performanceData[period] ?? 0;
                return _buildHeatmapCell(period, value.toDouble(), isDarkMode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapCell(String period, double value, bool isDarkMode) {
    final isPositive = value >= 0;
    final absValue = value.abs();

    Color cellColor;
    Color textColor;

    if (absValue == 0) {
      cellColor =
          isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
      textColor =
          isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    } else if (absValue <= 1) {
      cellColor =
          isPositive ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);
      textColor =
          isPositive ? const Color(0xFF065F46) : const Color(0xFF991B1B);
    } else if (absValue <= 5) {
      cellColor =
          isPositive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA);
      textColor =
          isPositive ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D);
    } else if (absValue <= 15) {
      cellColor =
          isPositive ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5);
      textColor =
          isPositive ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D);
    } else {
      cellColor =
          isPositive ? const Color(0xFF34D399) : const Color(0xFFF87171);
      textColor =
          isPositive ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D);
    }

    return Container(
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            period,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: Constants.FONT_DEFAULT_NEW,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

const List<Color> _etfChartPalette = <Color>[
  Color(0xFF232C64),
  Color(0xFF3D5A80),
  Color(0xFFC45C3A),
  Color(0xFF6A2C72),
  Color(0xFF5C7A6A),
  Color(0xFFA72669),
  Color(0xFF8B7355),
  Color(0xFF4A6B8A),
  Color(0xFFB07D62),
  Color(0xFF6B5B7B),
  Color(0xFF7A8B7A),
  Color(0xFF8B929C),
];

LinearGradient _etfSliceGradient(Color color, bool isDarkMode) {
  final Color highlight =
      Color.lerp(color, Colors.white, isDarkMode ? 0.18 : 0.22)!;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[color, highlight],
  );
}

class PieChartPainter extends CustomPainter {
  final Map<String, num> data;
  final bool isDarkMode;

  PieChartPainter({
    required this.data,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 * 0.82;
    final Color surface = HomeUi.cardBg(isDarkMode);
    final Rect chartRect = Rect.fromCircle(center: center, radius: radius);

    final num total =
        data.values.fold<num>(0, (num sum, num value) => sum + value);
    if (total == 0) return;

    double startAngle = -math.pi / 2;
    final List<MapEntry<String, num>> entries = data.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final MapEntry<String, num> entry = entries[i];
      final double sweepAngle = (entry.value / total) * 2 * math.pi;
      final Color color = _etfChartPalette[i % _etfChartPalette.length];

      final Paint paint = Paint()
        ..shader = _etfSliceGradient(color, isDarkMode).createShader(chartRect)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawArc(chartRect, startAngle, sweepAngle, true, paint);

      final Paint gapPaint = Paint()
        ..color = surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..isAntiAlias = true;

      canvas.drawArc(chartRect, startAngle, sweepAngle, true, gapPaint);

      startAngle += sweepAngle;
    }

    final Paint centerPaint = Paint()
      ..color = surface
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius * 0.58, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _EtfPaginationIconButton extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _EtfPaginationIconButton({
    required this.icon,
    required this.enabled,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  State<_EtfPaginationIconButton> createState() =>
      _EtfPaginationIconButtonState();
}

class _EtfPaginationIconButtonState extends State<_EtfPaginationIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: enabled ? 1 : 0.38,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: HomeUi.controlHeight,
            height: HomeUi.controlHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: enabled && _hover
                  ? HomeUi.iconFillGradient
                  : HomeUi.iconWellGradient,
              border: Border.all(
                color: enabled && _hover
                    ? HomeUi.buttonBorder
                    : HomeUi.iconWellBorder,
                width: 0.856,
              ),
            ),
            child: enabled && _hover
                ? Icon(widget.icon, size: 18, color: Colors.white)
                : HomeUi.brandIcon(icon: widget.icon, size: 18),
          ),
        ),
      ),
    );
  }
}

class _EtfPaginationPageButton extends StatefulWidget {
  final int page;
  final bool selected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _EtfPaginationPageButton({
    required this.page,
    required this.selected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  State<_EtfPaginationPageButton> createState() =>
      _EtfPaginationPageButtonState();
}

class _EtfPaginationPageButtonState extends State<_EtfPaginationPageButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final selected = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: selected ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: selected ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(
            minWidth: HomeUi.controlHeight,
            minHeight: HomeUi.controlHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? HomeUi.iconFillGradient : null,
            color: selected
                ? null
                : (_hover ? HomeUi.elevatedBg(dark) : Colors.transparent),
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            border: Border.all(
              color: selected
                  ? HomeUi.buttonBorder
                  : (_hover ? HomeUi.borderStrong(dark) : Colors.transparent),
              width: 0.856,
            ),
          ),
          child: Text(
            '${widget.page}',
            style: HomeUi.control(dark, active: true).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : HomeUi.title(dark),
            ),
          ),
        ),
      ),
    );
  }
}

class _EtfResearchNotesOverlayCard extends StatelessWidget {
  const _EtfResearchNotesOverlayCard({
    required this.isDarkMode,
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.child,
  });

  final bool isDarkMode;
  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 420,
        height: 560,
        decoration: BoxDecoration(
          color: HomeUi.cardBg(isDarkMode),
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          border: Border.all(color: HomeUi.borderLight(isDarkMode)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.38 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: HomeUi.tableToolbarHeader(
                      isDarkMode,
                      icon: Icons.sticky_note_2_outlined,
                      title: title,
                      subtitleText: subtitle.isNotEmpty ? subtitle : null,
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: HomeUi.elevatedBg(isDarkMode),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: HomeUi.borderLight(isDarkMode)),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: HomeUi.muted(isDarkMode),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: HomeUi.borderLight(isDarkMode)),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _EtfAddResearchNoteDialog extends StatefulWidget {
  const _EtfAddResearchNoteDialog({
    required this.ticker,
    required this.notesController,
    required this.onSaved,
  });

  final String ticker;
  final ResearchNotesController notesController;
  final VoidCallback onSaved;

  static Future<void> show({
    required BuildContext context,
    required String ticker,
    required ResearchNotesController notesController,
    required VoidCallback onSaved,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Research Note',
      barrierColor: Colors.black.withValues(alpha: 0.46),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: _EtfAddResearchNoteDialog(
              ticker: ticker,
              notesController: notesController,
              onSaved: onSaved,
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<_EtfAddResearchNoteDialog> createState() =>
      _EtfAddResearchNoteDialogState();
}

class _EtfAddResearchNoteDialogState extends State<_EtfAddResearchNoteDialog> {
  final TextEditingController _noteController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Please enter a note');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final success = await widget.notesController.addNote(widget.ticker, text);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      widget.onSaved();
    } else {
      setState(() {
        _saving = false;
        _error = widget.notesController.errorMessage.value.isNotEmpty
            ? widget.notesController.errorMessage.value
            : 'Failed to add note';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: HomeUi.cardBg(isDark),
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          border: Border.all(color: HomeUi.borderLight(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.10),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: HomeUi.tableToolbarHeader(
                      isDark,
                      icon: Icons.note_add_outlined,
                      title: 'Add Research Note',
                      subtitleText: widget.ticker,
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _saving ? null : () => Navigator.of(context).pop(),
                      child: Container(
                        width: HomeUi.controlHeight,
                        height: HomeUi.controlHeight,
                        decoration: BoxDecoration(
                          color: HomeUi.elevatedBg(isDark),
                          shape: BoxShape.circle,
                          border: Border.all(color: HomeUi.borderLight(isDark)),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: HomeUi.muted(isDark),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: FilterTextField(
                dark: isDark,
                label: 'Note',
                controller: _noteController,
                hintText: 'Thesis, catalysts, risks, follow-ups…',
                errorText: _error,
                minLines: 4,
                maxLines: 6,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Divider(height: 1, color: HomeUi.borderLight(isDark)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: _saving ? 0.5 : 1,
                      child: HomeUi.ghostAction(
                        label: 'Cancel',
                        dark: isDark,
                        onTap:
                            _saving ? () {} : () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Opacity(
                      opacity: _saving ? 0.7 : 1,
                      child: HomeUi.primaryAction(
                        label: _saving ? 'Saving…' : 'Save',
                        onTap: _saving ? () {} : _save,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
