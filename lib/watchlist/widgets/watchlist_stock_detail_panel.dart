import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Controllers/research_notes_controller.dart';
import 'package:musaffa_terminal/Screens/ticker_detail_screen.dart';
import 'package:musaffa_terminal/charts/controllers/ticker_custom_charts_controller.dart';
import 'package:musaffa_terminal/charts/models/ohlc_candle_point.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/watchlist/models/target_price_model.dart';
import 'package:musaffa_terminal/watchlist/widgets/research_note_dialog.dart';
import 'package:musaffa_terminal/watchlist/widgets/target_price_dialog.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_shimmer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Right-rail stock detail for the watchlist page.
/// Entire panel (header + timeframe tabs + chart + stats + note) scrolls together.
class WatchlistStockDetailPanel extends StatefulWidget {
  const WatchlistStockDetailPanel({
    super.key,
    required this.stock,
    required this.isDarkMode,
  });

  final SimpleRowModel? stock;
  final bool isDarkMode;

  @override
  State<WatchlistStockDetailPanel> createState() =>
      _WatchlistStockDetailPanelState();
}

class _WatchlistStockDetailPanelState extends State<WatchlistStockDetailPanel> {
  static const List<PremiumPriceRange> _ranges = <PremiumPriceRange>[
    PremiumPriceRange.oneDay,
    PremiumPriceRange.oneWeek,
    PremiumPriceRange.oneMonth,
    PremiumPriceRange.threeMonths,
    PremiumPriceRange.oneYear,
    PremiumPriceRange.fiveYears,
  ];

  late final TickerCustomChartsController _chartController;
  late final ResearchNotesController _notesController;
  String? _loadedSymbol;

  @override
  void initState() {
    super.initState();
    _chartController = TickerCustomChartsController();
    _chartController.selectedRange.value = PremiumPriceRange.oneDay;
    _notesController = ResearchNotesController();
    _syncForStock(widget.stock);
  }

  @override
  void didUpdateWidget(covariant WatchlistStockDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? next = widget.stock?.symbol;
    final String? prev = oldWidget.stock?.symbol;
    if (next != prev) {
      _syncForStock(widget.stock);
    }
  }

