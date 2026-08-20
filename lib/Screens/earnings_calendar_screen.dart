import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/Components/dynamic_table_from_web.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Controllers/earnings_calendar_controller.dart';
import 'package:musaffa_terminal/Controllers/earnings_detail_controller.dart';
import 'package:musaffa_terminal/Screens/earnings_detail_screen.dart';
import 'package:musaffa_terminal/models/earnings_calendar_model.dart';
import 'package:musaffa_terminal/services/company_enrichment_cache.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

class EarningsCalendarScreen extends StatefulWidget {
  const EarningsCalendarScreen({super.key});

  @override
  State<EarningsCalendarScreen> createState() => _EarningsCalendarScreenState();
}

class _EarningsCalendarScreenState extends State<EarningsCalendarScreen> {
  late final EarningsCalendarController _controller;
  late final TextEditingController _searchController;
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  final DateFormat _displayDate = DateFormat('MMM d, yyyy');

  static const Color _bmo = Color(0xFF059669);
  static const Color _amc = Color(0xFF2563EB);
  static const Color _dmh = Color(0xFFEA580C);

  @override
  void initState() {
    super.initState();
    _controller = Get.put(EarningsCalendarController());
    _searchController = TextEditingController();
    _fromController = TextEditingController(
      text: _displayDate.format(_controller.fromDate.value),
    );
    _toController = TextEditingController(
      text: _displayDate.format(_controller.toDate.value),
    );
    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.earnings);
    }
    ever<DateTime>(_controller.fromDate, (DateTime d) {
      _fromController.text = _displayDate.format(d);
    });
    ever<DateTime>(_controller.toDate, (DateTime d) {
      _toController.text = _displayDate.format(d);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fromController.dispose();
    _toController.dispose();
    if (Get.isRegistered<EarningsCalendarController>()) {
      Get.delete<EarningsCalendarController>();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime initial =
        isFrom ? _controller.fromDate.value : _controller.toDate.value;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: HomeUi.accent(isDark),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    if (isFrom) {
      _controller.setCustomRange(picked, _controller.toDate.value);
    } else {
      _controller.setCustomRange(_controller.fromDate.value, picked);
    }
  }

  void _openDetail(EarningsCalendarModel item) {
    Get.to(
      () => EarningsDetailScreen(
        args: EarningsDetailArgs.fromModel(item),
      ),
    );
  }

  Future<void> _downloadCsv() async {
    final StringBuffer buf = StringBuffer();
    buf.writeln(
      'date,symbol,hour,quarter,year,epsActual,epsEstimate,revenueActual,revenueEstimate',
    );
    for (final EarningsCalendarModel e in _controller.filteredEvents) {
      buf.writeln(
        '${e.date},${e.symbol},${e.hour ?? ''},${e.quarter ?? ''},${e.year ?? ''},${e.epsActual ?? ''},${e.epsEstimate ?? ''},${e.revenueActual ?? ''},${e.revenueEstimate ?? ''}',
      );
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Earnings CSV copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = HomeUi.pageBg(isDark);
    final Color cardBg = HomeUi.cardBg(isDark);
    final Color border = HomeUi.border(isDark);
    final Color title = HomeUi.title(isDark);
    final Color muted = HomeUi.muted(isDark);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isDark, title, muted, border, cardBg),
            Expanded(
              child: RefreshIndicator(
                color: HomeUi.accent(isDark),
                onRefresh: _controller.refreshCalendar,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _buildHeader(isDark, title, muted),
                    const SizedBox(height: 16),
                    _buildPresetRow(isDark, border, cardBg, muted, title),
                    const SizedBox(height: 12),
                    _buildFilterBar(isDark, border, cardBg, muted, title),
                    Obx(() {
                      final bool custom = _controller.datePreset.value ==
                          EarningsDatePreset.custom;
                      return SizedBox(height: custom ? 16 : 12);
                    }),
                    _buildSummaryStrip(isDark, border, muted, title),
                    const SizedBox(height: 16),
                    _buildTableCard(isDark, cardBg, border, title, muted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    bool isDark,
    Color title,
    Color muted,
    Color border,
    Color cardBg,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menu',
            onPressed: () {
              if (Get.isRegistered<GlobalSidebarService>()) {
                Get.find<GlobalSidebarService>().open();
              }
            },
            icon: Icon(CupertinoIcons.line_horizontal_3, color: muted),
          ),
          IconButton(
            tooltip: 'Back',
            onPressed: () => Get.back(),
            icon: Icon(CupertinoIcons.back, color: muted),
          ),
          const Spacer(),
          SizedBox(
            width: 280,
            height: HomeUi.controlHeight,
            child: TextField(
              controller: _searchController,
              onChanged: _controller.onSearchChanged,
              onSubmitted: _controller.onSearchSubmitted,
              style: HomeUi.control(isDark, active: true),
              decoration: InputDecoration(
                hintText: 'Search by symbol or company',
                hintStyle: HomeUi.control(isDark),
                prefixIcon: Icon(CupertinoIcons.search, size: 16, color: muted),
                filled: true,
                fillColor: HomeUi.elevatedBg(isDark),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                  borderSide: BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                  borderSide: BorderSide(color: HomeUi.accent(isDark)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          HomeUi.ghostAction(
            label: 'Download',
            dark: isDark,
            icon: CupertinoIcons.cloud_download,
            onTap: _downloadCsv,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color title, Color muted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: HomeUi.iconWellGradient,
            borderRadius: BorderRadius.circular(HomeUi.radiusMd),
            border: Border.all(color: HomeUi.iconWellBorder),
          ),
          child: HomeUi.brandIcon(icon: CupertinoIcons.calendar, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Earnings Calendar',
                style: HomeUi.heading(isDark).copyWith(fontSize: 22),
              ),
              const SizedBox(height: 4),
              Text(
                'Get historical and upcoming earnings releases. EPS and Revenue are non-GAAP, adjusted to exclude one-time or unusual items.',
                style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetRow(
    bool isDark,
    Color border,
    Color cardBg,
    Color muted,
    Color title,
  ) {
    return Obx(() {
      final EarningsDatePreset selected = _controller.datePreset.value;
      final List<MapEntry<EarningsDatePreset, String>> presets =
          <MapEntry<EarningsDatePreset, String>>[
        const MapEntry(EarningsDatePreset.yesterday, 'Yesterday'),
        const MapEntry(EarningsDatePreset.today, 'Today'),
        const MapEntry(EarningsDatePreset.tomorrow, 'Tomorrow'),
        const MapEntry(EarningsDatePreset.thisWeek, 'This Week'),
        const MapEntry(EarningsDatePreset.nextWeek, 'Next Week'),
        const MapEntry(EarningsDatePreset.thisMonth, 'This Month'),
        const MapEntry(EarningsDatePreset.custom, 'Custom Range'),
      ];
      final Color accent = HomeUi.accent(isDark);

      return Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: border)),
        ),
        child: Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'International',
                  style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
                ),
                const SizedBox(width: 2),
                Tooltip(
                  message:
                      'Include international (non-US) earnings when enabled.',
                  child: Icon(CupertinoIcons.info, size: 12, color: muted),
                ),
                Transform.scale(
                  scale: 0.65,
                  alignment: Alignment.centerLeft,
                  child: Switch.adaptive(
                    value: _controller.includeInternational.value,
                    activeColor: accent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: _controller.setInternational,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: presets.map((MapEntry<EarningsDatePreset, String> e) {
                    final bool active = selected == e.key;
                    return InkWell(
                      onTap: () {
                        if (e.key == EarningsDatePreset.custom) {
                          _controller.datePreset.value =
                              EarningsDatePreset.custom;
                        } else {
                          _controller.applyDatePreset(e.key);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: active ? accent : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                            fontSize: 13,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.w500,
                            color: active ? accent : muted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterBar(
    bool isDark,
    Color border,
    Color cardBg,
    Color muted,
    Color title,
  ) {
    return Obx(() {
      final bool isCustom =
          _controller.datePreset.value == EarningsDatePreset.custom;
      if (!isCustom) return const SizedBox.shrink();

      final EarningsHourFilter hourFilter = _controller.hourFilter.value;
      final String timeLabel = switch (hourFilter) {
        EarningsHourFilter.all => 'All Hours',
        EarningsHourFilter.bmo => 'Before Market Open',
        EarningsHourFilter.amc => 'After Market Close',
        EarningsHourFilter.dmh => 'During Market Hours',
      };

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(HomeUi.radiusLg),
          border: Border.all(color: border),
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _dateField(
              label: 'From',
              controller: _fromController,
              onTap: () => _pickDate(isFrom: true),
              isDark: isDark,
              border: border,
              muted: muted,
              title: title,
            ),
            _dateField(
              label: 'To',
              controller: _toController,
              onTap: () => _pickDate(isFrom: false),
              isDark: isDark,
              border: border,
              muted: muted,
              title: title,
            ),
            _labeledControl(
              label: 'Markets',
              isDark: isDark,
              child: _controlDropdown(
                icon: CupertinoIcons.globe,
                value: _controller.marketFilter.value,
                items: const <String>['All Markets', 'US Markets'],
                onChanged: (String? v) {
                  if (v != null) _controller.setMarketFilter(v);
                },
                isDark: isDark,
                border: border,
                muted: muted,
                title: title,
              ),
            ),
            _labeledControl(
              label: 'Time',
              isDark: isDark,
              child: _controlDropdown(
                icon: CupertinoIcons.clock,
                value: timeLabel,
                items: const <String>[
                  'All Hours',
                  'Before Market Open',
                  'After Market Close',
                  'During Market Hours',
                ],
                onChanged: (String? v) {
                  if (v == null) return;
                  final EarningsHourFilter mapped = switch (v) {
                    'Before Market Open' => EarningsHourFilter.bmo,
                    'After Market Close' => EarningsHourFilter.amc,
                    'During Market Hours' => EarningsHourFilter.dmh,
                    _ => EarningsHourFilter.all,
                  };
                  _controller.setHourFilter(mapped);
                },
                isDark: isDark,
                border: border,
                muted: muted,
                title: title,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HomeUi.ghostAction(
                  label: 'Clear',
                  dark: isDark,
                  onTap: _controller.clearFilters,
                ),
                const SizedBox(width: 8),
                HomeUi.primaryAction(
                  label: 'Apply Filters',
                  onTap: () {
                    _controller.applyClientFilters();
                    _controller.loadCalendar();
                  },
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _labeledControl({
    required String label,
    required bool isDark,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: HomeUi.filterFieldLabelStyle(isDark)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _dateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    required bool isDark,
    required Color border,
    required Color muted,
    required Color title,
  }) {
    return SizedBox(
      width: 168,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: HomeUi.filterFieldLabelStyle(isDark)),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(HomeUi.radiusMd),
            child: Container(
              height: HomeUi.controlHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                border: Border.all(color: border),
                color: HomeUi.elevatedBg(isDark),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.text,
                      style: HomeUi.control(isDark, active: true),
                    ),
                  ),
                  Icon(CupertinoIcons.calendar, size: 14, color: muted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlDropdown({
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
    required Color border,
    required Color muted,
    required Color title,
  }) {
    return Container(
      height: HomeUi.controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: border),
        color: HomeUi.elevatedBg(isDark),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: Icon(CupertinoIcons.chevron_down, size: 12, color: muted),
          style: HomeUi.control(isDark, active: true),
          items: items
              .map(
                (String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: muted),
                      const SizedBox(width: 6),
                      Text(item),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSummaryStrip(
    bool isDark,
    Color border,
    Color muted,
    Color title,
  ) {
    return Obx(() {
      final int total = _controller.filteredEvents.length;
      final int bmo = _controller.bmoCount;
      final int amc = _controller.amcCount;
      final int dmh = _controller.dmhCount;
      final int unspecified = _controller.unspecifiedHourCount;
      if (total == 0) return const SizedBox.shrink();

      final List<({String key, int count, Color color})> parts =
          <({String key, int count, Color color})>[
        (key: 'BMO', count: bmo, color: _bmo),
        (key: 'AMC', count: amc, color: _amc),
        (key: 'DMH', count: dmh, color: _dmh),
        (key: 'TBD', count: unspecified, color: muted),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$total',
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: title,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'releases',
                style: HomeUi.subtitle(isDark).copyWith(fontSize: 13),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < parts.length; i++) ...[
                        if (i > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Container(
                              width: 1,
                              height: 14,
                              color: border,
                            ),
                          ),
                        _statChip(
                          parts[i].key,
                          parts[i].count,
                          parts[i].color,
                          muted,
                          isDark,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: Row(
                children: [
                  for (final part in parts)
                    if (part.count > 0)
                      Expanded(
                        flex: part.count,
                        child: ColoredBox(color: part.color),
                      ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _statChip(
    String label,
    int count,
    Color color,
    Color muted,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: muted,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTableCard(
    bool isDark,
    Color cardBg,
    Color border,
    Color title,
    Color muted,
  ) {
    return Obx(() {
      final EarningsCalendarLoadState state = _controller.loadState.value;
      final bool resolving = _controller.searchResolving.value;
      final int eventCount = _controller.filteredEvents.length;
      final int currentPage = _controller.page.value;
      // Rebuild when enrichment finishes (logos/names/market cap).
      _controller.isEnriching.value;

      if (state == EarningsCalendarLoadState.loading ||
          state == EarningsCalendarLoadState.initial ||
          resolving) {
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(HomeUi.radiusCard),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.all(48),
          child: Center(
            child: CircularProgressIndicator(color: HomeUi.accent(isDark)),
          ),
        );
      }
      if (state == EarningsCalendarLoadState.error) {
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(HomeUi.radiusCard),
            border: Border.all(color: border),
          ),
          child: _stateMessage(
            icon: CupertinoIcons.exclamationmark_triangle,
            message: _controller.errorMessage.value,
            actionLabel: 'Retry',
            onAction: _controller.refreshCalendar,
            muted: muted,
            title: title,
            isDark: isDark,
          ),
        );
      }
      if (state == EarningsCalendarLoadState.empty || eventCount == 0) {
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(HomeUi.radiusCard),
            border: Border.all(color: border),
          ),
          child: _stateMessage(
            icon: CupertinoIcons.calendar_badge_minus,
            message: _controller.emptyStateMessage(),
            actionLabel: 'Refresh',
            onAction: _controller.refreshCalendar,
            muted: muted,
            title: title,
            isDark: isDark,
          ),
        );
      }

      final List<EarningsCalendarModel> items = _controller.pageItems;
      return Column(
        children: [
          DynamicTable(
            title: 'Earnings Releases',
            subtitle: 'Click a ticker to open earnings detail',
            toolbarLeadingIcon: Icons.calendar_month_outlined,
            showOuterShadow: true,
            columns: _earningsColumns(),
            rows: items
                .map(
                  (EarningsCalendarModel item) =>
                      _toSimpleRow(item, isDark, muted),
                )
                .toList(),
            showFixedColumn: true,
            considerPadding: false,
            columnSpacing: 8,
            fixedColumnWidth: 240,
            enableLivePrices: false,
            zebraStripes: true,
            enableColumnCustomization: true,
            tableId: 'earnings_calendar_table',
            tickerHeaderLabel: 'TICKER',
            onTickerTap: (DynamicTableRow row) {
              final String symbol =
                  row.data['_ticker_symbol']?.toString() ?? '';
              final String date =
                  row.data['_earnings_date']?.toString() ?? '';
              final Iterable<EarningsCalendarModel> match = items.where(
                (EarningsCalendarModel e) =>
                    e.symbol == symbol && e.date == date,
              );
              if (match.isEmpty) return;
              _openDetail(match.first);
            },
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(HomeUi.radiusMd),
              border: Border.all(color: border),
            ),
            child: _pagination(
              isDark,
              border,
              muted,
              keySeed: '$currentPage-$eventCount',
            ),
          ),
        ],
      );
    });
  }

  List<SimpleColumn> _earningsColumns() {
    return const <SimpleColumn>[
      SimpleColumn(label: 'DATE', fieldName: 'date', width: 110),
      SimpleColumn(label: 'TIME', fieldName: 'time', width: 130),
      SimpleColumn(label: 'QUARTER', fieldName: 'quarter', width: 90),
      SimpleColumn(
        label: 'EPS ACTUAL',
        fieldName: 'epsActual',
        isNumeric: true,
        width: 110,
      ),
      SimpleColumn(
        label: 'EPS ESTIMATE',
        fieldName: 'epsEstimate',
        isNumeric: true,
        width: 120,
      ),
      SimpleColumn(
        label: 'REVENUE ACTUAL',
        fieldName: 'revenueActual',
        isNumeric: true,
        width: 130,
      ),
      SimpleColumn(
        label: 'REVENUE ESTIMATE',
        fieldName: 'revenueEstimate',
        isNumeric: true,
        width: 140,
      ),
    ];
  }

  SimpleRowModel _toSimpleRow(
    EarningsCalendarModel item,
    bool isDark,
    Color muted,
  ) {
    final CompanyEnrichment? enrichment =
        CompanyEnrichmentCache.getCached(item.symbol);
    final bool logoPending = !CompanyEnrichmentCache.hasCached(item.symbol);
    final String companyName = enrichment?.name?.trim().isNotEmpty == true
        ? enrichment!.name!
        : item.symbol;
    final String logo =
        logoPending ? '__loading__' : (enrichment?.logo ?? '');

    String dateLabel = item.date.isEmpty ? '—' : item.date;
    try {
      if (item.date.isNotEmpty) {
        dateLabel =
            DateFormat('MMM d, yyyy').format(DateTime.parse(item.date));
      }
    } catch (_) {}

    final String hourKey = (item.hour ?? '').trim().toLowerCase();
    final String timeLabel = FinnhubDisplayFormatters.formatHourBadge(item.hour);
    final String timeSubtitle =
        FinnhubDisplayFormatters.formatAnnouncementHour(item.hour);

    return SimpleRowModel(
      symbol: item.symbol,
      name: companyName,
      logo: logo,
      fields: <String, dynamic>{
        '_row_id': '${item.symbol}_${item.date}_${item.hour ?? ''}',
        '_earnings_date': item.date,
        'date': dateLabel,
        'time': _timeBadgeWidget(hourKey, timeLabel, timeSubtitle, isDark, muted),
        'quarter': item.quarterLabel,
        'epsActual': item.epsActual == null
            ? '—'
            : '\$${item.epsActual!.toStringAsFixed(2)}',
        'epsEstimate': item.epsEstimate == null
            ? '—'
            : '\$${item.epsEstimate!.toStringAsFixed(2)}',
        'revenueActual':
            FinnhubDisplayFormatters.formatCompactCurrency(item.revenueActual),
        'revenueEstimate':
            FinnhubDisplayFormatters.formatCompactCurrency(item.revenueEstimate),
      },
    );
  }

  Widget _timeBadgeWidget(
    String hourKey,
    String badge,
    String subtitle,
    bool isDark,
    Color muted,
  ) {
    final Color badgeBg = switch (hourKey) {
      'bmo' => const Color(0xFFECFDF5),
      'amc' => const Color(0xFFEFF6FF),
      'dmh' => const Color(0xFFFFF7ED),
      _ => HomeUi.elevatedBg(isDark),
    };
    final Color badgeFg = switch (hourKey) {
      'bmo' => _bmo,
      'amc' => _amc,
      'dmh' => _dmh,
      _ => muted,
    };
    final bool hasBadge = badge == 'BMO' || badge == 'AMC' || badge == 'DMH';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeFg,
              ),
            ),
          )
        else
          Text(
            '—',
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 12,
              color: muted,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 10,
            color: muted,
          ),
        ),
      ],
    );
  }

  Widget _stateMessage({
    required IconData icon,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    required Color muted,
    required Color title,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 36, color: muted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: HomeUi.bodyText(isDark),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: TextStyle(color: HomeUi.accent(isDark)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pagination(
    bool isDark,
    Color border,
    Color muted, {
    String? keySeed,
  }) {
    final int eventCount = _controller.filteredEvents.length;
    final int pageSize = _controller.pageSize.value;
    final int total =
        eventCount == 0 ? 1 : ((eventCount - 1) ~/ pageSize) + 1;
    final int current = _controller.page.value;
    final List<int> pages = _pageWindow(current, total);
    final int start = eventCount == 0 ? 0 : (current - 1) * pageSize + 1;
    final int end = (current * pageSize).clamp(0, eventCount);
    final String showing = eventCount == 0
        ? 'Showing 0 events'
        : 'Showing $start to $end of $eventCount events.';

    return Padding(
      key: ValueKey<String>('pagination-${keySeed ?? '$current-$eventCount'}'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: current > 1
                      ? () => _controller.goToPage(current - 1)
                      : null,
                  icon: Icon(
                    CupertinoIcons.chevron_left,
                    size: 16,
                    color: muted,
                  ),
                ),
                for (final int p in pages)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => _controller.goToPage(p),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: p == current
                                ? HomeUi.accent(isDark)
                                : border,
                          ),
                          gradient: p == current
                              ? HomeUi.iconWellGradient
                              : null,
                        ),
                        child: Text(
                          '$p',
                          style: TextStyle(
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p == current
                                ? HomeUi.accent(isDark)
                                : muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: current < total
                      ? () => _controller.goToPage(current + 1)
                      : null,
                  icon: Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            showing,
            style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<int> _pageWindow(int current, int total) {
    if (total <= 7) {
      return List<int>.generate(total, (int i) => i + 1);
    }
    int start = (current - 2).clamp(1, total);
    int end = (start + 4).clamp(1, total);
    start = (end - 4).clamp(1, total);
    return List<int>.generate(end - start + 1, (int i) => start + i);
  }
}
