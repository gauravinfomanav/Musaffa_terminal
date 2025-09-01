import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/auto_size_text.dart';
import 'package:musaffa_terminal/controllers/finhub_controller.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/Controllers/search_service.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeTabBar extends StatelessWidget {
  final ValueChanged<String>? onSearch;
  final VoidCallback? onSearchSubmit;
  final VoidCallback? onThemeToggle;

  const HomeTabBar({
    super.key, 
    this.onSearch, 
    this.onSearchSubmit,
    this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FinhubController());
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.15 : 0.06),
            blurRadius: isDarkMode ? 8 : 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Theme toggle button
          GestureDetector(
            onTap: onThemeToggle,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                size: 20,
                color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Search field
          Expanded(
            flex: 1,
            child: _SearchField(
              onChanged: onSearch,
              onSubmitted: (_) => onSearchSubmit?.call(),
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(width: 16),
          // Market indices
          Expanded(
            flex: 3,
            child: _MarketIndicesStrip(
              controller: controller,
              isDarkMode: isDarkMode,
            ),
          ),
        ],
      ),
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

class _SearchFieldState extends State<_SearchField> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  List<TickerModel> _searchResults = [];
  bool _showResults = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _searchFieldKey = GlobalKey();
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _showResults) {
      setState(() {
        _showResults = false;
      });
      _removeOverlay();
      _searchController.clear();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App lost focus or user navigated away
      if (_showResults) {
        setState(() {
          _showResults = false;
        });
        _removeOverlay();
        _searchController.clear();
      }
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    
    if (_searchResults.isEmpty) return;
    
    final RenderBox? renderBox = _searchFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy + size.height + 4,
        left: position.dx,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final ticker = _searchResults[index];
                return _buildSearchResultItem(ticker);
              },
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      _removeOverlay();
      return;
    }

    setState(() {
      _showResults = true;
    });

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
      print('Search error: $e');
      setState(() {
        _searchResults = [];
      });
      _removeOverlay();
    }
  }

  void _onTickerSelected(TickerModel ticker) {
    print('DEBUG: Ticker selected: ${ticker.symbol} - ${ticker.name}');
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TickerDetailScreen(ticker: ticker),
        ),
      );
      print('DEBUG: Navigation successful');
    } catch (e) {
      print('DEBUG: Navigation error: $e');
    }
    _removeOverlay();
    setState(() {
      _showResults = false;
    });
  }

  Widget _buildLogoWidget(String logoUrl, bool isStock, TickerModel ticker) {
    if (!isStock) {
      // For ETFs, show first letter or number from name
      String initialLetter = 'E'; // Default fallback
      if (ticker.name != null && ticker.name!.isNotEmpty) {
        String name = ticker.name!.trim();
        // Find first alphanumeric character
        for (int i = 0; i < name.length; i++) {
          if (RegExp(r'[a-zA-Z0-9]').hasMatch(name[i])) {
            initialLetter = name[i].toUpperCase();
            break;
          }
        }
      }
      
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            initialLetter,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
        ),
      );
    }

    if (logoUrl.isEmpty) {
      // For stocks without logo, show first letter or number from name
      String initialLetter = 'S'; // Default fallback
      if (ticker.name != null && ticker.name!.isNotEmpty) {
        String name = ticker.name!.trim();
        // Find first alphanumeric character
        for (int i = 0; i < name.length; i++) {
          if (RegExp(r'[a-zA-Z0-9]').hasMatch(name[i])) {
            initialLetter = name[i].toUpperCase();
            break;
          }
        }
      }
      
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            initialLetter,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
        ),
      );
    }

    if (logoUrl.toLowerCase().endsWith('.svg')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SvgPicture.network(
          logoUrl,
          width: 20,
          height: 20,
          fit: BoxFit.cover,
          placeholderBuilder: (context) => ShimmerWidgets.box(
            width: 20,
            height: 20,
            borderRadius: BorderRadius.circular(4),
            baseColor: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            highlightColor: widget.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
          ),
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.broken_image,
            size: 16,
            color: widget.isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          logoUrl,
          width: 20,
          height: 20,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return ShimmerWidgets.box(
              width: 20,
              height: 20,
              borderRadius: BorderRadius.circular(4),
              baseColor: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              highlightColor: widget.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
            );
          },
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.broken_image,
            size: 16,
            color: widget.isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
        ),
      );
    }
  }

  Widget _buildSearchResultItem(TickerModel ticker) {
    return InkWell(
      onTap: () {
        print('DEBUG: Search result item tapped: ${ticker.symbol}');
        _onTickerSelected(ticker);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: (widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)).withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Logo or Icon
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: _buildLogoWidget(ticker.logo ?? '', ticker.isStock, ticker),
            ),
            
            const SizedBox(width: 12),
            
            // Ticker and Company Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticker.symbol ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF1F2937),
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                  Text(
                    ticker.companyName ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF6B7280),
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Price with change indicator
            if (ticker.currentPrice != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ticker.percentChange != null && ticker.percentChange! >= 0 
                            ? Icons.keyboard_arrow_up 
                            : Icons.keyboard_arrow_down,
                        size: 12,
                        color: ticker.percentChange != null && ticker.percentChange! >= 0 
                            ? Colors.green.shade600 
                            : Colors.red.shade600,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '\$${ticker.currentPrice!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ticker.percentChange != null && ticker.percentChange! >= 0 
                              ? Colors.green.shade600 
                              : Colors.red.shade600,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Close search results when tapping outside
        if (_showResults) {
          setState(() {
            _showResults = false;
          });
          _removeOverlay();
          _searchController.clear();
        }
      },
      child: SizedBox(
        key: _searchFieldKey,
        height: 44,
                child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: (value) {
          if (value.length >= 2) {
            _performSearch(value);
          } else if (value.isEmpty) {
            setState(() {
              _searchResults = [];
              _showResults = false;
            });
            _removeOverlay();
          }
        },
        textInputAction: TextInputAction.search,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF1F2937),
          fontFamily: Constants.FONT_DEFAULT_NEW,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: widget.isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
          hintText: 'Search symbols, ETFs, or stocks...',
          hintStyle: TextStyle(
            color: widget.isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            fontSize: 15,
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: true,
          fillColor: widget.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFF4F46E5),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Color(0xFFDC2626),
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Color(0xFFDC2626),
              width: 1.5,
            ),
          ),
        ),
      ),
    ));
  }
}