  @override
  void dispose() {
    _chartController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _syncForStock(SimpleRowModel? stock) async {
    final String? symbol = stock?.symbol.trim().toUpperCase();
    if (symbol == null || symbol.isEmpty) {
      _loadedSymbol = null;
      return;
    }
    if (_loadedSymbol == symbol) return;
    _loadedSymbol = symbol;
    await Future.wait(<Future<void>>[
      _chartController.loadPriceHistory(symbol),
      _notesController.fetchNotes(symbol),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;
    final SimpleRowModel? stock = widget.stock;

    return Container(
      decoration: HomeUi.cardDecoration(isDark),
      clipBehavior: Clip.none,
      child: stock == null
          ? SizedBox(
              height: 280,
              child: _EmptyState(isDark: isDark),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _Header(
                    stock: stock,
                    isDark: isDark,
                    onOpenFull: () => _openTickerDetail(stock),
                  ),
                  const SizedBox(height: 10),
                  _PriceBlock(stock: stock, isDark: isDark),
                  const SizedBox(height: 12),
                  _RangeTabs(
                    isDark: isDark,
                    controller: _chartController,
                    ranges: _ranges,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: _DetailChart(
                      isDark: isDark,
                      controller: _chartController,
                      positive: stock.isPositive ?? true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Key Stats', style: HomeUi.sectionTitle(isDark)),
                  const SizedBox(height: 12),
                  _KeyStatsGrid(stock: stock, isDark: isDark),
                  const SizedBox(height: 20),
                  _MyNoteSection(
                    stock: stock,
                    isDark: isDark,
                    notesController: _notesController,
                  ),
                ],
              ),
            ),
    );
  }

  void _openTickerDetail(SimpleRowModel stock) {
    final TickerModel model = TickerModel(
      symbol: stock.symbol,
      ticker: stock.symbol,
      mainTicker: stock.symbol,
      name: stock.name,
      companyName: stock.name,
      logo: stock.logo,
      currentPrice: stock.price,
      percentChange: stock.changePercent,
      currency: stock.currency ?? 'USD',
      isStock: true,
    );
    FeatureNavigation.pushIfAllowed(
      context,
      FeatureKeys.tickerDetails,
      TickerDetailScreen(ticker: model),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Select a stock to see details',
          textAlign: TextAlign.center,
          style: HomeUi.subtitle(isDark),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.stock,
    required this.isDark,
    required this.onOpenFull,
  });

  final SimpleRowModel stock;
  final bool isDark;
  final VoidCallback onOpenFull;

  static String _shortCompanyName(String name) {
    String trimmed = name.trim();
    const List<String> suffixes = <String>[
      ', Inc.',
      ' Inc.',
      ', Inc',
      ' Inc',
      ', Corp.',
      ' Corp.',
      ' Corporation',
      ', Ltd.',
      ' Ltd.',
      ' Limited',
      ' PLC',
      ' plc',
    ];
    for (final String suffix in suffixes) {
      if (trimmed.endsWith(suffix)) {
        trimmed = trimmed.substring(0, trimmed.length - suffix.length).trim();
        break;
      }
    }
    if (trimmed.endsWith('.com')) {
      trimmed = trimmed.substring(0, trimmed.length - 4).trim();
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final String exchange =
        (stock.fields['exchange'] as String?)?.trim().isNotEmpty == true
            ? stock.fields['exchange'] as String
            : '—';
    final String displayName = _shortCompanyName(stock.name);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        showLogo(
          stock.symbol,
          stock.logo ?? '',
          sideWidth: 48,
          circular: true,
          name: stock.name,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HomeUi.sectionTitle(isDark).copyWith(fontSize: 17),
              ),
              const SizedBox(height: 3),
              Text(
                '${stock.symbol} · $exchange',
                style: HomeUi.subtitle(isDark).copyWith(fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        HomeUi.ghostAction(
          label: 'Full Ticker',
          dark: isDark,
          onTap: onOpenFull,
        ),
      ],
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.stock, required this.isDark});

  final SimpleRowModel stock;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final double? price = (stock.fields['currentPrice'] as num?)?.toDouble() ??
        stock.price?.toDouble();
    final double? pct = (stock.fields['change1DPercent'] as num?)?.toDouble() ??
        stock.changePercent?.toDouble();
    final double? abs = (stock.fields['change1DAbs'] as num?)?.toDouble();
    final bool positive = (pct ?? abs ?? 0) >= 0;
    final Color tone =
        positive ? HomeUi.positive(isDark) : HomeUi.negative(isDark);

    String changeLabel = '—';
    if (pct != null) {
      final String absPart = abs != null
          ? '${abs >= 0 ? '+' : ''}${abs.toStringAsFixed(2)}'
          : '';
      final String pctPart =
          '${positive ? '+' : ''}${pct.toStringAsFixed(2)}%';
      changeLabel = absPart.isEmpty ? pctPart : '$absPart ($pctPart)';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          price == null ? '—' : '\$${price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.1,
            color: HomeUi.title(isDark),
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            changeLabel,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: tone,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
        ),
      ],
    );
  }
}

class _RangeTabs extends StatelessWidget {
  const _RangeTabs({
    required this.isDark,
    required this.controller,
    required this.ranges,
  });

