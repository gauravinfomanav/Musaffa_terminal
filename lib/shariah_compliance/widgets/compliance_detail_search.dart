import 'package:flutter/material.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/shariah_compliance/services/shariah_compliance_search_service.dart';
import 'package:musaffa_terminal/shariah_compliance/widgets/compliance_shared_widgets.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

class ComplianceDetailSearch extends StatefulWidget {
  const ComplianceDetailSearch({
    super.key,
    required this.onSelectTicker,
    this.maxWidth = 520,
    this.compact = false,
  });

  final ValueChanged<TickerModel> onSelectTicker;
  final double maxWidth;
  final bool compact;

  @override
  State<ComplianceDetailSearch> createState() => _ComplianceDetailSearchState();
}

class _ComplianceDetailSearchState extends State<ComplianceDetailSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _searchFieldKey = GlobalKey();
  final ShariahComplianceSearchService _searchService =
      ShariahComplianceSearchService();

  List<TickerModel> _searchResults = <TickerModel>[];
  bool _isSearching = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleFocusChange);
    _searchController.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchFocusNode.removeListener(_handleFocusChange);
    _searchController.removeListener(_handleControllerChange);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchService.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) setState(() {});
  }

  void _handleFocusChange() {
    if (_searchFocusNode.hasFocus) {
      if (_isSearching || _searchResults.isNotEmpty) {
        _showOverlay();
      }
      return;
    }

    if (!_isSearching &&
        _searchResults.isEmpty &&
        _searchController.text.trim().isEmpty) {
      _removeOverlay();
    }
  }

  void _onSearchChanged(String value) {
    final String query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = <TickerModel>[];
      });
      _removeOverlay();
      return;
    }

    setState(() {
      _isSearching = true;
    });
    _showOverlay();

    _searchService.searchTickersDebounced(
      query,
      onResults: (List<TickerModel> results) {
        if (!mounted || _searchController.text.trim() != query) {
          return;
        }

        setState(() {
          _isSearching = false;
          _searchResults = results;
        });

        if (results.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      },
    );
  }

  void _dismissSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = <TickerModel>[];
    });
    _removeOverlay();
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    _dismissSearch();
    _searchFocusNode.requestFocus();
  }

  void _selectTicker(TickerModel ticker) {
    _removeOverlay();
    _searchFocusNode.unfocus();
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = <TickerModel>[];
    });
    widget.onSelectTicker(ticker);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();

    if (!_isSearching && _searchResults.isEmpty) {
      return;
    }

    final RenderBox? renderBox =
        _searchFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }

    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) => Positioned(
        top: position.dy + size.height + 4,
        left: position.dx,
        width: size.width,
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: HomeUi.cardDecoration(isDarkMode),
            clipBehavior: Clip.antiAlias,
            child: _isSearching
                ? const ComplianceSearchResultsShimmer(itemCount: 4)
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _searchResults.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _SearchSuggestionTile(
                        ticker: _searchResults[index],
                        isLast: index == _searchResults.length - 1,
                        isDarkMode: isDarkMode,
                        rowIndex: index,
                        onTap: () => _selectTicker(_searchResults[index]),
                      );
                    },
                  ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool hasQuery = _searchController.text.isNotEmpty;
    final double fieldHeight =
        widget.compact ? HomeUi.filterFieldHeight : 52.0;

    return SizedBox(
      key: _searchFieldKey,
      width: widget.maxWidth,
      height: fieldHeight,
      child: AnimatedBuilder(
        animation: _searchFocusNode,
        builder: (BuildContext context, Widget? _) {
          final bool focused = _searchFocusNode.hasFocus;
          return HomeUi.filterFieldShell(
            dark: isDarkMode,
            accent: focused,
            hover: focused,
            height: fieldHeight,
            radius: HomeUi.radiusCard,
            padding: const EdgeInsets.only(left: 6, right: 6),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              cursorColor: const Color(0xFFC42329),
              cursorWidth: 1.2,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              style: HomeUi.control(isDarkMode, active: true).copyWith(
                fontSize: 13.5,
                height: 1.2,
                color: HomeUi.title(isDarkMode),
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search another compliance report',
                hintStyle: HomeUi.subtitle(isDarkMode).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: focused
                      ? HomeUi.brandIcon(
                          icon: Icons.search_rounded,
                          size: HomeUi.iconMd,
                          gradient: HomeUi.iconFillGradient,
                        )
                      : HomeUi.vectorIcon(
                          icon: Icons.search_rounded,
                          size: HomeUi.iconMd,
                          color: HomeUi.muted(isDarkMode),
                        ),
                ),
                prefixIconConstraints: const BoxConstraints(
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
                          color: HomeUi.muted(isDarkMode),
                        ),
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchSuggestionTile extends StatelessWidget {
  const _SearchSuggestionTile({
    required this.ticker,
    required this.isLast,
    required this.isDarkMode,
    required this.onTap,
    this.rowIndex = 0,
  });

  final TickerModel ticker;
  final bool isLast;
  final bool isDarkMode;
  final VoidCallback onTap;
  final int rowIndex;

  @override
  Widget build(BuildContext context) {
    final String symbol = ticker.symbol ?? ticker.ticker ?? '-';
    final String name =
        ticker.companyName ?? ticker.name ?? ticker.stockName ?? 'Unknown';
    final String meta = <String>[
      if ((ticker.exchange ?? '').isNotEmpty) ticker.exchange!,
      if ((ticker.countryName ?? '').isNotEmpty) ticker.countryName!,
    ].join(' · ');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: rowIndex.isEven
                ? HomeUi.tableRowEven(isDarkMode)
                : HomeUi.tableRowOdd(isDarkMode),
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(color: HomeUi.borderLight(isDarkMode)),
                  ),
          ),
          child: Row(
            children: <Widget>[
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
                  style: HomeUi.control(isDarkMode, active: true).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HomeUi.title(isDarkMode),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HomeUi.sectionTitle(isDarkMode)
                                .copyWith(fontSize: 13.5),
                          ),
                        ),
                        if (!ticker.isStock) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: HomeUi.elevatedBg(isDarkMode),
                              borderRadius:
                                  BorderRadius.circular(HomeUi.radiusPill),
                              border: Border.all(
                                color: HomeUi.borderLight(isDarkMode),
                              ),
                            ),
                            child: Text(
                              'ETF',
                              style: HomeUi.overline(isDarkMode).copyWith(
                                fontSize: 9,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (meta.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            HomeUi.subtitle(isDarkMode).copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
