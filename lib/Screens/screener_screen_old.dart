import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Components/screener_dropdown.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';

class ScreenerScreen extends StatefulWidget {
  const ScreenerScreen({Key? key}) : super(key: key);

  @override
  State<ScreenerScreen> createState() => _ScreenerScreenState();
}

class _ScreenerScreenState extends State<ScreenerScreen> with TickerProviderStateMixin {
  bool _isWatchlistOpen = false;
  late TabController _tabController;
  String _selectedCategory = "Descriptive";

  final List<String> _filterCategories = [
    "Descriptive",
    "Fundamental", 
    "Technical",
    "Growth",
    "ETF"
  ];

  // Filter values - Descriptive
  String? _selectedExchange;
  String? _selectedSector;
  String? _selectedIndustry;
  String? _selectedCountry;
  String? _selectedMarketCap;
  String? _selectedSharesOutstanding;
  String? _selectedPrice;
  String? _selectedVolume;
  String? _selectedVolume10Days;
  String? _selectedVolume30Days;
  String? _selectedPriceChangeYTD;
  String? _selectedIPODate;

  // Filter values - Fundamental
  String? _selectedPEAnnual;
  String? _selectedPETTM;
  String? _selectedPBAnnual;
  String? _selectedPSAnnual;
  String? _selectedPSTTM;
  String? _selectedAnalystRecommendation;
  String? _selectedCurrentRatio;
  String? _selectedDebtEquity;
  String? _selectedNetMargin;
  String? _selectedROI;
  String? _selectedDividendYield;
  String? _selectedROE;
  String? _selectedROA;
  String? _selectedGrossMargin;
  String? _selectedOperatingMargin;
  String? _selectedQuickRatio;
  String? _selectedCashToDebt;
  String? _selectedAssetTurnover;
  String? _selectedInventoryTurnover;
  String? _selectedReceivablesTurnover;
  String? _selectedPayoutRatio;
  String? _selectedEPSGrowth;
  String? _selectedRevenueGrowth;

  // Filter values - Technical
  String? _selectedPriceChange1D;
  String? _selectedPriceChange1M;
  String? _selectedPriceChange1Y;
  String? _selectedBeta;
  String? _selected52WeekHigh;
  String? _selected52WeekLow;

  // Filter values - Growth
  String? _selectedRevenueGrowth3Y;
  String? _selectedRevenueGrowth5Y;
  String? _selectedEarningsGrowth3Y;
  String? _selectedEarningsGrowth5Y;

