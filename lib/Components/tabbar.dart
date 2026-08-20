import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/auto_size_text.dart';
import 'package:musaffa_terminal/controllers/finhub_controller.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:musaffa_terminal/Controllers/search_service.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/Screens/ticker_detail_screen.dart';
import 'package:musaffa_terminal/Screens/etf_details_screen.dart';
import 'package:musaffa_terminal/Screens/screener_screen.dart';
import 'package:musaffa_terminal/Screens/trading_ideas_screen.dart';
import 'package:musaffa_terminal/Screens/portfolio_idea_screen.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Controllers/floating_action_buttons_controller.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/services/global_search_service.dart';
import 'package:musaffa_terminal/web_service.dart';
import 'package:musaffa_terminal/Components/app_sidebar.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/services/feature_access_service.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';

class HomeTabBar extends StatelessWidget {
  final ValueChanged<String>? onSearch;
  final VoidCallback? onSearchSubmit;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onWatchlistToggle;
  final bool showBackButton;
  final bool isWatchlistOpen;

  const HomeTabBar({
    super.key,
    this.onSearch,
    this.onSearchSubmit,
    this.onThemeToggle,
    this.onWatchlistToggle,
    this.showBackButton = false,
    this.isWatchlistOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FinhubController());
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fabController = Get.find<FloatingActionButtonsController>();

    return DragTarget<FABType>(
      onWillAccept: (data) => data != null,
      onAccept: (type) {
        // When FAB is dropped on tabbar, remove it (icon will reappear)
        try {
          final fab = fabController.fabs.firstWhere((fab) => fab.type == type);
          fabController.removeFAB(fab.id);
        } catch (e) {
          // FAB not found, ignore
        }
      },
      builder: (context, candidateData, rejectedData) {
        final barBg = candidateData.isNotEmpty
            ? (isDarkMode
                ? const Color(0xFF2D4A6B).withOpacity(0.8)
                : const Color(0xFFDBEAFE).withOpacity(0.8))
            : (isDarkMode ? const Color(0xFF121417) : const Color(0xFFFFFFFF));
        final borderColor =
            isDarkMode ? const Color(0xFF2A2F33) : const Color(0xFFE8EAED);
        final screenWidth = MediaQuery.sizeOf(context).width;
        // Responsive centered search: ~45% of screen, clamped.
        final searchWidth = (screenWidth * 0.45).clamp(300.0, 680.0);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                barBg,
                isDarkMode ? const Color(0xFF101317) : const Color(0xFFFBFBFC),
              ],
            ),
            border: Border(
              bottom: BorderSide(color: borderColor, width: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.28 : 0.04),
                blurRadius: isDarkMode ? 16 : 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          foregroundDecoration: candidateData.isNotEmpty
              ? BoxDecoration(
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF4A9EFF)
                        : const Color(0xFF2563EB),
                    width: 2,
                  ),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SidebarMenuButton(isDarkMode: isDarkMode),
                          const SizedBox(width: 12),
                          if (showBackButton) ...[
                            _HeaderBackButton(isDarkMode: isDarkMode),
                            const SizedBox(width: 10),
                          ],
                          _HeaderLogoLockup(isDarkMode: isDarkMode),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: searchWidth),
                      child: Obx(() {
                        final canSearch = FeatureNavigation.isEnabled(
                          FeatureKeys.stockSearch,
                        );
                        if (!canSearch) {
                          return const SizedBox.shrink();
                        }
                        return _SearchField(
                          onChanged: onSearch,
                          onSubmitted: (_) => onSearchSubmit?.call(),
                          isDarkMode: isDarkMode,
                        );
                      }),
                    ),
                    ),
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(child: _NavToolsCluster(isDarkMode: isDarkMode)),
                          Obx(() {
                            final canWatchlists = FeatureNavigation.isEnabled(
                              FeatureKeys.watchlists,
                            );
                            if (!canWatchlists) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _WatchlistToggleButton(
                                isOpen: isWatchlistOpen,
                                onToggle: onWatchlistToggle,
                                isDarkMode: isDarkMode,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                height: HomeUi.indicesStripHeight,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF0E1012)
                      : const Color(0xFFF7F8FA),
                  border: Border(
                    top: BorderSide(
                      color: HomeUi.borderLight(isDarkMode),
                      width: 1,
                    ),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: _MarketIndicesStrip(
                  controller: controller,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchField extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool isDarkMode;

  const _SearchField({
    this.onChanged,
    this.onSubmitted,
    required this.isDarkMode,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _HeaderBackButton extends StatefulWidget {
  const _HeaderBackButton({required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<_HeaderBackButton> createState() => _HeaderBackButtonState();
}

class _HeaderBackButtonState extends State<_HeaderBackButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final color = _hovering
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

class _HeaderLogoLockup extends StatelessWidget {
  const _HeaderLogoLockup({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return const MusaffaLogo(height: 25);
  }
}

class _SearchFieldState extends State<_SearchField>
    with SingleTickerProviderStateMixin {
  static const List<String> _searchKeywords = ['Symbols', 'ETFs', 'Stocks'];
  final TextEditingController _searchController = TextEditingController();
  List<TickerModel> _searchResults = [];
  OverlayEntry? _overlayEntry;
  final GlobalKey _searchFieldKey = GlobalKey();
  late FocusNode _focusNode;
  late final AnimationController _keywordAnimationController;
  bool _hovered = false;
  Timer? _keywordTimer;
  int _keywordIndex = 0;
  int _nextKeywordIndex = 1;
  bool _isKeywordAnimating = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _keywordAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _keywordIndex = _nextKeywordIndex;
            _nextKeywordIndex = (_keywordIndex + 1) % _searchKeywords.length;
            _isKeywordAnimating = false;
          });
          _keywordAnimationController.reset();
        }
      });
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _startKeywordCarousel();
    if (Get.isRegistered<GlobalSearchService>()) {
      Get.find<GlobalSearchService>().registerSearchFocusNode(_focusNode);
    }
  }

  @override
  void dispose() {
    // Unregister the focus node
    if (Get.isRegistered<GlobalSearchService>()) {
      Get.find<GlobalSearchService>().unregisterSearchFocusNode();
    }
    _searchController.dispose();
    _focusNode.dispose();
    _stopKeywordCarousel();
    _keywordAnimationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _startKeywordCarousel() {
    _keywordTimer?.cancel();
    _keywordTimer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (!mounted ||
          _searchController.text.isNotEmpty ||
          _isKeywordAnimating) {
        return;
      }
      _animateKeywordTransition();
    });
  }

  void _stopKeywordCarousel() {
    _keywordTimer?.cancel();
    _keywordTimer = null;
  }

  void _animateKeywordTransition() {
    if (_isKeywordAnimating) return;
    setState(() {
      _nextKeywordIndex = (_keywordIndex + 1) % _searchKeywords.length;
      _isKeywordAnimating = true;
    });
    _keywordAnimationController.forward(from: 0);
  }

  void _showOverlay() {
    _removeOverlay();

    // Only show overlay if there are search results AND the text field is not empty
    if (_searchResults.isEmpty || _searchController.text.isEmpty) {
      return;
    }

    final RenderBox? renderBox =
        _searchFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final dark = widget.isDarkMode;
        return Positioned(
          top: position.dy + size.height + 8,
          left: position.dx,
          width: size.width,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 360),
              decoration: BoxDecoration(
                color: HomeUi.cardBg(dark),
                borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                border: Border.all(color: HomeUi.borderLight(dark), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(dark ? 0.28 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(dark ? 0.32 : 0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(left: 56, right: 12),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: HomeUi.borderLight(dark).withOpacity(0.85),
                  ),
                ),
                itemBuilder: (context, index) {
                  return _SearchResultRow(
                    ticker: _searchResults[index],
                    isDarkMode: dark,
                    onTap: () => _onTickerSelected(_searchResults[index]),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      _removeOverlay();
      return;
    }

    try {
      final results = await SearchService.searchStocks(query.trim());
      setState(() {
        _searchResults = results;
      });

      if (results.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
      });
      _removeOverlay();
    }
  }

  void _onTickerSelected(TickerModel ticker) {
    // Remove overlay and reset state first
    _removeOverlay();
    _searchController.clear();
    _focusNode.unfocus();

    // Navigate to appropriate screen based on isStock flag
    if (ticker.isStock) {
      FeatureNavigation.pushIfAllowed(
        context,
        FeatureKeys.tickerDetails,
        TickerDetailScreen(ticker: ticker),
      );
    } else {
      FeatureNavigation.pushIfAllowed(
        context,
        FeatureKeys.etfDetails,
        EtfDetailsScreen(ticker: ticker),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const fieldHeight = HomeUi.controlHeight;
    final dark = widget.isDarkMode;
    final focused = _focusNode.hasFocus;
    final active = focused || _hovered;
    final hasQuery = _searchController.text.isNotEmpty;
    final radius = BorderRadius.circular(HomeUi.radiusMd);
    final fill = HomeUi.cardBg(dark);
    final placeholderStyle = HomeUi.subtitle(dark).copyWith(
      fontSize: 13.5,
      height: 1.2,
      fontWeight: FontWeight.w400,
    );
    final borderColor = focused
        ? const Color(0xFFC42329).withOpacity(dark ? 0.55 : 0.42)
        : HomeUi.borderStrong(dark);

    OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.text,
      child: AnimatedContainer(
        key: _searchFieldKey,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: fieldHeight,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: focused
              ? [
                  BoxShadow(
                    color:
                        const Color(0xFFC42329).withOpacity(dark ? 0.18 : 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ]
              : HomeUi.cardShadow(dark, hover: true),
        ),
        child: Stack(
          children: [
            TextField(
              controller: _searchController,
              focusNode: _focusNode,
              cursorColor: const Color(0xFFC42329),
              cursorWidth: 1.2,
              cursorHeight: 14,
              onChanged: (value) {
                widget.onChanged?.call(value);
                if (value.isEmpty) {
                  _startKeywordCarousel();
                } else {
                  _stopKeywordCarousel();
                }
                if (value.length >= 2) {
                  _performSearch(value);
                } else {
                  setState(() {
                    _searchResults = [];
                  });
                  _removeOverlay();
                }
              },
              onSubmitted: (value) => widget.onSubmitted?.call(value),
              textInputAction: TextInputAction.search,
              style: HomeUi.control(dark, active: true).copyWith(
                fontSize: 14,
                height: 1.2,
                color: HomeUi.title(dark),
              ),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: active
                      ? HomeUi.brandIcon(
                          icon: CupertinoIcons.search,
                          size: HomeUi.iconMd,
                          gradient: HomeUi.iconFillGradient,
                        )
                      : HomeUi.vectorIcon(
                          icon: CupertinoIcons.search,
                          size: HomeUi.iconMd,
                          color: HomeUi.muted(dark),
                        ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: fieldHeight,
                ),
                suffixIcon: hasQuery
                    ? IconButton(
                        tooltip: 'Clear',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: fieldHeight,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                          _startKeywordCarousel();
                          _removeOverlay();
                          widget.onChanged?.call('');
                        },
                        icon: HomeUi.vectorIcon(
                          icon: CupertinoIcons.xmark_circle_fill,
                          size: HomeUi.iconSm,
                          color: HomeUi.muted(dark),
                        ),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: fieldHeight,
                ),
                hintText: '',
                hintStyle: placeholderStyle,
                contentPadding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                filled: true,
                fillColor: fill,
                border: outline(borderColor, active ? 1 : 0.5),
                enabledBorder: outline(borderColor, active ? 1 : 0.5),
                focusedBorder: outline(borderColor, 1),
                errorBorder: outline(const Color(0xFFDC2626), 1),
                focusedErrorBorder: outline(const Color(0xFFDC2626), 1),
              ),
            ),
            if (!hasQuery)
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 8, 12, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Search by ',
                            style: placeholderStyle,
                          ),
                          ClipRect(
                            child: SizedBox(
                              height: 20,
                              width: 54,
                              child: AnimatedBuilder(
                                animation: _keywordAnimationController,
                                builder: (context, child) {
                                  final t = Curves.easeInOutCubic.transform(
                                    _keywordAnimationController.value,
                                  );
                                  final currentDy =
                                      _isKeywordAnimating ? -20.0 * t : 0.0;
                                  final nextDy = _isKeywordAnimating
                                      ? 20.0 * (1 - t)
                                      : 20.0;
                                  final currentOpacity =
                                      _isKeywordAnimating ? (1 - t) : 1.0;
                                  final nextOpacity =
                                      _isKeywordAnimating ? t : 0.0;

                                  return Stack(
                                    clipBehavior: Clip.hardEdge,
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      Transform.translate(
                                        offset: Offset(0, currentDy),
                                        child: Opacity(
                                          opacity: currentOpacity,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              _searchKeywords[_keywordIndex],
                                              style: placeholderStyle,
                                              maxLines: 1,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Transform.translate(
                                        offset: Offset(0, nextDy),
                                        child: Opacity(
                                          opacity: nextOpacity,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              _searchKeywords[_nextKeywordIndex],
                                              style: placeholderStyle,
                                              maxLines: 1,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultRow extends StatefulWidget {
  const _SearchResultRow({
    required this.ticker,
    required this.isDarkMode,
    required this.onTap,
  });

  final TickerModel ticker;
  final bool isDarkMode;
  final VoidCallback onTap;

  @override
  State<_SearchResultRow> createState() => _SearchResultRowState();
}

class _SearchResultRowState extends State<_SearchResultRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final ticker = widget.ticker;
    final symbol = ticker.symbol ?? ticker.ticker ?? '';
    final name = ticker.companyName ?? ticker.name ?? '';
    final up = ticker.percentChange == null || ticker.percentChange! >= 0;
    final priceColor = ticker.percentChange == null
        ? HomeUi.body(dark)
        : (up ? HomeUi.positive(dark) : HomeUi.negative(dark));

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          color: _hover ? HomeUi.tableRowHover(dark) : Colors.transparent,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HomeUi.elevatedBg(dark),
                  border: Border.all(color: HomeUi.borderLight(dark), width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: showLogo(
                  symbol,
                  ticker.logo ?? '',
                  sideWidth: 28,
                  name: symbol,
                  circular: true,
                  borderColor: Colors.transparent,
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
                            symbol,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HomeUi.control(dark, active: true).copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: HomeUi.title(dark),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: HomeUi.elevatedBg(dark),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ticker.isStock ? 'Stock' : 'ETF',
                            style: HomeUi.overline(dark).copyWith(
                              fontSize: 9,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeUi.subtitle(dark).copyWith(
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (ticker.currentPrice != null) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${ticker.currentPrice!.toStringAsFixed(2)}',
                      style: HomeUi.tableNumeric(dark).copyWith(
                        color: priceColor,
                        fontSize: 13,
                      ),
                    ),
                    if (ticker.percentChange != null)
                      Text(
                        '${up ? '+' : ''}${ticker.percentChange!.toStringAsFixed(2)}%',
                        style: HomeUi.subtitle(dark).copyWith(
                          fontSize: 11,
                          color: priceColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketIndicesStrip extends StatefulWidget {
  final FinhubController controller;
  final bool isDarkMode;

  const _MarketIndicesStrip({
    required this.controller,
    required this.isDarkMode,
  });

  @override
  State<_MarketIndicesStrip> createState() => _MarketIndicesStripState();
}

class _MarketIndicesStripState extends State<_MarketIndicesStrip> {
  late final ScrollController _scrollController;
  final GlobalKey _loopKey = GlobalKey();
  Timer? _scrollTimer;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _advance(0.55);
    });
  }

  double get _loopWidth {
    try {
      return _loopKey.currentContext?.size?.width ?? 0;
    } catch (_) {
      // Size can be read while the render object is still dirty for layout.
      return 0;
    }
  }

  void _advance(double delta) {
    if (!mounted || _isHovered || !_scrollController.hasClients) return;
    final loop = _loopWidth;
    if (loop <= 0) return;
    var next = _scrollController.offset + delta;
    while (next >= loop) {
      next -= loop;
    }
    while (next < 0) {
      next += loop;
    }
    _scrollController.jumpTo(next);
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color:
          widget.isDarkMode ? const Color(0xFF2A2E34) : const Color(0xFFE6E8EC),
    );
  }

  Widget _buildIndexItems(List<MarketIndex> indices) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < indices.length; i++) ...[
          if (i > 0) _divider(),
          _IndexItem(
            index: indices[i],
            isDarkMode: widget.isDarkMode,
          ),
        ],
      ],
    );
  }

  Widget _loopCopy(List<MarketIndex> indices) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIndexItems(indices),
        _divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.controller.isLoading.value &&
          widget.controller.indices.isEmpty) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(
              8,
              (i) => Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ShimmerWidgets.box(
                    width: 120,
                    height: 14,
                    borderRadius: BorderRadius.circular(6),
                    baseColor: widget.isDarkMode
                        ? const Color(0xFF404040)
                        : const Color(0xFFE5E7EB),
                    highlightColor: widget.isDarkMode
                        ? const Color(0xFF2D2D2D)
                        : const Color(0xFFF3F4F6),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      if (widget.controller.indices.isEmpty) {
        return const SizedBox.shrink();
      }

      final indices = widget.controller.indices.take(20).toList();

      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.basic,
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent && _scrollController.hasClients) {
              final loop = _loopWidth;
              if (loop <= 0) return;
              var next = _scrollController.offset + event.scrollDelta.dy;
              while (next >= loop) {
                next -= loop;
              }
              while (next < 0) {
                next += loop;
              }
              _scrollController.jumpTo(next);
            }
          },
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0.0, 0.035, 0.965, 1.0],
            ).createShader(rect),
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeyedSubtree(
                    key: _loopKey,
                    child: _loopCopy(indices),
                  ),
                  _loopCopy(indices),
                  _loopCopy(indices),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _IndexItem extends StatelessWidget {
  final MarketIndex index;
  final bool isDarkMode;

  const _IndexItem({
    required this.index,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final up = index.isPositive;
    final color =
        up ? HomeUi.positive(isDarkMode) : HomeUi.negative(isDarkMode);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          index.displayName,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontFamilyFallback: Constants.FONT_FALLBACK,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            height: 1,
            color: HomeUi.title(isDarkMode),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.fromLTRB(5, 3, 6, 3),
          decoration: BoxDecoration(
            color: color.withOpacity(isDarkMode ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                up
                    ? CupertinoIcons.arrowtriangle_up_fill
                    : CupertinoIcons.arrowtriangle_down_fill,
                size: 7,
                color: color,
              ),
              const SizedBox(width: 3),
              Text(
                index.formattedChangePercent,
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontFamilyFallback: Constants.FONT_FALLBACK,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  letterSpacing: -0.15,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavToolsCluster extends StatelessWidget {
  final bool isDarkMode;

  const _NavToolsCluster({required this.isDarkMode});

  void _goScreener(BuildContext context) {
    bool isOnScreener = false;
    context.visitAncestorElements((element) {
      if (element.widget is ScreenerScreen) {
        isOnScreener = true;
        return false;
      }
      return true;
    });
    if (isOnScreener) return;

    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.screener);
    }
    FeatureNavigation.pushIfAllowed(
      context,
      FeatureKeys.screener,
      const ScreenerScreen(),
    );
  }

  void _goIdeas(BuildContext context) {
    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.ideas);
    }
    FeatureNavigation.pushIfAllowed(
      context,
      FeatureKeys.tradingIdeas,
      const TradingIdeasScreen(),
    );
  }

  void _goPortfolio(BuildContext context) {
    bool isOnPortfolio = false;
    context.visitAncestorElements((element) {
      if (element.widget is PortfolioIdeaScreen) {
        isOnPortfolio = true;
        return false;
      }
      return true;
    });
    if (isOnPortfolio) return;

    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.portfolio);
    }
    FeatureNavigation.pushIfAllowed(
      context,
      FeatureKeys.portfolios,
      const PortfolioIdeaScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fab = Get.find<FloatingActionButtonsController>();
      // Ensure Obx tracks feature map changes.
      if (Get.isRegistered<FeatureAccessService>()) {
        Get.find<FeatureAccessService>().features.length;
      }
      // Track active nav item so chips rebuild on page change.
      if (Get.isRegistered<GlobalSidebarService>()) {
        Get.find<GlobalSidebarService>().activeItem.value;
      }
      final canScreener = FeatureNavigation.isEnabled(FeatureKeys.screener);
      final canIdeas = FeatureNavigation.isEnabled(FeatureKeys.tradingIdeas);
      final canPortfolios = FeatureNavigation.isEnabled(FeatureKeys.portfolios);

      final tools = <_ToolSpec>[
        if (canScreener && !fab.shouldHideInTabbar(FABType.screener))
          _ToolSpec(
            label: 'Screener',
            icon: Icons.tune_rounded,
            fabType: FABType.screener,
            tooltip: 'Open Screener  ·  Drag to pin',
            onTap: () => _goScreener(context),
            navItem: SidebarNavItem.screener,
          ),
        if (canIdeas && !fab.shouldHideInTabbar(FABType.ideas))
          _ToolSpec(
            label: 'Ideas',
            icon: CupertinoIcons.lightbulb_fill,
            fabType: FABType.ideas,
            tooltip: 'Open Ideas  ·  Drag to pin',
            onTap: () => _goIdeas(context),
            navItem: SidebarNavItem.ideas,
          ),
        if (canPortfolios && !fab.shouldHideInTabbar(FABType.portfolio))
          _ToolSpec(
            label: 'Portfolios',
            icon: CupertinoIcons.chart_pie_fill,
            fabType: FABType.portfolio,
            tooltip: 'Open Portfolios  ·  Drag to pin',
            onTap: () => _goPortfolio(context),
            navItem: SidebarNavItem.portfolio,
          ),
      ];

      if (tools.isEmpty) return const SizedBox.shrink();

      return Container(
        height: HomeUi.controlHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HomeUi.radiusMd),
          border: Border.all(color: HomeUi.borderLight(isDarkMode), width: 0.9),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDarkMode ? const Color(0xFF1A1D22) : Colors.white,
              isDarkMode ? const Color(0xFF13161A) : const Color(0xFFF6F7F9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.16 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < tools.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 16,
                  color: HomeUi.borderLight(isDarkMode),
                ),
              _ToolSegment(
                spec: tools[i],
                isDarkMode: isDarkMode,
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _ToolSpec {
  final String label;
  final IconData icon;
  final FABType fabType;
  final String tooltip;
  final VoidCallback onTap;
  final SidebarNavItem navItem;

  const _ToolSpec({
    required this.label,
    required this.icon,
    required this.fabType,
    required this.tooltip,
    required this.onTap,
    required this.navItem,
  });
}

class _HeaderTooltip extends StatelessWidget {
  const _HeaderTooltip({
    required this.message,
    required this.isDarkMode,
    required this.child,
  });

  final String message;
  final bool isDarkMode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      waitDuration: const Duration(milliseconds: 280),
      showDuration: const Duration(seconds: 4),
      preferBelow: true,
      verticalOffset: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1D22) : const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF3A4048) : const Color(0xFF1F2937),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.35 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      textStyle: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontFamilyFallback: Constants.FONT_FALLBACK,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.25,
        color: isDarkMode ? const Color(0xFFF3F4F6) : Colors.white,
      ),
      child: child,
    );
  }
}

class _ToolSegment extends StatefulWidget {
  final _ToolSpec spec;
  final bool isDarkMode;

  const _ToolSegment({
    required this.spec,
    required this.isDarkMode,
  });

  @override
  State<_ToolSegment> createState() => _ToolSegmentState();
}

class _ToolSegmentState extends State<_ToolSegment> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final idle =
        widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final activeColor =
        widget.isDarkMode ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final hoverBg = widget.isDarkMode
        ? Colors.white.withOpacity(0.1)
        : const Color(0xFFF8FAFC);
    final fabController = Get.find<FloatingActionButtonsController>();

    final sidebarActive = Get.isRegistered<GlobalSidebarService>()
        ? Get.find<GlobalSidebarService>().activeItem.value
        : null;
    final bool isActive = sidebarActive == widget.spec.navItem;
    final bool highlighted = _hovering || isActive;
    final color = highlighted ? activeColor : idle;

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      height: HomeUi.controlHeight - 2,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: highlighted ? hoverBg : Colors.transparent,
        borderRadius: BorderRadius.circular(HomeUi.radiusMd - 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HomeUi.brandIcon(
            icon: widget.spec.icon,
            size: HomeUi.iconSm,
            gradient: highlighted ? HomeUi.brandGradient : null,
          ),
          const SizedBox(width: 6),
          Text(
            widget.spec.label,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontFamilyFallback: Constants.FONT_FALLBACK,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: _HeaderTooltip(
        message: widget.spec.tooltip,
        isDarkMode: widget.isDarkMode,
        child: GestureDetector(
          onTap: widget.spec.onTap,
          behavior: HitTestBehavior.opaque,
          child: Draggable<FABType>(
            data: widget.spec.fabType,
            onDragEnd: (_) => fabController.addFAB(widget.spec.fabType),
            feedback: Material(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
              color: widget.isDarkMode ? const Color(0xFF1A1D22) : Colors.white,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HomeUi.brandIcon(
                        icon: widget.spec.icon, size: HomeUi.iconSm, gradient: HomeUi.brandGradient),
                    const SizedBox(width: 6),
                    Text(
                      widget.spec.label,
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontFamilyFallback: Constants.FONT_FALLBACK,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: activeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.35, child: chip),
            child: chip,
          ),
        ),
      ),
    );
  }
}

class _WatchlistToggleButton extends StatefulWidget {
  final bool isOpen;
  final VoidCallback? onToggle;
  final bool isDarkMode;

  const _WatchlistToggleButton({
    required this.isOpen,
    this.onToggle,
    required this.isDarkMode,
  });

  @override
  State<_WatchlistToggleButton> createState() => _WatchlistToggleButtonState();
}

class _WatchlistToggleButtonState extends State<_WatchlistToggleButton> {
  bool _isHovered = false;
  bool _isDragOver = false;

  void _onTap() {
    widget.onToggle?.call();
  }

  Future<void> _handleStockDrop(SimpleRowModel stockData) async {
    try {
      final watchlistController = Get.find<WatchlistController>();

      // Check if we have a default watchlist
      if (watchlistController.defaultWatchlistId == null) {
        // If no default watchlist, use the first available watchlist
        if (watchlistController.watchlists.isNotEmpty) {
          watchlistController.selectedWatchlist.value =
              watchlistController.watchlists.first;
        } else {
          // Show error if no watchlists exist
          _showErrorSnackBar(
              'No watchlists available. Please create a watchlist first.');
          return;
        }
      }

      // Extract current price from multiple sources
      double currentPrice = 0.0;

      // First try to get price from the price field
      if (stockData.price != null) {
        currentPrice = stockData.price!.toDouble();
      } else {
        // Try to extract price from the fields map (formatted string)
        final priceField = stockData.fields['price'];
        if (priceField is String && priceField != '-') {
          // Remove $ and parse the number
          final cleanPrice =
              priceField.replaceAll('\$', '').replaceAll(',', '');
          currentPrice = double.tryParse(cleanPrice) ?? 0.0;
        }
      }

      // If still no price, try to fetch it from the API
      if (currentPrice == 0.0) {
        try {
          // Try to fetch current price from the stock details API
          final stockDetails = await _fetchStockPrice(stockData.symbol);
          if (stockDetails != null) {
            currentPrice = stockDetails;
          }
        } catch (e) {
          print('Failed to fetch price for ${stockData.symbol}: $e');
        }
      }

      // Prepare stock data for API
      final stockToAdd = {
        'ticker': stockData.symbol,
        'current_price':
            currentPrice, // Backend expects underscore, not camelCase
        'addedAt': DateTime.now().toIso8601String(),
      };

      // Add stock to the default/selected watchlist
      final success =
          await watchlistController.addStocksToWatchlist([stockToAdd]);

      if (success) {
        _showSuccessSnackBar('${stockData.symbol} added to watchlist');
      } else {
        _showErrorSnackBar('Failed to add ${stockData.symbol} to watchlist');
      }
    } catch (e) {
      print('Error adding stock to watchlist: $e');
      _showErrorSnackBar('Error adding stock to watchlist');
    }
  }

  void _showSuccessSnackBar(String message) {
    SnackBarUtils.showSuccess(context, message);
  }

  void _showErrorSnackBar(String message) {
    SnackBarUtils.showError(context, message);
  }

  Future<double?> _fetchStockPrice(String symbol) async {
    try {
      // Use the same API endpoint that the stock details controller uses
      final response = await WebService.getTypesense([
        'collections',
        'stocks_data',
        'documents',
        'search'
      ], {
        'q': symbol,
        'query_by': 'id',
        'per_page': 1,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final hits = (data['hits'] as List?) ?? [];

        if (hits.isNotEmpty) {
          final doc =
              (hits.first['document'] as Map?)?.cast<String, dynamic>() ?? {};
          Map<String, dynamic>? sd;
          final v = doc['\$stocks_data'] ?? doc['stocks_data'];
          if (v is Map) sd = v.cast<String, dynamic>();
          if (v is List && v.isNotEmpty)
            sd = (v.first as Map).cast<String, dynamic>();

          if (sd != null && sd['currentPrice'] != null) {
            return double.tryParse(sd['currentPrice'].toString());
          }
        }
      }
    } catch (e) {
      print('Error fetching stock price for $symbol: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<SimpleRowModel>(
      onWillAccept: (data) {
        setState(() {
          _isDragOver = true;
        });
        return true;
      },
      onAccept: (stockData) {
        setState(() {
          _isDragOver = false;
        });
        _handleStockDrop(stockData);
      },
      onLeave: (data) {
        setState(() {
          _isDragOver = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        // Watchlist button is NOT draggable - it stays in tabbar
        return _buildButtonContent();
      },
    );
  }

  Widget _buildButtonContent() {
    final idle =
        widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final active =
        widget.isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF111827);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: _HeaderTooltip(
        message: widget.isOpen ? 'Close watchlist' : 'Open watchlist',
        isDarkMode: widget.isDarkMode,
        child: GestureDetector(
          onTap: _onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: HomeUi.controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _isDragOver
                  ? const Color(0xFFC42329)
                      .withOpacity(widget.isDarkMode ? 0.16 : 0.08)
                  : widget.isOpen
                      ? (widget.isDarkMode
                          ? const Color(0xFF1C2430)
                          : const Color(0xFFEFF6FF))
                      : (_isHovered
                          ? HomeUi.cardBg(widget.isDarkMode)
                          : HomeUi.elevatedBg(widget.isDarkMode)),
              borderRadius: BorderRadius.circular(HomeUi.radiusMd),
              border: Border.all(
                color: _isDragOver || widget.isOpen
                    ? const Color(0xFFC42329).withOpacity(0.55)
                    : (_isHovered
                        ? HomeUi.borderStrong(widget.isDarkMode)
                        : HomeUi.borderLight(widget.isDarkMode)),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HomeUi.brandIcon(
                  icon: _isDragOver
                      ? CupertinoIcons.plus_circle_fill
                      : CupertinoIcons.bookmark_fill,
                  size: HomeUi.iconSm,
                  gradient: (widget.isOpen || _isHovered || _isDragOver)
                      ? HomeUi.brandGradient
                      : null,
                ),
                const SizedBox(width: 6),
                Text(
                  _isDragOver ? 'Add' : 'Watchlist',
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontFamilyFallback: Constants.FONT_FALLBACK,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    color: widget.isOpen || _isDragOver || _isHovered
                        ? active
                        : idle,
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
