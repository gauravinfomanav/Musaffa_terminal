import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/shariah_compliance/shariah_compliance_details_screen.dart';
import 'package:musaffa_terminal/shariah_compliance/shariah_compliance_etf_details_screen.dart';
import 'package:musaffa_terminal/shariah_compliance/services/shariah_compliance_search_service.dart';
import 'package:musaffa_terminal/shariah_compliance/widgets/compliance_shared_widgets.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';

class ShariahComplianceScreen extends StatefulWidget {
  const ShariahComplianceScreen({super.key});

  @override
  State<ShariahComplianceScreen> createState() =>
      _ShariahComplianceScreenState();
}

class _ShariahComplianceScreenState extends State<ShariahComplianceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _screenFocusNode = FocusNode();
  final ShariahComplianceSearchService _searchService =
      ShariahComplianceSearchService();
  List<TickerModel> _searchResults = <TickerModel>[];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _screenFocusNode.dispose();
    _searchService.dispose();
    super.dispose();
  }

  void _closeScreen() {
    Navigator.of(context).maybePop();
  }

  void _onSearchChanged(String value) {
    final String query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = <TickerModel>[];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _searchService.searchTickersDebounced(
      query,
      onResults: (List<TickerModel> results) {
        if (!mounted || _searchController.text.trim() != query) {
          return;
        }

        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      },
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = <TickerModel>[];
    });
    _searchFocusNode.requestFocus();
  }

  void _selectTicker(TickerModel ticker) {
    final String symbol = (ticker.symbol ?? ticker.ticker ?? '').trim();
    if (symbol.isEmpty) return;

    final String? name = ticker.companyName ?? ticker.name ?? ticker.stockName;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ticker.isStock
            ? ShariahComplianceDetailsScreen(
                tickerSymbol: symbol,
                companyName: name,
                ticker: ticker,
              )
            : ShariahComplianceEtfDetailsScreen(
                tickerSymbol: symbol,
                companyName: name,
                ticker: ticker,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasQuery = _searchController.text.isNotEmpty;

    return FeatureGuard(
      featureKey: FeatureKeys.shariahCompliance,
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): _closeScreen,
        },
        child: Focus(
          autofocus: true,
          focusNode: _screenFocusNode,
          child: Scaffold(
            backgroundColor: HomeUi.pageBg(isDark),
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    right: 20,
                    child: HomeUi.ghostAction(
                      label: 'Esc',
                      dark: isDark,
                      icon: Icons.close_rounded,
                      onTap: _closeScreen,
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const MusaffaLogo(height: 28),
                            const SizedBox(height: 22),
                            Text(
                              'SHARIAH SCREENING',
                              style: HomeUi.overline(isDark),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Shariah Stock & ETF Screener',
                              textAlign: TextAlign.center,
                              style: HomeUi.heading(isDark).copyWith(
                                fontSize: 28,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Find Shariah compliance details for any stock or ETF.',
                              textAlign: TextAlign.center,
                              style: HomeUi.subtitle(isDark),
                            ),
                            const SizedBox(height: 28),
                            AnimatedBuilder(
                              animation: _searchFocusNode,
                              builder: (context, _) {
                                final bool hasFocus = _searchFocusNode.hasFocus;
                                return HomeUi.filterFieldShell(
                                  dark: isDark,
                                  accent: hasFocus,
                                  hover: hasFocus,
                                  height: 52,
                                  radius: HomeUi.radiusCard,
                                  padding: const EdgeInsets.only(
                                    left: 6,
                                    right: 6,
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    cursorColor: const Color(0xFFC42329),
                                    cursorWidth: 1.2,
                                    textInputAction: TextInputAction.search,
                                    onChanged: (value) {
                                      setState(() {});
                                      _onSearchChanged(value);
                                    },
                                    style: HomeUi.control(isDark, active: true)
                                        .copyWith(
                                      fontSize: 14,
                                      height: 1.2,
                                      color: HomeUi.title(isDark),
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText:
                                          'Search stocks and ETFs for Shariah compliance',
                                      hintStyle:
                                          HomeUi.subtitle(isDark).copyWith(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8,
                                          right: 4,
                                        ),
                                        child: hasFocus
                                            ? HomeUi.brandIcon(
                                                icon: Icons.search_rounded,
                                                size: HomeUi.iconMd,
                                                gradient:
                                                    HomeUi.iconFillGradient,
                                              )
                                            : HomeUi.vectorIcon(
                                                icon: Icons.search_rounded,
                                                size: HomeUi.iconMd,
                                                color: HomeUi.muted(isDark),
                                              ),
                                      ),
                                      prefixIconConstraints:
                                          const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      suffixIcon: hasQuery
                                          ? IconButton(
                                              tooltip: 'Clear',
                                              onPressed: _clearSearch,
                                              icon: HomeUi.vectorIcon(
                                                icon: Icons.close_rounded,
                                                size: HomeUi.iconSm,
                                                color: HomeUi.muted(isDark),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (_isSearching || _searchResults.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                decoration: HomeUi.cardDecoration(isDark),
                                clipBehavior: Clip.antiAlias,
                                child: _isSearching
                                    ? const ComplianceSearchResultsShimmer(
                                        itemCount: 4,
                                      )
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: _searchResults
                                            .asMap()
                                            .entries
                                            .map(
                                              (entry) => _SearchSuggestionTile(
                                                ticker: entry.value,
                                                isLast: entry.key ==
                                                    _searchResults.length - 1,
                                                isDark: isDark,
                                                onTap: () =>
                                                    _selectTicker(entry.value),
                                              ),
                                            )
                                            .toList(),
                                      ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: const [
                                _FeatureChip(
                                  icon: Icons.verified_outlined,
                                  label: 'Compliance status',
                                ),
                                _FeatureChip(
                                  icon: Icons.business_center_outlined,
                                  label: 'Business screening',
                                ),
                                _FeatureChip(
                                  icon: Icons.bar_chart_rounded,
                                  label: 'Financial ratios',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Press Esc or click × to return to terminal',
                              textAlign: TextAlign.center,
                              style: HomeUi.subtitle(isDark).copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
      decoration: BoxDecoration(
        color: HomeUi.cardBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusPill),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: HomeUi.iconWellGradient,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: HomeUi.iconWellBorder),
            ),
            child: HomeUi.brandIcon(
              icon: icon,
              size: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: HomeUi.control(isDark, active: true).copyWith(
              fontSize: 12,
              color: HomeUi.body(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchSuggestionTile extends StatefulWidget {
  const _SearchSuggestionTile({
    required this.ticker,
    required this.isLast,
    required this.isDark,
    required this.onTap,
  });

  final TickerModel ticker;
  final bool isLast;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_SearchSuggestionTile> createState() => _SearchSuggestionTileState();
}

class _SearchSuggestionTileState extends State<_SearchSuggestionTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDark;
    final String symbol = widget.ticker.symbol ?? widget.ticker.ticker ?? '-';
    final String name = widget.ticker.companyName ??
        widget.ticker.name ??
        widget.ticker.stockName ??
        'Unknown';
    final String meta = [
      if ((widget.ticker.exchange ?? '').isNotEmpty) widget.ticker.exchange!,
      if ((widget.ticker.countryName ?? '').isNotEmpty)
        widget.ticker.countryName!,
    ].join(' · ');

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _hover ? HomeUi.tableRowHover(isDark) : Colors.transparent,
            border: widget.isLast
                ? null
                : Border(
                    bottom: BorderSide(color: HomeUi.borderLight(isDark)),
                  ),
          ),
          child: Row(
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 56),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: HomeUi.iconWellGradient,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: HomeUi.iconWellBorder),
                ),
                child: Text(
                  symbol,
                  textAlign: TextAlign.center,
                  style: HomeUi.control(isDark, active: true).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HomeUi.title(isDark),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HomeUi.sectionTitle(isDark).copyWith(
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        if (!widget.ticker.isStock) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: HomeUi.elevatedBg(isDark),
                              borderRadius:
                                  BorderRadius.circular(HomeUi.radiusPill),
                              border: Border.all(
                                color: HomeUi.borderLight(isDark),
                              ),
                            ),
                            child: Text(
                              'ETF',
                              style: HomeUi.overline(isDark).copyWith(
                                fontSize: 9,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              HomeUi.vectorIcon(
                icon: Icons.chevron_right_rounded,
                size: HomeUi.iconMd,
                color: HomeUi.muted(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