  // Filter values - ETF
  String? _selectedAUM;
  String? _selectedHoldingsCount;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterCategories.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = _filterCategories[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleWatchlist() {
    setState(() {
      _isWatchlistOpen = !_isWatchlistOpen;
      
      // When opening the watchlist, reset to default watchlist
      if (_isWatchlistOpen) {
        final watchlistController = Get.find<WatchlistController>();
        watchlistController.resetToDefaultWatchlist();
      }
    });
  }

  void _applyFilters() {
    // TODO: Implement actual filtering logic
    // For now, just update the results counter
    setState(() {
      // This will trigger a rebuild and show updated results
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Tab bar with back button
                  HomeTabBar(
                    showBackButton: true,
                    onWatchlistToggle: _toggleWatchlist,
                    isWatchlistOpen: _isWatchlistOpen,
                  ),
                  
                  // Screener content
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          _buildHeader(isDarkMode),
                          const SizedBox(height: 24),
                          
                          // Filter content
                          Expanded(
                            child: _buildFilterContent(isDarkMode),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Results section
                          _buildResultsSection(isDarkMode),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Watchlist sidebar
              if (_isWatchlistOpen)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: WatchlistSidebar(
                    isDarkMode: isDarkMode,
                    onClose: () => setState(() => _isWatchlistOpen = false),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      children: [
        Text(
          'STOCK SCREENER',
          style: DashboardTextStyles.tickerSymbol.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF4F5F7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            '${_getResultsCount()} Results',
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 12,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(bool isDarkMode) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _filterCategories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final isSelected = _tabController.index == index;
            
            return GestureDetector(
              onTap: () {
                _tabController.animateTo(index);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF4F5F7))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected 
                      ? Border.all(
                          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                          width: 1,
                        )
                      : null,
                ),
                child: Text(
                  category,
                  style: DashboardTextStyles.tickerSymbol.copyWith(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? (isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151))
                        : (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterContent(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter category tabs
          _buildFilterTabs(isDarkMode),
          const SizedBox(height: 16),
          
          Text(
            '$_selectedCategory Filters',
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 16),
          
          // Filter grid
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: _buildFilterGrid(isDarkMode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterGrid(bool isDarkMode) {
    final filters = _getFiltersForCategory(_selectedCategory, isDarkMode);
    final crossAxisCount = 4;
    final rows = (filters.length / crossAxisCount).ceil();
    
    return Column(
      children: List.generate(rows, (rowIndex) {
        final startIndex = rowIndex * crossAxisCount;
        final endIndex = (startIndex + crossAxisCount).clamp(0, filters.length);
        final rowFilters = filters.sublist(startIndex, endIndex);
        
        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? 12 : 0),
          child: Row(
            children: List.generate(crossAxisCount, (colIndex) {
              if (colIndex < rowFilters.length) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: colIndex < crossAxisCount - 1 ? 16 : 0),
                    child: rowFilters[colIndex],
                  ),
                );
              } else {
                return const Expanded(child: SizedBox());
              }
            }),
          ),
        );
      }),
    );
  }

  List<Widget> _getFiltersForCategory(String category, bool isDarkMode) {
    switch (category) {
      case "Descriptive":
        return _getDescriptiveFilters(isDarkMode);
      case "Fundamental":
        return _getFundamentalFilters(isDarkMode);
      case "Technical":
        return _getTechnicalFilters(isDarkMode);
      case "Growth":
        return _getGrowthFilters(isDarkMode);
      case "ETF":
        return _getETFFilters(isDarkMode);
      default:
        return [];
    }
  }

  List<Widget> _getDescriptiveFilters(bool isDarkMode) {
    return [
      // Exchange
      ScreenerDropdown(
        label: 'Exchange',
        value: _selectedExchange,
        options: const [
          {"value": "NYSE", "label": "NYSE"},
          {"value": "NASDAQ", "label": "NASDAQ"},
          {"value": "AMEX", "label": "AMEX"},
          {"value": "LSE", "label": "LSE"},
          {"value": "TSX", "label": "TSX"},
          {"value": "HKEX", "label": "HKEX"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedExchange = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Sector
      ScreenerDropdown(
        label: 'Sector',
        value: _selectedSector,
        options: const [
          {"value": "Technology", "label": "Technology"},
          {"value": "Healthcare", "label": "Healthcare"},
          {"value": "Financial Services", "label": "Financial Services"},
          {"value": "Consumer Cyclical", "label": "Consumer Cyclical"},
          {"value": "Industrials", "label": "Industrials"},
          {"value": "Consumer Defensive", "label": "Consumer Defensive"},
          {"value": "Energy", "label": "Energy"},
          {"value": "Utilities", "label": "Utilities"},
          {"value": "Real Estate", "label": "Real Estate"},
          {"value": "Communication Services", "label": "Communication Services"},
          {"value": "Basic Materials", "label": "Basic Materials"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedSector = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Industry
      ScreenerDropdown(
        label: 'Industry',
        value: _selectedIndustry,
        options: const [
          {"value": "Software", "label": "Software"},
          {"value": "Semiconductors", "label": "Semiconductors"},
          {"value": "Banks", "label": "Banks"},
          {"value": "Pharmaceuticals", "label": "Pharmaceuticals"},
          {"value": "Oil & Gas", "label": "Oil & Gas"},
          {"value": "Biotechnology", "label": "Biotechnology"},
          {"value": "Auto Manufacturers", "label": "Auto Manufacturers"},
          {"value": "Retail", "label": "Retail"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedIndustry = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Country
      ScreenerDropdown(
        label: 'Country',
        value: _selectedCountry,
        options: const [
          {"value": "United States", "label": "United States"},
          {"value": "China", "label": "China"},
          {"value": "United Kingdom", "label": "United Kingdom"},
          {"value": "Canada", "label": "Canada"},
          {"value": "Germany", "label": "Germany"},
          {"value": "Japan", "label": "Japan"},
          {"value": "France", "label": "France"},
          {"value": "India", "label": "India"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedCountry = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Market Cap
      ScreenerDropdown(
        label: 'Market Cap',
        value: _selectedMarketCap,
        options: const [
          {"value": "under_50m", "label": "Nano (Under \$50M)"},
          {"value": "50m_300m", "label": "Micro (\$50M - \$300M)"},
          {"value": "300m_2b", "label": "Small (\$300M - \$2B)"},
          {"value": "2b_10b", "label": "Mid (\$2B - \$10B)"},
          {"value": "10b_200b", "label": "Large (\$10B - \$200B)"},
          {"value": "over_200b", "label": "Mega (Over \$200B)"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedMarketCap = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Shares Outstanding
      ScreenerDropdown(
        label: 'Shares Outstanding',
        value: _selectedSharesOutstanding,
        options: const [
          {"value": "under_10m", "label": "Under 10M"},
          {"value": "10m_50m", "label": "10M - 50M"},
          {"value": "50m_100m", "label": "50M - 100M"},
          {"value": "100m_500m", "label": "100M - 500M"},
          {"value": "500m_1b", "label": "500M - 1B"},
          {"value": "over_1b", "label": "Over 1B"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedSharesOutstanding = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Price
      ScreenerDropdown(
        label: 'Price',
        value: _selectedPrice,
        options: const [
          {"value": "under_1", "label": "Under \$1"},
          {"value": "1_5", "label": "\$1 - \$5"},
          {"value": "5_10", "label": "\$5 - \$10"},
          {"value": "10_20", "label": "\$10 - \$20"},
          {"value": "20_50", "label": "\$20 - \$50"},
          {"value": "50_100", "label": "\$50 - \$100"},
          {"value": "over_100", "label": "Over \$100"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedPrice = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Volume
      ScreenerDropdown(
        label: 'Volume',
        value: _selectedVolume,
        options: const [
          {"value": "under_50k", "label": "Under 50K"},
          {"value": "50k_100k", "label": "50K - 100K"},
          {"value": "100k_500k", "label": "100K - 500K"},
          {"value": "500k_1m", "label": "500K - 1M"},
          {"value": "1m_5m", "label": "1M - 5M"},
          {"value": "over_5m", "label": "Over 5M"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedVolume = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Avg Volume 10D
      ScreenerDropdown(
        label: 'Avg Volume 10D',
        value: _selectedVolume10Days,
        options: const [
          {"value": "under_50k", "label": "Under 50K"},
          {"value": "50k_100k", "label": "50K - 100K"},
          {"value": "100k_500k", "label": "100K - 500K"},
          {"value": "500k_1m", "label": "500K - 1M"},
          {"value": "1m_5m", "label": "1M - 5M"},
          {"value": "over_5m", "label": "Over 5M"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedVolume10Days = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Avg Volume 30D
      ScreenerDropdown(
        label: 'Avg Volume 30D',
        value: _selectedVolume30Days,
        options: const [
          {"value": "under_50k", "label": "Under 50K"},
          {"value": "50k_100k", "label": "50K - 100K"},
          {"value": "100k_500k", "label": "100K - 500K"},
          {"value": "500k_1m", "label": "500K - 1M"},
          {"value": "1m_5m", "label": "1M - 5M"},
          {"value": "over_5m", "label": "Over 5M"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedVolume30Days = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // YTD Performance
      ScreenerDropdown(
        label: 'YTD Performance',
        value: _selectedPriceChangeYTD,
        options: const [
          {"value": "under_minus30", "label": "Down >30%"},
          {"value": "minus30_minus20", "label": "Down 20-30%"},
          {"value": "minus20_minus10", "label": "Down 10-20%"},
          {"value": "minus10_0", "label": "Down 0-10%"},
          {"value": "0_10", "label": "Up 0-10%"},
          {"value": "10_20", "label": "Up 10-20%"},
          {"value": "20_30", "label": "Up 20-30%"},
          {"value": "over_30", "label": "Up >30%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedPriceChangeYTD = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // IPO Date
      ScreenerDropdown(
        label: 'IPO Date',
        value: _selectedIPODate,
        options: const [
          {"value": "within_1y", "label": "Within 1 Year"},
          {"value": "1y_3y", "label": "1-3 Years Ago"},
          {"value": "3y_5y", "label": "3-5 Years Ago"},
          {"value": "5y_10y", "label": "5-10 Years Ago"},
          {"value": "over_10y", "label": "Over 10 Years Ago"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedIPODate = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
    ];
  }

  List<Widget> _getFundamentalFilters(bool isDarkMode) {
    return [
      // P/E Annual
      ScreenerDropdown(
        label: 'P/E Annual',
        value: _selectedPEAnnual,
        options: const [
          {"value": "under_5", "label": "Under 5"},
          {"value": "5_10", "label": "5 - 10"},
          {"value": "10_15", "label": "10 - 15"},
          {"value": "15_20", "label": "15 - 20"},
          {"value": "20_25", "label": "20 - 25"},
          {"value": "25_30", "label": "25 - 30"},
          {"value": "over_30", "label": "Over 30"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedPEAnnual = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // P/E TTM
      ScreenerDropdown(
        label: 'P/E TTM',
        value: _selectedPETTM,
        options: const [
          {"value": "under_5", "label": "Under 5"},
          {"value": "5_10", "label": "5 - 10"},
          {"value": "10_15", "label": "10 - 15"},
          {"value": "15_20", "label": "15 - 20"},
          {"value": "20_25", "label": "20 - 25"},
          {"value": "25_30", "label": "25 - 30"},
          {"value": "over_30", "label": "Over 30"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedPETTM = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // P/B Annual
      ScreenerDropdown(
        label: 'P/B Annual',
        value: _selectedPBAnnual,
        options: const [
          {"value": "under_1", "label": "Under 1"},
          {"value": "1_2", "label": "1 - 2"},
          {"value": "2_3", "label": "2 - 3"},
          {"value": "3_5", "label": "3 - 5"},
          {"value": "over_5", "label": "Over 5"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedPBAnnual = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // P/S Annual
      ScreenerDropdown(
        label: 'P/S Annual',
        value: _selectedPSAnnual,
        options: const [
          {"value": "under_1", "label": "Under 1"},
          {"value": "1_2", "label": "1 - 2"},
          {"value": "2_3", "label": "2 - 3"},
          {"value": "3_5", "label": "3 - 5"},
          {"value": "5_10", "label": "5 - 10"},
          {"value": "over_10", "label": "Over 10"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedPSAnnual = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // P/S TTM
      ScreenerDropdown(
        label: 'P/S TTM',
        value: _selectedPSTTM,
        options: const [
          {"value": "under_1", "label": "Under 1"},
          {"value": "1_2", "label": "1 - 2"},
          {"value": "2_3", "label": "2 - 3"},
          {"value": "3_5", "label": "3 - 5"},
          {"value": "5_10", "label": "5 - 10"},
          {"value": "over_10", "label": "Over 10"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedPSTTM = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Analyst Recommendation
      ScreenerDropdown(
        label: 'Analyst Recommendation',
        value: _selectedAnalystRecommendation,
        options: const [
          {"value": "1_1.5", "label": "Strong Buy (1-1.5)"},
          {"value": "1.5_2.5", "label": "Buy (1.5-2.5)"},
          {"value": "2.5_3.5", "label": "Hold (2.5-3.5)"},
          {"value": "3.5_4.5", "label": "Sell (3.5-4.5)"},
          {"value": "4.5_5", "label": "Strong Sell (4.5-5)"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedAnalystRecommendation = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Current Ratio
      ScreenerDropdown(
        label: 'Current Ratio',
        value: _selectedCurrentRatio,
        options: const [
          {"value": "under_1", "label": "Under 1"},
          {"value": "1_2", "label": "1 - 2"},
          {"value": "2_3", "label": "2 - 3"},
          {"value": "over_3", "label": "Over 3"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedCurrentRatio = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Debt/Equity
      ScreenerDropdown(
        label: 'Debt/Equity',
        value: _selectedDebtEquity,
        options: const [
          {"value": "under_0.5", "label": "Under 0.5"},
          {"value": "0.5_1", "label": "0.5 - 1"},
          {"value": "1_2", "label": "1 - 2"},
          {"value": "over_2", "label": "Over 2"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedDebtEquity = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Net Margin
      ScreenerDropdown(
        label: 'Net Margin',
        value: _selectedNetMargin,
        options: const [
          {"value": "negative", "label": "Negative"},
          {"value": "0_5", "label": "0% - 5%"},
          {"value": "5_10", "label": "5% - 10%"},
          {"value": "10_20", "label": "10% - 20%"},
          {"value": "over_20", "label": "Over 20%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedNetMargin = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // ROI
      ScreenerDropdown(
        label: 'ROI',
        value: _selectedROI,
        options: const [
          {"value": "negative", "label": "Negative"},
          {"value": "0_5", "label": "0% - 5%"},
          {"value": "5_10", "label": "5% - 10%"},
          {"value": "10_20", "label": "10% - 20%"},
          {"value": "over_20", "label": "Over 20%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedROI = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Dividend Yield
      ScreenerDropdown(
        label: 'Dividend Yield',
        value: _selectedDividendYield,
        options: const [
          {"value": "0", "label": "0%"},
          {"value": "1_2", "label": "1% - 2%"},
          {"value": "2_3", "label": "2% - 3%"},
          {"value": "3_5", "label": "3% - 5%"},
          {"value": "over_5", "label": "Over 5%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedDividendYield = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // ROE
      ScreenerDropdown(
        label: 'ROE',
        value: _selectedROE,
        options: const [
          {"value": "negative", "label": "Negative"},
          {"value": "0_5", "label": "0% - 5%"},
          {"value": "5_10", "label": "5% - 10%"},
          {"value": "10_15", "label": "10% - 15%"},
          {"value": "15_20", "label": "15% - 20%"},
          {"value": "over_20", "label": "Over 20%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedROE = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // ROA
      ScreenerDropdown(
        label: 'ROA',
        value: _selectedROA,
        options: const [
          {"value": "negative", "label": "Negative"},
          {"value": "0_2", "label": "0% - 2%"},
          {"value": "2_5", "label": "2% - 5%"},
          {"value": "5_10", "label": "5% - 10%"},
          {"value": "10_15", "label": "10% - 15%"},
          {"value": "over_15", "label": "Over 15%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedROA = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Gross Margin
      ScreenerDropdown(
        label: 'Gross Margin',
        value: _selectedGrossMargin,
        options: const [
          {"value": "negative", "label": "Negative"},
          {"value": "0_10", "label": "0% - 10%"},
          {"value": "10_20", "label": "10% - 20%"},
          {"value": "20_30", "label": "20% - 30%"},
          {"value": "30_50", "label": "30% - 50%"},
          {"value": "over_50", "label": "Over 50%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedGrossMargin = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Operating Margin
      ScreenerDropdown(
        label: 'Operating Margin',
        value: _selectedOperatingMargin,
        options: const [
          {"value": "negative", "label": "Negative"},
          {"value": "0_5", "label": "0% - 5%"},
          {"value": "5_10", "label": "5% - 10%"},
          {"value": "10_15", "label": "10% - 15%"},
          {"value": "15_25", "label": "15% - 25%"},
          {"value": "over_25", "label": "Over 25%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedOperatingMargin = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Quick Ratio
      ScreenerDropdown(
        label: 'Quick Ratio',
        value: _selectedQuickRatio,
        options: const [
          {"value": "under_0.5", "label": "Under 0.5"},
          {"value": "0.5_1", "label": "0.5 - 1"},
          {"value": "1_1.5", "label": "1 - 1.5"},
          {"value": "1.5_2", "label": "1.5 - 2"},
          {"value": "over_2", "label": "Over 2"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedQuickRatio = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Cash to Debt
      ScreenerDropdown(
        label: 'Cash to Debt',
        value: _selectedCashToDebt,
        options: const [
          {"value": "under_0.1", "label": "Under 0.1"},
          {"value": "0.1_0.3", "label": "0.1 - 0.3"},
          {"value": "0.3_0.5", "label": "0.3 - 0.5"},
          {"value": "0.5_1", "label": "0.5 - 1"},
          {"value": "over_1", "label": "Over 1"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedCashToDebt = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Asset Turnover
      ScreenerDropdown(
        label: 'Asset Turnover',
        value: _selectedAssetTurnover,
        options: const [
          {"value": "under_0.5", "label": "Under 0.5"},
          {"value": "0.5_1", "label": "0.5 - 1"},
          {"value": "1_1.5", "label": "1 - 1.5"},
          {"value": "1.5_2", "label": "1.5 - 2"},
          {"value": "over_2", "label": "Over 2"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedAssetTurnover = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Inventory Turnover
      ScreenerDropdown(
        label: 'Inventory Turnover',
        value: _selectedInventoryTurnover,
        options: const [
          {"value": "under_2", "label": "Under 2"},
          {"value": "2_5", "label": "2 - 5"},
          {"value": "5_10", "label": "5 - 10"},
          {"value": "10_20", "label": "10 - 20"},
          {"value": "over_20", "label": "Over 20"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedInventoryTurnover = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Receivables Turnover
      ScreenerDropdown(
        label: 'Receivables Turnover',
        value: _selectedReceivablesTurnover,
        options: const [
          {"value": "under_5", "label": "Under 5"},
          {"value": "5_10", "label": "5 - 10"},
          {"value": "10_15", "label": "10 - 15"},
          {"value": "15_25", "label": "15 - 25"},
          {"value": "over_25", "label": "Over 25"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedReceivablesTurnover = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Payout Ratio
      ScreenerDropdown(
        label: 'Payout Ratio',
        value: _selectedPayoutRatio,
        options: const [
          {"value": "0", "label": "0%"},
          {"value": "0_25", "label": "0% - 25%"},
          {"value": "25_50", "label": "25% - 50%"},
          {"value": "50_75", "label": "50% - 75%"},
          {"value": "over_75", "label": "Over 75%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedPayoutRatio = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // EPS Growth
      ScreenerDropdown(
        label: 'EPS Growth',
        value: _selectedEPSGrowth,
        options: const [
          {"value": "negative", "label": "Negative"},
          {"value": "0_5", "label": "0% - 5%"},
          {"value": "5_10", "label": "5% - 10%"},
          {"value": "10_20", "label": "10% - 20%"},
          {"value": "20_50", "label": "20% - 50%"},
          {"value": "over_50", "label": "Over 50%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedEPSGrowth = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Revenue Growth
      ScreenerDropdown(
        label: 'Revenue Growth',
        value: _selectedRevenueGrowth,
        options: const [
          {"value": "negative", "label": "Negative"},
          {"value": "0_5", "label": "0% - 5%"},
          {"value": "5_10", "label": "5% - 10%"},
          {"value": "10_20", "label": "10% - 20%"},
          {"value": "20_50", "label": "20% - 50%"},
          {"value": "over_50", "label": "Over 50%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedRevenueGrowth = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
    ];
  }

  List<Widget> _getTechnicalFilters(bool isDarkMode) {
    return [
      // Price Change 1D
      ScreenerDropdown(
        label: 'Price Change 1D',
        value: _selectedPriceChange1D,
        options: const [
          {"value": "under_minus10", "label": "Under -10%"},
          {"value": "minus10_minus5", "label": "-10% to -5%"},
          {"value": "minus5_0", "label": "-5% to 0%"},
          {"value": "0_5", "label": "0% to 5%"},
          {"value": "5_10", "label": "5% to 10%"},
          {"value": "over_10", "label": "Over 10%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedPriceChange1D = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Price Change 1M
      ScreenerDropdown(
        label: 'Price Change 1M',
        value: _selectedPriceChange1M,
        options: const [
          {"value": "under_minus20", "label": "Under -20%"},
          {"value": "minus20_minus10", "label": "-20% to -10%"},
          {"value": "minus10_0", "label": "-10% to 0%"},
          {"value": "0_10", "label": "0% to 10%"},
          {"value": "10_20", "label": "10% to 20%"},
          {"value": "over_20", "label": "Over 20%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedPriceChange1M = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Price Change 1Y
      ScreenerDropdown(
        label: 'Price Change 1Y',
        value: _selectedPriceChange1Y,
        options: const [
          {"value": "under_minus50", "label": "Under -50%"},
          {"value": "minus50_minus20", "label": "-50% to -20%"},
          {"value": "minus20_0", "label": "-20% to 0%"},
          {"value": "0_20", "label": "0% to 20%"},
          {"value": "20_50", "label": "20% to 50%"},
          {"value": "over_50", "label": "Over 50%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedPriceChange1Y = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Beta
      ScreenerDropdown(
        label: 'Beta',
        value: _selectedBeta,
        options: const [
          {"value": "under_0.5", "label": "Under 0.5"},
          {"value": "0.5_1", "label": "0.5 - 1"},
          {"value": "1_1.5", "label": "1 - 1.5"},
          {"value": "over_1.5", "label": "Over 1.5"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedBeta = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // 52 Week High
      ScreenerDropdown(
        label: '52W High',
        value: _selected52WeekHigh,
        options: const [
          {"value": "under_10", "label": "Under \$10"},
          {"value": "10_50", "label": "\$10 - \$50"},
          {"value": "50_100", "label": "\$50 - \$100"},
          {"value": "over_100", "label": "Over \$100"},
        ],
        onChanged: (value) {
          setState(() {
            _selected52WeekHigh = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // 52 Week Low
      ScreenerDropdown(
        label: '52W Low',
        value: _selected52WeekLow,
        options: const [
          {"value": "under_10", "label": "Under \$10"},
          {"value": "10_50", "label": "\$10 - \$50"},
          {"value": "50_100", "label": "\$50 - \$100"},
          {"value": "over_100", "label": "Over \$100"},
        ],
        onChanged: (value) {
          setState(() {
            _selected52WeekLow = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
    ];
  }

  List<Widget> _getGrowthFilters(bool isDarkMode) {
    return [
      // Revenue Growth 3Y
      ScreenerDropdown(
        label: 'Revenue Growth 3Y',
        value: _selectedRevenueGrowth3Y,
        options: const [
          {"value": "negative", "label": "Negative"},
          {"value": "0_5", "label": "0% - 5%"},
          {"value": "5_10", "label": "5% - 10%"},
          {"value": "10_20", "label": "10% - 20%"},
          {"value": "over_20", "label": "Over 20%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedRevenueGrowth3Y = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Revenue Growth 5Y
      ScreenerDropdown(
        label: 'Revenue Growth 5Y',
        value: _selectedRevenueGrowth5Y,
        options: const [
          {"value": "negative", "label": "Negative"},
          {"value": "0_5", "label": "0% - 5%"},
          {"value": "5_10", "label": "5% - 10%"},
          {"value": "10_20", "label": "10% - 20%"},
          {"value": "over_20", "label": "Over 20%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedRevenueGrowth5Y = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Earnings Growth 3Y
      ScreenerDropdown(
        label: 'Earnings Growth 3Y',
        value: _selectedEarningsGrowth3Y,
        options: const [
          {"value": "negative", "label": "Negative"},
          {"value": "0_10", "label": "0% - 10%"},
          {"value": "10_25", "label": "10% - 25%"},
          {"value": "25_50", "label": "25% - 50%"},
          {"value": "over_50", "label": "Over 50%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedEarningsGrowth3Y = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Earnings Growth 5Y
      ScreenerDropdown(
        label: 'Earnings Growth 5Y',
        value: _selectedEarningsGrowth5Y,
        options: const [
          {"value": "negative", "label": "Negative"},
          {"value": "0_10", "label": "0% - 10%"},
          {"value": "10_25", "label": "10% - 25%"},
          {"value": "25_50", "label": "25% - 50%"},
          {"value": "over_50", "label": "Over 50%"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedEarningsGrowth5Y = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
    ];
  }

  List<Widget> _getETFFilters(bool isDarkMode) {
    return [
      // AUM
      ScreenerDropdown(
        label: 'AUM',
        value: _selectedAUM,
        options: const [
          {"value": "under_100m", "label": "Under \$100M"},
          {"value": "100m_1b", "label": "\$100M - \$1B"},
          {"value": "1b_10b", "label": "\$1B - \$10B"},
          {"value": "over_10b", "label": "Over \$10B"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedAUM = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
      
      // Holdings Count
      ScreenerDropdown(
        label: 'Holdings Count',
        value: _selectedHoldingsCount,
        options: const [
          {"value": "under_50", "label": "Under 50"},
          {"value": "50_100", "label": "50 - 100"},
          {"value": "100_500", "label": "100 - 500"},
          {"value": "over_500", "label": "Over 500"},
        ],
        onChanged: (value) {
          setState(() {
            _selectedHoldingsCount = value;
          });
          _applyFilters();
        },
        isDarkMode: isDarkMode,
      ),
    ];
  }

  Widget _buildFilterPlaceholder(bool isDarkMode, int index) {
    final filterNames = _getFilterNamesForCategory(_selectedCategory);
    final filterName = index < filterNames.length ? filterNames[index] : 'Filter ${index + 1}';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            filterName,
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 11,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Center(
              child: Text(
                'Any',
                style: DashboardTextStyles.tickerSymbol.copyWith(
                  fontSize: 11,
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(bool isDarkMode) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Results',
            style: DashboardTextStyles.tickerSymbol.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Text(
                'No filters applied yet. Use the filters above to screen stocks.',
                style: DashboardTextStyles.tickerSymbol.copyWith(
                  fontSize: 14,
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getFilterCountForCategory(String category) {
    switch (category) {
      case 'Descriptive':
        return 3; // Exchange, Sector, Market Cap
      case 'Fundamental':
        return 12; // P/E, Forward P/E, PEG, P/S, P/B, EV/EBITDA, ROE, Net Margin, Gross Margin, Debt/Equity, Current Ratio, Dividend Yield
      case 'Technical':
        return 10; // Change (1D, 1W, 1M, 1Y), Volume, Relative Volume, Beta, Price Range, 52W High/Low
      case 'Growth':
        return 5; // EPS Growth (1Y, 3Y), Revenue Growth (1Y, 3Y), Market Cap Growth
      case 'ETF':
        return 2; // AUM, Holdings Count
      default:
        return 4;
    }
  }

  List<String> _getFilterNamesForCategory(String category) {
    switch (category) {
      case 'Descriptive':
        return ['Exchange', 'Sector', 'Market Cap'];
      case 'Fundamental':
        return ['P/E', 'Forward P/E', 'PEG', 'P/S', 'P/B', 'EV/EBITDA', 'ROE', 'Net Margin', 'Gross Margin', 'Debt/Equity', 'Current Ratio', 'Dividend Yield'];
      case 'Technical':
        return ['Change', 'Change (1W)', 'Change (1M)', 'Change (1Y)', 'Volume', 'Relative Volume', 'Beta', 'Price Range', '52W High', '52W Low'];
      case 'Growth':
        return ['EPS Growth 1Y', 'EPS Growth 3Y', 'Revenue Growth 1Y', 'Revenue Growth 3Y', 'Market Cap Growth'];
      case 'ETF':
        return ['AUM', 'Holdings Count'];
      default:
        return ['Filter 1', 'Filter 2', 'Filter 3', 'Filter 4'];
    }
  }

  int _getResultsCount() {
    // Count how many filters are applied
    int appliedFilters = 0;
    
    // Descriptive filters
    if (_selectedExchange != null) appliedFilters++;
    if (_selectedSector != null) appliedFilters++;
    if (_selectedIndustry != null) appliedFilters++;
    if (_selectedCountry != null) appliedFilters++;
    if (_selectedMarketCap != null) appliedFilters++;
    if (_selectedSharesOutstanding != null) appliedFilters++;
    if (_selectedPrice != null) appliedFilters++;
    if (_selectedVolume != null) appliedFilters++;
    if (_selectedVolume10Days != null) appliedFilters++;
    if (_selectedVolume30Days != null) appliedFilters++;
    if (_selectedPriceChangeYTD != null) appliedFilters++;
    if (_selectedIPODate != null) appliedFilters++;
    
    // Fundamental filters
    if (_selectedPEAnnual != null) appliedFilters++;
    if (_selectedPETTM != null) appliedFilters++;
    if (_selectedPBAnnual != null) appliedFilters++;
    if (_selectedPSAnnual != null) appliedFilters++;
    if (_selectedPSTTM != null) appliedFilters++;
    if (_selectedAnalystRecommendation != null) appliedFilters++;
    if (_selectedCurrentRatio != null) appliedFilters++;
    if (_selectedDebtEquity != null) appliedFilters++;
    if (_selectedNetMargin != null) appliedFilters++;
    if (_selectedROI != null) appliedFilters++;
    if (_selectedDividendYield != null) appliedFilters++;
    if (_selectedROE != null) appliedFilters++;
    if (_selectedROA != null) appliedFilters++;
    if (_selectedGrossMargin != null) appliedFilters++;
    if (_selectedOperatingMargin != null) appliedFilters++;
    if (_selectedQuickRatio != null) appliedFilters++;
    if (_selectedCashToDebt != null) appliedFilters++;
    if (_selectedAssetTurnover != null) appliedFilters++;
    if (_selectedInventoryTurnover != null) appliedFilters++;
    if (_selectedReceivablesTurnover != null) appliedFilters++;
    if (_selectedPayoutRatio != null) appliedFilters++;
    if (_selectedEPSGrowth != null) appliedFilters++;
    if (_selectedRevenueGrowth != null) appliedFilters++;
    
    // Technical filters
    if (_selectedPriceChange1D != null) appliedFilters++;
    if (_selectedPriceChange1M != null) appliedFilters++;
    if (_selectedPriceChange1Y != null) appliedFilters++;
    if (_selectedBeta != null) appliedFilters++;
    if (_selected52WeekHigh != null) appliedFilters++;
    if (_selected52WeekLow != null) appliedFilters++;
    
    // Growth filters
    if (_selectedRevenueGrowth3Y != null) appliedFilters++;
    if (_selectedRevenueGrowth5Y != null) appliedFilters++;
    if (_selectedEarningsGrowth3Y != null) appliedFilters++;
    if (_selectedEarningsGrowth5Y != null) appliedFilters++;
    
    // ETF filters
    if (_selectedAUM != null) appliedFilters++;
    if (_selectedHoldingsCount != null) appliedFilters++;
    
    // For demo purposes, return a mock count based on applied filters
    if (appliedFilters == 0) return 0;
    if (appliedFilters <= 2) return 1250;
    if (appliedFilters <= 4) return 850;
    if (appliedFilters <= 6) return 420;
    if (appliedFilters <= 8) return 180;
    if (appliedFilters <= 10) return 75;
    if (appliedFilters <= 12) return 23;
    if (appliedFilters <= 15) return 8;
    if (appliedFilters <= 18) return 3;
    if (appliedFilters <= 20) return 1;
    
    return 0;
  }
}
