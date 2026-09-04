import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/Components/dynamic_table_from_web.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Components/app_sidebar.dart';
import 'package:musaffa_terminal/Components/sliding_pill_tabs.dart';
import 'package:musaffa_terminal/Components/table_pagination_bar.dart';
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
  bool _searchFocused = false;
  bool _searchHover = false;

  static const Color _amc = Color(0xFF2563EB);
  static const Color _dmh = Color(0xFFEAB308);

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
    final DateTime initial =
        isFrom ? _controller.fromDate.value : _controller.toDate.value;
    final DateTime? picked = await HomeUi.pickDate(
      context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
      SnackBar(
        content: const Text('Earnings CSV copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        ),
      ),
    );
  }

  Color _hourColor(String hourKey, bool isDark, Color muted) {
    return switch (hourKey) {
      'bmo' => HomeUi.positive(isDark),
      'amc' => isDark ? const Color(0xFF60A5FA) : _amc,
      'dmh' => isDark ? const Color(0xFFFBBF24) : _dmh,
      _ => muted,
    };
  }

  Color _hourSoftBg(String hourKey, bool isDark) {
    final Color muted = HomeUi.muted(isDark);
    final Color c = _hourColor(hourKey, isDark, muted);
    if (hourKey.isEmpty) return HomeUi.elevatedBg(isDark);
    return c.withValues(alpha: isDark ? 0.20 : 0.12);
  }

  Color _hourBorder(String hourKey, bool isDark) {
    final Color muted = HomeUi.muted(isDark);
    final Color c = _hourColor(hourKey, isDark, muted);
    if (hourKey.isEmpty) return HomeUi.borderLight(isDark);
    return c.withValues(alpha: 0.28);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = HomeUi.pageBg(isDark);
    final Color cardBg = HomeUi.cardBg(isDark);
    final Color border = HomeUi.borderLight(isDark);
    final Color title = HomeUi.title(isDark);
    final Color muted = HomeUi.muted(isDark);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            final EdgeInsets pagePad = HomeUi.pagePadding(width);
            final bool compact = width < 900;
            final bool narrow = width < 700;

            return Column(
              children: [
                _buildTopBar(
                  isDark,
                  title,
                  muted,
                  border,
                  cardBg,
                  compact: compact,
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: HomeUi.accent(isDark),
                    backgroundColor: cardBg,
                    onRefresh: _controller.refreshCalendar,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(14, 12, 14, pagePad.bottom),
                      children: [
                        _buildHeader(
                          isDark,
                          title,
                          muted,
                          narrow: narrow,
                          compact: compact,
                        ),
                        const SizedBox(height: 12),
                        _buildPresetRow(
                          isDark,
                          border,
                          cardBg,
                          muted,
                          title,
                          compact: compact,
                        ),
                        _buildFilterBar(
                          isDark,
                          border,
                          cardBg,
                          muted,
                          title,
                          compact: compact,
                        ),
                        const SizedBox(height: 10),
                        _buildSummaryStrip(
                          isDark,
                          border,
                          muted,
                          title,
                          compact: compact,
                        ),
                        const SizedBox(height: 12),
                        _buildTableCard(
                          isDark,
                          cardBg,
                          border,
                          title,
                          muted,
                          compact: compact,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(
    bool isDark,
    Color title,
    Color muted,
    Color border,
    Color cardBg, {
    required bool compact,
  }) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double searchWidth =
        compact ? double.infinity : (screenWidth * 0.45).clamp(300.0, 520.0);
    final bool searchActive = _searchFocused || _searchHover;
    final Color searchBorder = _searchFocused
        ? const Color(0xFFC42329).withValues(alpha: isDark ? 0.55 : 0.42)
        : HomeUi.borderStrong(isDark);
    final BorderRadius searchRadius = BorderRadius.circular(HomeUi.radiusMd);

    OutlineInputBorder searchOutline(Color color, double width) =>
        OutlineInputBorder(
          borderRadius: searchRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    final Widget searchField = MouseRegion(
      onEnter: (_) => setState(() => _searchHover = true),
      onExit: (_) => setState(() => _searchHover = false),
      cursor: SystemMouseCursors.text,
      child: Focus(
        onFocusChange: (bool focused) =>
            setState(() => _searchFocused = focused),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: compact ? null : searchWidth,
          height: HomeUi.controlHeight,
          decoration: BoxDecoration(
            borderRadius: searchRadius,
            boxShadow: _searchFocused
                ? <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFFC42329)
                          .withValues(alpha: isDark ? 0.18 : 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : HomeUi.cardShadow(isDark, hover: true),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (String value) {
              _controller.onSearchChanged(value);
              setState(() {});
            },
            onSubmitted: _controller.onSearchSubmitted,
            textInputAction: TextInputAction.search,
            cursorColor: const Color(0xFFC42329),
            cursorWidth: 1.2,
            cursorHeight: 14,
            style: HomeUi.control(isDark, active: true).copyWith(
              fontSize: 14,
              height: 1.2,
              color: HomeUi.title(isDark),
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: HomeUi.cardBg(isDark),
              hintText: 'Search by symbol or company',
              hintStyle: HomeUi.subtitle(isDark).copyWith(
                fontSize: 13.5,
                height: 1.2,
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 4),
                child: searchActive
                    ? HomeUi.brandIcon(
                        icon: CupertinoIcons.search,
                        size: HomeUi.iconMd,
                        gradient: HomeUi.iconFillGradient,
                      )
                    : HomeUi.vectorIcon(
                        icon: CupertinoIcons.search,
                        size: HomeUi.iconMd,
                        color: HomeUi.muted(isDark),
                      ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: HomeUi.controlHeight,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: HomeUi.controlHeight,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _controller.onSearchChanged('');
                        setState(() {});
                      },
                      icon: HomeUi.vectorIcon(
                        icon: CupertinoIcons.xmark_circle_fill,
                        size: HomeUi.iconSm,
                        color: HomeUi.muted(isDark),
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 28,
                minHeight: HomeUi.controlHeight,
              ),
              border: searchOutline(searchBorder, searchActive ? 1 : 0.5),
              enabledBorder:
                  searchOutline(searchBorder, searchActive ? 1 : 0.5),
              focusedBorder: searchOutline(searchBorder, 1),
            ),
          ),
        ),
      ),
    );

    final Widget backButton = _EarningsBackButton(isDark: isDark);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            HomeUi.headerBg(isDark),
            isDark ? const Color(0xFF101317) : const Color(0xFFFBFBFC),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2A2F33) : const Color(0xFFE8EAED),
            width: 0.5,
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
            blurRadius: isDark ? 16 : 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SidebarMenuButton(isDarkMode: isDark),
                    const SizedBox(width: 12),
                    backButton,
                    const SizedBox(width: 10),
                    Text(
                      'Earnings',
                      style: HomeUi.wordmark(isDark).copyWith(fontSize: 14),
                    ),
                    const Spacer(),
                    HomeUi.ghostAction(
                      label: 'Download',
                      dark: isDark,
                      icon: CupertinoIcons.cloud_download,
                      onTap: _downloadCsv,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                searchField,
              ],
            )
          : Row(
              children: [
                SidebarMenuButton(isDarkMode: isDark),
                const SizedBox(width: 12),
                backButton,
                const SizedBox(width: 10),
                Text(
                  'Earnings',
                  style: HomeUi.wordmark(isDark).copyWith(fontSize: 14),
                ),
                const Spacer(),
                searchField,
                const SizedBox(width: 12),
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

  Widget _buildHeader(
    bool isDark,
    Color title,
    Color muted, {
    required bool narrow,
    required bool compact,
  }) {
    return Obx(() {
      final String rangeLabel =
          '${_displayDate.format(_controller.fromDate.value)}  –  ${_displayDate.format(_controller.toDate.value)}';
      final String presetLabel = switch (_controller.datePreset.value) {
        EarningsDatePreset.yesterday => 'Yesterday',
        EarningsDatePreset.today => 'Today',
        EarningsDatePreset.tomorrow => 'Tomorrow',
        EarningsDatePreset.thisWeek => 'This Week',
        EarningsDatePreset.nextWeek => 'Next Week',
        EarningsDatePreset.thisMonth => 'This Month',
        EarningsDatePreset.custom => 'Custom Range',
      };

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _PremiumCalendarIcon(size: 40, glyphSize: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earnings Calendar',
                      style: HomeUi.heading(isDark).copyWith(
                        fontSize: narrow ? 20 : 22,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Non-GAAP EPS & revenue · adjusted for one-time items',
                      style: HomeUi.subtitle(isDark).copyWith(
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 12),
                _RangeChip(
                  isDark: isDark,
                  label: presetLabel,
                  value: rangeLabel,
                ),
              ],
            ],
          ),
          if (compact) ...[
            const SizedBox(height: 10),
            _RangeChip(
              isDark: isDark,
              label: presetLabel,
              value: rangeLabel,
            ),
          ],
        ],
      );
    });
  }

  Widget _buildPresetRow(
    bool isDark,
    Color border,
    Color cardBg,
    Color muted,
    Color title, {
    required bool compact,
  }) {
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
        const MapEntry(EarningsDatePreset.custom, 'Custom'),
      ];
      final int selectedIndex =
          presets.indexWhere((MapEntry<EarningsDatePreset, String> e) => e.key == selected)
              .clamp(0, presets.length - 1);

      final Widget internationalToggle = _InternationalToggle(
        isDark: isDark,
        value: _controller.includeInternational.value,
        onChanged: _controller.setInternational,
      );

      final Widget presetTabs = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SlidingPillTabs(
          itemCount: presets.length,
          selectedIndex: selectedIndex,
          isDarkMode: isDark,
          onSelect: (int index) {
            final EarningsDatePreset preset = presets[index].key;
            if (preset == EarningsDatePreset.custom) {
              _controller.datePreset.value = EarningsDatePreset.custom;
            } else {
              _controller.applyDatePreset(preset);
            }
          },
          itemBuilder: (BuildContext context, int index, bool isSelected) {
            return Text(
              presets[index].value,
              style: HomeUi.control(isDark, active: isSelected).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : HomeUi.muted(isDark),
              ),
            );
          },
        ),
      );

      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          border: Border.all(color: HomeUi.borderLight(isDark)),
          boxShadow: HomeUi.cardShadow(isDark),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Date window',
                        style: HomeUi.filterFieldLabelStyle(isDark),
                      ),
                      const Spacer(),
                      internationalToggle,
                    ],
                  ),
                  const SizedBox(height: 8),
                  presetTabs,
                ],
              )
            : Row(
                children: [
                  Expanded(child: presetTabs),
                  const SizedBox(width: 12),
                  internationalToggle,
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
    Color title, {
    required bool compact,
  }) {
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

      return AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 14,
              12,
              compact ? 12 : 14,
              12,
            ),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(HomeUi.radiusCard),
              border: Border.all(color: HomeUi.borderLight(isDark)),
              boxShadow: HomeUi.cardShadow(isDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    _dateField(
                      label: 'From',
                      controller: _fromController,
                      onTap: () => _pickDate(isFrom: true),
                      isDark: isDark,
                    ),
                    _dateField(
                      label: 'To',
                      controller: _toController,
                      onTap: () => _pickDate(isFrom: false),
                      isDark: isDark,
                    ),
                    SizedBox(
                      width: 188,
                      child: FilterDropdown<String>(
                        dark: isDark,
                        label: 'Markets',
                        value: _controller.marketFilter.value,
                        items: const <String>['All Markets', 'US Markets']
                            .map(
                              (String item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (String? v) {
                          if (v != null) _controller.setMarketFilter(v);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 210,
                      child: FilterDropdown<String>(
                        dark: isDark,
                        label: 'Time',
                        value: timeLabel,
                        items: const <String>[
                          'All Hours',
                          'Before Market Open',
                          'After Market Close',
                          'During Market Hours',
                        ]
                            .map(
                              (String item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
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
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HomeUi.ghostAction(
                            label: 'Clear',
                            dark: isDark,
                            icon: Icons.close_rounded,
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _dateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return SizedBox(
      width: 176,
      child: _PremiumDateFilterField(
        isDark: isDark,
        label: label,
        value: controller.text,
        onTap: onTap,
      ),
    );
  }

  Widget _buildSummaryStrip(
    bool isDark,
    Color border,
    Color muted,
    Color title, {
    required bool compact,
  }) {
    return Obx(() {
      final int total = _controller.filteredEvents.length;
      final int bmo = _controller.bmoCount;
      final int amc = _controller.amcCount;
      final int dmh = _controller.dmhCount;
      final int unspecified = _controller.unspecifiedHourCount;
      if (total == 0) return const SizedBox.shrink();

      final List<({String key, int count, String hourKey})> parts =
          <({String key, int count, String hourKey})>[
        (key: 'BMO', count: bmo, hourKey: 'bmo'),
        (key: 'AMC', count: amc, hourKey: 'amc'),
        (key: 'DMH', count: dmh, hourKey: 'dmh'),
        (key: 'TBD', count: unspecified, hourKey: ''),
      ];

      return Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: HomeUi.cardBg(isDark),
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          border: Border.all(color: HomeUi.borderLight(isDark)),
          boxShadow: HomeUi.cardShadow(isDark),
        ),
        alignment: Alignment.center,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$total',
              style: HomeUi.tableCellEmphasis(isDark).copyWith(
                fontSize: 18,
                letterSpacing: -0.4,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                total == 1 ? 'release' : 'releases',
                style: HomeUi.subtitle(isDark).copyWith(
                  fontSize: 12.5,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (int i = 0; i < parts.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _InlineTimingStat(
                        badge: parts[i].key,
                        count: parts[i].count,
                        color: _hourColor(parts[i].hourKey, isDark, muted),
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: compact ? 72 : 110,
              height: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                child: Row(
                  children: [
                    for (final part in parts)
                      if (part.count > 0)
                        Expanded(
                          flex: part.count,
                          child: ColoredBox(
                            color: _hourColor(part.hourKey, isDark, muted),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTableCard(
    bool isDark,
    Color cardBg,
    Color border,
    Color title,
    Color muted, {
    required bool compact,
  }) {
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
          decoration: HomeUi.cardDecoration(isDark),
          padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 32),
          child: Column(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: HomeUi.accent(isDark),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading earnings releases…',
                style: HomeUi.subtitle(isDark),
              ),
            ],
          ),
        );
      }
      if (state == EarningsCalendarLoadState.error) {
        return Container(
          decoration: HomeUi.cardDecoration(isDark),
          child: _stateMessage(
            icon: CupertinoIcons.exclamationmark_triangle,
            titleText: 'Unable to load earnings',
            message: _controller.errorMessage.value,
            actionLabel: 'Retry',
            onAction: _controller.refreshCalendar,
            muted: muted,
            title: title,
            isDark: isDark,
            showSuggestions: false,
          ),
        );
      }
      if (state == EarningsCalendarLoadState.empty || eventCount == 0) {
        return Container(
          decoration: HomeUi.cardDecoration(isDark),
          child: _stateMessage(
            icon: CupertinoIcons.calendar_badge_minus,
            titleText: 'No releases in this window',
            message: _controller.emptyStateMessage(),
            actionLabel: 'Refresh',
            onAction: _controller.refreshCalendar,
            muted: muted,
            title: title,
            isDark: isDark,
            showSuggestions: true,
          ),
        );
      }

      final List<EarningsCalendarModel> items = _controller.pageItems;
      return Container(
        decoration: HomeUi.cardDecoration(isDark),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            DynamicTable(
              title: 'Earnings Releases',
              subtitle: 'Click a ticker to open earnings detail',
              toolbarLeadingIcon: Icons.calendar_month_outlined,
              showOuterShadow: false,
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
              fixedColumnWidth: compact ? 200 : 248,
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
            _pagination(
              isDark,
              compact: compact,
              keySeed: '$currentPage-$eventCount',
            ),
          ],
        ),
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
    final Color badgeBg = _hourSoftBg(hourKey, isDark);
    final Color badgeFg = _hourColor(hourKey, isDark, muted);
    final Color badgeBorder = _hourBorder(hourKey, isDark);
    final bool hasBadge = badge == 'BMO' || badge == 'AMC' || badge == 'DMH';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: badgeBorder),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontFamilyFallback: Constants.FONT_FALLBACK,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                height: 1.1,
                color: badgeFg,
              ),
            ),
          )
        else
          Text(
            '—',
            style: HomeUi.tableCellSecondary(isDark),
          ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: HomeUi.label(isDark).copyWith(
            fontSize: 10.5,
            letterSpacing: 0.05,
          ),
        ),
      ],
    );
  }

  Widget _stateMessage({
    required IconData icon,
    required String titleText,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    required Color muted,
    required Color title,
    required bool isDark,
    required bool showSuggestions,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HomeUi.elevatedBg(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HomeUi.borderLight(isDark)),
            ),
            child: Icon(icon, size: 22, color: muted),
          ),
          const SizedBox(height: 16),
          Text(
            titleText,
            textAlign: TextAlign.center,
            style: HomeUi.sectionTitle(isDark).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: HomeUi.bodyText(isDark).copyWith(height: 1.5, fontSize: 13),
            ),
          ),
          const SizedBox(height: 18),
          HomeUi.ghostAction(
            label: actionLabel,
            dark: isDark,
            icon: actionLabel == 'Refresh'
                ? CupertinoIcons.refresh
                : CupertinoIcons.arrow_clockwise,
            onTap: onAction,
          ),
          if (showSuggestions) ...[
            const SizedBox(height: 22),
            Text(
              'Try another window',
              style: HomeUi.filterFieldLabelStyle(isDark),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: <Widget>[
                _SuggestionChip(
                  isDark: isDark,
                  label: 'This Week',
                  onTap: () =>
                      _controller.applyDatePreset(EarningsDatePreset.thisWeek),
                ),
                _SuggestionChip(
                  isDark: isDark,
                  label: 'Next Week',
                  onTap: () =>
                      _controller.applyDatePreset(EarningsDatePreset.nextWeek),
                ),
                _SuggestionChip(
                  isDark: isDark,
                  label: 'This Month',
                  onTap: () =>
                      _controller.applyDatePreset(EarningsDatePreset.thisMonth),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _pagination(
    bool isDark, {
    required bool compact,
    String? keySeed,
  }) {
    final int eventCount = _controller.filteredEvents.length;
    final int pageSize = _controller.pageSize.value;
    final int totalPages =
        eventCount == 0 ? 1 : ((eventCount - 1) ~/ pageSize) + 1;
    final int current = _controller.page.value;

    String commaNumber(int value) {
      final String s = value.toString();
      final StringBuffer buf = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }

    return TablePaginationBar(
      key: ValueKey<String>('pagination-${keySeed ?? '$current-$eventCount'}'),
      isDark: isDark,
      currentPage: current,
      totalPages: totalPages,
      summaryText: '${commaNumber(eventCount)} events',
      compact: compact,
      rowsPerPage: pageSize,
      onRowsPerPageChanged: _controller.setPageSize,
      onPageChanged: _controller.goToPage,
    );
  }
}

class _PremiumDateFilterField extends StatefulWidget {
  const _PremiumDateFilterField({
    required this.isDark,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final bool isDark;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  State<_PremiumDateFilterField> createState() =>
      _PremiumDateFilterFieldState();
}

class _PremiumDateFilterFieldState extends State<_PremiumDateFilterField> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return HomeUi.filterFieldColumn(
      dark: widget.isDark,
      label: widget.label,
      field: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: HomeUi.filterFieldShell(
            dark: widget.isDark,
            hover: _hover,
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HomeUi.control(widget.isDark, active: true).copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const _PremiumCalendarIcon(size: 24, glyphSize: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InternationalToggle extends StatelessWidget {
  const _InternationalToggle({
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  final bool isDark;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'International',
          style: HomeUi.control(isDark, active: true).copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          waitDuration: const Duration(milliseconds: 280),
          showDuration: const Duration(seconds: 5),
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.only(top: 8),
          decoration: const BoxDecoration(color: Colors.transparent),
          richMessage: WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: HomeUi.cardBg(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HomeUi.borderLight(isDark)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'International markets',
                      style: HomeUi.sectionTitle(isDark).copyWith(
                        fontSize: 12.5,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'When enabled, earnings from non-US exchanges are included alongside US listings.',
                      style: HomeUi.subtitle(isDark).copyWith(
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          child: Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: HomeUi.iconWellGradient,
              shape: BoxShape.circle,
              border: Border.all(color: HomeUi.iconWellBorder),
            ),
            child: HomeUi.brandIcon(
              icon: Icons.info_outline_rounded,
              size: 11,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _PremiumMiniToggle(
          isDark: isDark,
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PremiumMiniToggle extends StatefulWidget {
  const _PremiumMiniToggle({
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  final bool isDark;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<_PremiumMiniToggle> createState() => _PremiumMiniToggleState();
}

class _PremiumMiniToggleState extends State<_PremiumMiniToggle> {
  bool _hover = false;
  bool _pressed = false;

  static const double _width = 36;
  static const double _height = 20;
  static const double _thumb = 14;
  static const double _pad = 3;

  @override
  Widget build(BuildContext context) {
    final bool on = widget.value;
    final bool dark = widget.isDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
            _hover = false;
            _pressed = false;
          }),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () => widget.onChanged(!on),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: _width,
            height: _height,
            padding: const EdgeInsets.all(_pad),
            decoration: BoxDecoration(
              gradient: on ? HomeUi.iconFillGradient : null,
              color: on
                  ? null
                  : (_hover
                      ? HomeUi.borderStrong(dark)
                      : (dark
                          ? const Color(0xFF3A4048)
                          : const Color(0xFFD5D8DE))),
              borderRadius: BorderRadius.circular(HomeUi.radiusPill),
              border: Border.all(
                color: on
                    ? HomeUi.buttonBorder
                    : HomeUi.borderStrong(dark).withValues(alpha: 0.65),
                width: 0.8,
              ),
              boxShadow: on
                  ? <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFFE4621E)
                            .withValues(alpha: dark ? 0.28 : 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: on ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: _thumb,
                height: _thumb,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumCalendarIcon extends StatelessWidget {
  const _PremiumCalendarIcon({
    this.size = 24,
    this.glyphSize = 12,
  });

  final double size;
  final double glyphSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: HomeUi.iconWellGradient,
        shape: BoxShape.circle,
        border: Border.all(color: HomeUi.iconWellBorder),
      ),
      child: HomeUi.brandIcon(
        icon: Icons.calendar_today_rounded,
        size: glyphSize,
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.isDark,
    required this.label,
    required this.value,
  });

  final bool isDark;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
      decoration: BoxDecoration(
        color: HomeUi.elevatedBg(isDark),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PremiumCalendarIcon(size: 24, glyphSize: 12),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: HomeUi.overline(isDark).copyWith(
                  fontSize: 9,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: HomeUi.control(isDark, active: true).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineTimingStat extends StatelessWidget {
  const _InlineTimingStat({
    required this.badge,
    required this.count,
    required this.color,
    required this.isDark,
  });

  final String badge;
  final int count;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bool empty = count == 0;
    final Color fg = empty ? HomeUi.muted(isDark) : color;
    final Color bg = empty
        ? HomeUi.elevatedBg(isDark)
        : color.withValues(alpha: isDark ? 0.20 : 0.12);
    final Color border = empty
        ? HomeUi.borderLight(isDark)
        : color.withValues(alpha: 0.28);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 9, 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            badge,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontFamilyFallback: Constants.FONT_FALLBACK,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              height: 1,
              color: fg,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: HomeUi.tableCellEmphasis(isDark).copyWith(
              fontSize: 12,
              height: 1,
              fontWeight: FontWeight.w700,
              color: fg,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  const _SuggestionChip({
    required this.isDark,
    required this.label,
    required this.onTap,
  });

  final bool isDark;
  final String label;
  final VoidCallback onTap;

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hover
                ? HomeUi.accentSoft(widget.isDark)
                : HomeUi.cardBg(widget.isDark),
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            border: Border.all(
              color: _hover
                  ? HomeUi.accent(widget.isDark)
                      .withValues(alpha: widget.isDark ? 0.4 : 0.3)
                  : HomeUi.borderLight(widget.isDark),
            ),
          ),
          child: Text(
            widget.label,
            style: HomeUi.control(widget.isDark, active: true).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _hover
                  ? HomeUi.accent(widget.isDark)
                  : HomeUi.title(widget.isDark),
            ),
          ),
        ),
      ),
    );
  }
}

class _EarningsBackButton extends StatefulWidget {
  const _EarningsBackButton({required this.isDark});

  final bool isDark;

  @override
  State<_EarningsBackButton> createState() => _EarningsBackButtonState();
}

class _EarningsBackButtonState extends State<_EarningsBackButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.isDark;
    final Color color = _hovering
        ? (dark ? const Color(0xFFFFFFFF) : const Color(0xFF111827))
        : (dark ? const Color(0xFFB0B7C3) : const Color(0xFF6B7280));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Get.back(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }
}
