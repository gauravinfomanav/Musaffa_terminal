import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/shariah_compliance/shariah_compliance_details_screen.dart';
import 'package:musaffa_terminal/shariah_compliance/services/shariah_compliance_search_service.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class ShariahComplianceScreen extends StatefulWidget {
  const ShariahComplianceScreen({super.key});

  @override
  State<ShariahComplianceScreen> createState() => _ShariahComplianceScreenState();
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

    final String? name = ticker.companyName ??
        ticker.name ??
        ticker.stockName;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShariahComplianceDetailsScreen(
          tickerSymbol: symbol,
          companyName: name,
          ticker: ticker,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor =
        isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final Color primaryTextColor =
        isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF0A0A0A);
    final Color secondaryTextColor =
        isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final Color borderColor =
        isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
    final Color fillColor =
        isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final Color accentColor =
        isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6);
    final Color surfaceColor =
        isDarkMode ? const Color(0xFF111827) : Colors.white;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _closeScreen,
      },
      child: Focus(
        autofocus: true,
        focusNode: _screenFocusNode,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, right: 20),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _closeScreen,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Esc',
                                style: TextStyle(
                                  fontFamily: Constants.FONT_DEFAULT_NEW,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: secondaryTextColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.close,
                                color: secondaryTextColor,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'resources/Small Logo.svg',
                            height: 34,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Shariah Stock & ETF Screener',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: primaryTextColor,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Find Shariah compliance details for any stock or ETF.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: secondaryTextColor,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          AnimatedBuilder(
                            animation: _searchFocusNode,
                            builder: (context, child) {
                              final bool hasFocus = _searchFocusNode.hasFocus;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: hasFocus
                                      ? [
                                          BoxShadow(
                                            color: accentColor.withOpacity(
                                              isDarkMode ? 0.18 : 0.14,
                                            ),
                                            blurRadius: 22,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 10),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: child,
                              );
                            },
                            child: Material(
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              color: Colors.transparent,
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                cursorColor: accentColor,
                                textInputAction: TextInputAction.search,
                                  onChanged: _onSearchChanged,
                                style: TextStyle(
                                  fontFamily: Constants.FONT_DEFAULT_NEW,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: primaryTextColor,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    size: 24,
                                    color: secondaryTextColor,
                                  ),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            onPressed: _clearSearch,
                                            icon: Icon(
                                              Icons.close,
                                              size: 18,
                                              color: secondaryTextColor,
                                            ),
                                          )
                                        : null,
                                  hintText:
                                      'Search stocks and ETFs for Shariah compliance details',
                                  hintStyle: TextStyle(
                                    fontFamily: Constants.FONT_DEFAULT_NEW,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: secondaryTextColor,
                                  ),
                                  filled: true,
                                  fillColor: fillColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 22,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: borderColor,
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: borderColor,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: accentColor,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_isSearching || _searchResults.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isDarkMode ? 0.24 : 0.08,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: _isSearching
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: accentColor,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Searching stocks and ETFs...',
                                            style: TextStyle(
                                              fontFamily:
                                                  Constants.FONT_DEFAULT_NEW,
                                              fontSize: 13,
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: _searchResults
                                          .asMap()
                                          .entries
                                          .map(
                                            (entry) => _SearchSuggestionTile(
                                              ticker: entry.value,
                                              isFirst: entry.key == 0,
                                              isLast:
                                                  entry.key ==
                                                  _searchResults.length - 1,
                                              primaryTextColor:
                                                  primaryTextColor,
                                              secondaryTextColor:
                                                  secondaryTextColor,
                                              accentColor: accentColor,
                                              borderColor: borderColor,
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
                            spacing: 18,
                            runSpacing: 10,
                            children: [
                              _FeatureItem(
                                icon: Icons.verified_outlined,
                                label: 'Compliance status',
                                color: accentColor,
                                textColor: secondaryTextColor,
                              ),
                              _FeatureItem(
                                icon: Icons.business_center_outlined,
                                label: 'Business screening',
                                color: accentColor,
                                textColor: secondaryTextColor,
                              ),
                              _FeatureItem(
                                icon: Icons.bar_chart_rounded,
                                label: 'Financial ratios',
                                color: accentColor,
                                textColor: secondaryTextColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Click × to return to terminal',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: secondaryTextColor,
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
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _SearchSuggestionTile extends StatelessWidget {
  const _SearchSuggestionTile({
    required this.ticker,
    required this.isFirst,
    required this.isLast,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.borderColor,
    required this.onTap,
  });

  final TickerModel ticker;
  final bool isFirst;
  final bool isLast;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String symbol = ticker.symbol ?? ticker.ticker ?? '-';
    final String name =
        ticker.companyName ?? ticker.name ?? ticker.stockName ?? 'Unknown';
    final String meta = [
      if ((ticker.exchange ?? '').isNotEmpty) ticker.exchange!,
      if ((ticker.countryName ?? '').isNotEmpty) ticker.countryName!,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(12) : Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: borderColor.withOpacity(0.8)),
                ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
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
                children: [
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
                  if (meta.isNotEmpty) ...[
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