class _MarketIndicesStrip extends StatelessWidget {
  final FinhubController controller;
  final bool isDarkMode;

  const _MarketIndicesStrip({
    required this.controller,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.indices.isEmpty) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(
              8,
              (i) => Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: ShimmerWidgets.box(
                    width: 120,
                    height: 18,
                    borderRadius: BorderRadius.circular(6),
                    baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                    highlightColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      if (controller.indices.isEmpty) {
        return const SizedBox.shrink();
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: controller.indices
              .take(20)
              .map(
                (index) => Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: _IndexItem(
                      index: index,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ),
              )
              .toList(),
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
    final color = index.isPositive 
        ? const Color(0xFF10B981) 
        : const Color(0xFFEF4444);
    final icon = index.isPositive 
        ? Icons.arrow_upward 
        : Icons.arrow_downward;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MusaffaAutoSizeText.labelMedium(
          index.displayName,
          color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF1F2937),
          group: MusaffaAutoSizeText.groups.labelMediumGroup,
        ),
        const SizedBox(width: 6),
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        MusaffaAutoSizeText.labelMedium(
          index.formattedChangePercent,
          color: color,
          group: MusaffaAutoSizeText.groups.labelMediumGroup,
        ),
      ],
    );
  }
}

// Ticker Detail Screen
class TickerDetailScreen extends StatelessWidget {
  final TickerModel ticker;

  const TickerDetailScreen({Key? key, required this.ticker}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(ticker.symbol ?? 'Stock Details'),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Logo
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: ticker.logo != null && ticker.logo!.isNotEmpty
                              ? Colors.transparent
                              : (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ticker.logo != null && ticker.logo!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildDetailLogoWidget(ticker.logo!, isDarkMode, ticker),
                              )
                            : Icon(
                                ticker.isStock ? Icons.business : Icons.show_chart,
                                size: 32,
                                color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                              ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Ticker and Company Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticker.symbol ?? '',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF1F2937),
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                              ),
                            ),
                            Text(
                              ticker.companyName ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF6B7280),
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Additional Details
                  Row(
                    children: [
                      _buildDetailItem('Type', ticker.isStock ? 'Stock' : 'ETF', isDarkMode),
                      const SizedBox(width: 24),
                      _buildDetailItem('Exchange', ticker.exchange ?? 'N/A', isDarkMode),
                      const SizedBox(width: 24),
                      _buildDetailItem('Country', ticker.countryName ?? 'N/A', isDarkMode),
                    ],
                  ),
                  
                  if (ticker.currentPrice != null) ...[
                    const SizedBox(height: 16),
                    _buildDetailItem('Current Price', '\$${ticker.currentPrice!.toStringAsFixed(2)}', isDarkMode),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You are now viewing the ${ticker.symbol} stock page. This is a placeholder for the detailed stock information screen.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
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

  Widget _buildDetailLogoWidget(String logoUrl, bool isDarkMode, TickerModel ticker) {
    if (!ticker.isStock) {
      // For ETFs, show first letter or number from name
      String initialLetter = 'E'; // Default fallback
      if (ticker.name != null && ticker.name!.isNotEmpty) {
        String name = ticker.name!.trim();
        // Find first alphanumeric character
        for (int i = 0; i < name.length; i++) {
          if (RegExp(r'[a-zA-Z0-9]').hasMatch(name[i])) {
            initialLetter = name[i].toUpperCase();
            break;
          }
        }
      }
      
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            initialLetter,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
        ),
      );
    }

    if (logoUrl.isEmpty) {
      // For stocks without logo, show first letter or number from name
      String initialLetter = 'S'; // Default fallback
      if (ticker.name != null && ticker.name!.isNotEmpty) {
        String name = ticker.name!.trim();
        // Find first alphanumeric character
        for (int i = 0; i < name.length; i++) {
          if (RegExp(r'[a-zA-Z0-9]').hasMatch(name[i])) {
            initialLetter = name[i].toUpperCase();
            break;
          }
        }
      }
      
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            initialLetter,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
              fontFamily: Constants.FONT_DEFAULT_NEW,
            ),
          ),
        ),
      );
    }

    if (logoUrl.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        logoUrl,
        fit: BoxFit.cover,
        placeholderBuilder: (context) => Icon(
          Icons.image,
          size: 32,
          color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        ),
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.broken_image,
          size: 32,
          color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        ),
      );
    } else {
      return Image.network(
        logoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.broken_image,
          size: 32,
          color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        ),
      );
    }
  }

  Widget _buildDetailItem(String label, String value, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF6B7280),
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF1F2937),
            fontFamily: Constants.FONT_DEFAULT_NEW,
          ),
        ),
      ],
    );
  }
}