  final bool isDark;
  final TickerCustomChartsController controller;
  final List<PremiumPriceRange> ranges;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final PremiumPriceRange selected = controller.selectedRange.value;
      return Row(
        children: ranges.map((PremiumPriceRange range) {
          final bool sel = range == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => controller.selectRange(range),
                borderRadius: BorderRadius.circular(HomeUi.radiusSm),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(HomeUi.radiusSm),
                    border: Border.all(
                      color: sel
                          ? HomeUi.buttonBorder
                          : HomeUi.borderLight(isDark),
                      width: sel ? 1.5 : 1,
                    ),
                    color: sel
                        ? HomeUi.buttonBorder.withValues(alpha: 0.08)
                        : Colors.transparent,
                  ),
                  child: Text(
                    range.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel
                          ? HomeUi.buttonBorder
                          : HomeUi.muted(isDark),
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _DetailChart extends StatefulWidget {
  const _DetailChart({
    required this.isDark,
    required this.controller,
    required this.positive,
  });

  final bool isDark;
  final TickerCustomChartsController controller;
  final bool positive;

  @override
  State<_DetailChart> createState() => _DetailChartState();
}

class _DetailChartState extends State<_DetailChart> {
  late final CrosshairBehavior _crosshair;
  late final TrackballBehavior _trackball;

  @override
  void initState() {
    super.initState();
    _crosshair = CrosshairBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      lineType: CrosshairLineType.both,
      lineWidth: 1,
    );
    _trackball = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      lineType: TrackballLineType.vertical,
      tooltipDisplayMode: TrackballDisplayMode.floatAllPoints,
      markerSettings: TrackballMarkerSettings(
        color: HomeUi.buttonBorder,
        borderColor: HomeUi.cardBg(widget.isDark),
        borderWidth: 2,
        height: 7,
        width: 7,
      ),
      builder: (BuildContext context, TrackballDetails details) {
        final dynamic x = details.point?.x;
        final dynamic y = details.point?.y;
        if (x is! DateTime || y is! num) return const SizedBox.shrink();
        final bool intraday = widget.controller.isIntraday;
        return _ChartHoverTooltip(
          isDark: widget.isDark,
          dateLabel: DateFormat(
            intraday ? 'MMM d · h:mm a' : 'MMM d, yyyy',
          ).format(x),
          priceLabel: '\$${y.toStringAsFixed(2)}',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<OhlcCandlePoint> data = widget.controller.visibleCandles;
      final bool loading = widget.controller.isLoadingPrice.value;
      final bool up = (widget.controller.rangeChangePercent ??
              (widget.positive ? 1 : -1)) >=
          0;
      final Color line =
          up ? HomeUi.positive(widget.isDark) : HomeUi.negative(widget.isDark);

      if (loading) {
        return WatchlistShimmer.detailChart(isDarkMode: widget.isDark);
      }

      if (data.isEmpty) {
        return Center(
          child: Text(
            widget.controller.priceError.value.isNotEmpty
                ? widget.controller.priceError.value
                : 'No chart data',
            style: HomeUi.subtitle(widget.isDark),
          ),
        );
      }

      final bool intraday = widget.controller.isIntraday;
      return SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.zero,
        enableAxisAnimation: true,
        crosshairBehavior: _crosshair,
        trackballBehavior: _trackball,
        primaryXAxis: DateTimeAxis(
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: TextStyle(
            fontSize: 10,
            color: HomeUi.muted(widget.isDark),
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
          dateFormat: DateFormat(intraday ? 'h a' : 'MMM d'),
          edgeLabelPlacement: EdgeLabelPlacement.shift,
        ),
        primaryYAxis: NumericAxis(
          opposedPosition: true,
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: HomeUi.borderLight(widget.isDark),
            dashArray: const <double>[4, 4],
          ),
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: TextStyle(
            fontSize: 10,
            color: HomeUi.muted(widget.isDark),
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
          numberFormat: NumberFormat('#0.00'),
        ),
        series: <CartesianSeries<OhlcCandlePoint, DateTime>>[
          SplineAreaSeries<OhlcCandlePoint, DateTime>(
            dataSource: data,
            xValueMapper: (OhlcCandlePoint p, _) => p.date,
            yValueMapper: (OhlcCandlePoint p, _) => p.close,
            borderWidth: 1.8,
            borderColor: line,
            splineType: intraday ? SplineType.monotonic : SplineType.cardinal,
            cardinalSplineTension: intraday ? 0 : 0.2,
            animationDuration: 450,
            markerSettings: const MarkerSettings(isVisible: false),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                line.withValues(alpha: widget.isDark ? 0.32 : 0.22),
                line.withValues(alpha: 0.02),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _ChartHoverTooltip extends StatelessWidget {
  const _ChartHoverTooltip({
    required this.isDark,
    required this.dateLabel,
    required this.priceLabel,
  });

  final bool isDark;
  final String dateLabel;
  final String priceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: HomeUi.cardBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusSm),
        border: Border.all(color: HomeUi.borderLight(isDark)),
        boxShadow: HomeUi.cardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateLabel,
            style: HomeUi.subtitle(isDark).copyWith(fontSize: 10),
          ),
          const SizedBox(height: 3),
          Text(
            priceLabel,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: HomeUi.title(isDark),
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyStatsGrid extends StatelessWidget {
  const _KeyStatsGrid({required this.stock, required this.isDark});

  final SimpleRowModel stock;
  final bool isDark;

  String _num(dynamic v, {int digits = 2, String prefix = ''}) {
    final double? n = v is num
        ? v.toDouble()
        : double.tryParse(v?.toString() ?? '');
    if (n == null) return '—';
    return '$prefix${n.toStringAsFixed(digits)}';
  }

  String _vol(dynamic v) {
    final double? n = v is num
        ? v.toDouble()
        : double.tryParse(v?.toString() ?? '');
    if (n == null || n <= 0) return '—';
    if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}B';
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  String _mcap(dynamic v) {
    final double? n = v is num
        ? v.toDouble()
        : double.tryParse(v?.toString() ?? '');
    if (n == null || n <= 0) return '—';
    return Constants.formatMarketCapFromMillions(n);
  }

  String _pct(dynamic v) {
    final double? n = v is num
        ? v.toDouble()
        : double.tryParse(v?.toString() ?? '');
    if (n == null) return '—';
    return '${n.toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> f = stock.fields;
    final List<List<(String, String)>> pairs = <List<(String, String)>>[
      <(String, String)>[
        ('Open', _num(f['open'])),
        ('Prev Close', _num(f['previousClose'] ?? f['previous_close'])),
      ],
      <(String, String)>[
        ('High', _num(f['high'])),
        ('Low', _num(f['low'])),
      ],
      <(String, String)>[
        ('Market Cap', _mcap(f['marketCapRaw'] ?? f['usdMarketCap'])),
        ('P/E Ratio', _num(f['peTTM'])),
      ],
      <(String, String)>[
        ('Volume', _vol(f['volume'])),
        ('Avg Volume', _vol(f['avgVolume'])),
      ],
      <(String, String)>[
        ('52W High', _num(f['weekHigh'])),
        ('52W Low', _num(f['weekLow'])),
      ],
      <(String, String)>[
        ('Dividend Yield', _pct(f['dividendYield'])),
        ('Beta', _num(f['beta'])),
      ],
    ];

    return Column(
      children: pairs.map((List<(String, String)> row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: <Widget>[
              Expanded(child: _StatCell(label: row[0].$1, value: row[0].$2, isDark: isDark)),
              const SizedBox(width: 16),
              Expanded(child: _StatCell(label: row[1].$1, value: row[1].$2, isDark: isDark)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: HomeUi.title(isDark),
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
      ],
    );
  }
}

class _MyNoteSection extends StatelessWidget {
  const _MyNoteSection({
    required this.stock,
    required this.isDark,
    required this.notesController,
  });

  final SimpleRowModel stock;
  final bool isDark;
  final ResearchNotesController notesController;

  @override
  Widget build(BuildContext context) {
    final WatchlistController watchlist = Get.find<WatchlistController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: HomeUi.softBrandWellGradient,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: HomeUi.iconWellBorder),
              ),
              child: Icon(
                Icons.sticky_note_2_outlined,
                size: 16,
                color: HomeUi.muted(isDark),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('My Note', style: HomeUi.sectionTitle(isDark)),
                  Text(
                    'Private research for ${stock.symbol}',
                    style: HomeUi.subtitle(isDark).copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
            HomeUi.ghostAction(
              label: 'Edit',
              icon: Icons.edit_outlined,
              dark: isDark,
              onTap: () => _editNote(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          final String noteText = notesController.notes.isEmpty
              ? ''
              : notesController.notes.first.text;
          final TargetPriceModel? target =
              watchlist.getTargetPriceForTicker(stock.symbol);
          final bool hasNote = noteText.trim().isNotEmpty;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: HomeUi.cardDecoration(isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (notesController.isLoading.value)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            HomeUi.accent(isDark),
                          ),
                        ),
                      ),
                    ),
                  )
                else if (!hasNote)
                  _NoteEmptyState(
                    isDark: isDark,
                    symbol: stock.symbol,
                    onEdit: () => _editNote(context),
                  )
                else
                  Text(
                    noteText,
                    style: HomeUi.bodyText(isDark).copyWith(
                      height: 1.55,
                      fontSize: 13.5,
                      color: HomeUi.title(isDark),
                    ),
                  ),
                if (!notesController.isLoading.value) ...<Widget>[
                  const SizedBox(height: 14),
                  if (target != null)
                    _TargetPriceRow(
                      isDark: isDark,
                      target: target,
                      onEdit: () => _editTarget(context, watchlist, target),
                    )
                  else
                    _SetTargetAction(
                      isDark: isDark,
                      onTap: () => _editTarget(context, watchlist, null),
                    ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _editNote(BuildContext context) async {
    final String? result = await ResearchNoteDialog.show(
      context: context,
      symbol: stock.symbol,
      initialText: notesController.notes.isNotEmpty
          ? notesController.notes.first.text
          : '',
    );

    if (result == null || result.isEmpty) return;
    await notesController.addNote(stock.symbol, result);
  }

  Future<void> _editTarget(
    BuildContext context,
    WatchlistController watchlist,
    TargetPriceModel? existing,
  ) async {
    await TargetPriceDialog.show(
      context: context,
      ticker: stock.symbol,
      existingTarget: existing,
      onSave: (double price, String alertType) async {
        if (existing != null) {
          await watchlist.updateTargetPrice(
            existing.targetId,
            price,
            alertType,
          );
        } else {
          await watchlist.createTargetPrice(stock.symbol, price, alertType);
        }
      },
    );
  }
}

class _NoteEmptyState extends StatelessWidget {
  const _NoteEmptyState({
    required this.isDark,
    required this.symbol,
    required this.onEdit,
  });

  final bool isDark;
  final String symbol;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'No note yet',
                      style: HomeUi.control(isDark, active: true).copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Capture your thesis for $symbol',
                      style: HomeUi.subtitle(isDark).copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: HomeUi.muted(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetPriceRow extends StatelessWidget {
  const _TargetPriceRow({
    required this.isDark,
    required this.target,
    required this.onEdit,
  });

  final bool isDark;
  final TargetPriceModel target;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final Color green = HomeUi.positive(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: HomeUi.cardBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusPill),
        border: Border.all(color: green.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.flag_rounded, size: 14, color: green),
          const SizedBox(width: 8),
          Text(
            'Target',
            style: HomeUi.control(isDark).copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: green,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '\$${target.targetPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: HomeUi.title(isDark),
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          HomeUi.ghostAction(
            label: 'Update',
            dark: isDark,
            onTap: onEdit,
          ),
        ],
      ),
    );
  }
}

class _SetTargetAction extends StatelessWidget {
  const _SetTargetAction({
    required this.isDark,
    required this.onTap,
  });

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: HomeUi.ghostAction(
        label: 'Set target price',
        icon: Icons.track_changes_rounded,
        dark: isDark,
        onTap: onTap,
      ),
    );
  }
}
