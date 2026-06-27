import 'package:flutter/material.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/shariah_compliance/services/shariah_compliance_search_service.dart';
import 'package:musaffa_terminal/shariah_compliance/widgets/compliance_shared_widgets.dart';
import 'package:musaffa_terminal/utils/constants.dart';

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
          elevation: 4,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDarkMode
                    ? const Color(0xFF404040)
                    : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
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
    final double screenHeight = MediaQuery.of(context).size.height;
    final double fieldHeight = widget.compact
        ? (screenHeight * 0.055).clamp(40.0, 48.0)
        : (screenHeight * 0.055).clamp(44.0, 56.0);

    return SizedBox(
      key: _searchFieldKey,
      width: widget.maxWidth,
      height: fieldHeight,
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        cursorColor: isDarkMode
            ? const Color(0xFF81AACE)
            : const Color(0xFF3B82F6),
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
        style: DashboardTextStyles.stockName.copyWith(
          color: isDarkMode
              ? const Color(0xFFE0E0E0)
              : DashboardTextStyles.stockName.color,
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: widget.compact ? 14 : 16,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            size: widget.compact ? 18 : 20,
            color: isDarkMode
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF6B7280),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: isDarkMode
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                )
              : null,
          hintText: 'Search another compliance report',
          hintStyle: DashboardTextStyles.tickerSymbol.copyWith(
            color: isDarkMode
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF6B7280),
            fontSize: widget.compact ? 13 : 14,
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 12 : 16,
            vertical: widget.compact ? 10 : 12,
          ),
          filled: true,
          fillColor: isDarkMode
              ? const Color(0xFF1A1A1A)
              : const Color(0xFFFAFAFA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: isDarkMode
                  ? const Color(0xFF404040)
                  : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: isDarkMode
                  ? const Color(0xFF404040)
                  : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: isDarkMode
                  ? const Color(0xFF404040)
                  : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
        ),
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
  });

  final TickerModel ticker;
  final bool isLast;
  final bool isDarkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String symbol = ticker.symbol ?? ticker.ticker ?? '-';
    final String name =
        ticker.companyName ?? ticker.name ?? ticker.stockName ?? 'Unknown';
    final String meta = <String>[
      if ((ticker.exchange ?? '').isNotEmpty) ticker.exchange!,
      if ((ticker.countryName ?? '').isNotEmpty) ticker.countryName!,
    ].join(' · ');
    final Color borderColor =
        isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
    final Color primaryTextColor =
        isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF0A0A0A);
    final Color secondaryTextColor =
        isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF6B7280);
    final Color accentColor =
        isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: borderColor.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                symbol,
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: primaryTextColor,
                    ),
                  ),
                  if (!ticker.isStock) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      'ETF',
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ],
                  if (meta.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
