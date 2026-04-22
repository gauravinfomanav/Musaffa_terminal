import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Components/global_fab_overlay.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/Controllers/portfolio_controller.dart';
import 'package:musaffa_terminal/models/portfolio_model.dart';
import 'package:musaffa_terminal/Screens/portfolio_builder_form.dart';

class PortfolioIdeaScreen extends StatefulWidget {
  const PortfolioIdeaScreen({super.key});

  @override
  State<PortfolioIdeaScreen> createState() => _PortfolioIdeaScreenState();
}

class _PortfolioIdeaScreenState extends State<PortfolioIdeaScreen> with SingleTickerProviderStateMixin {
  late final WatchlistController _watchlistController;
  final GlobalWatchlistService _watchlistService = Get.find<GlobalWatchlistService>();
  bool _isNewIdeaExpanded = false;
  late TabController _tabController;
  int _selectedTabIndex = 0;
  int _previousTabIndex = 0;

  late PortfolioController _portfolioController;

  @override
  void initState() {
    super.initState();
    _watchlistController = Get.put(WatchlistController());
    _portfolioController = Get.put(PortfolioController());
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Only update UI state when animation is complete
        final newIndex = _tabController.index;
        if (newIndex != _previousTabIndex) {
      setState(() {
            _selectedTabIndex = newIndex;
            _previousTabIndex = newIndex;
      });
        }
      }
    });
    // Load active portfolios on init - defer to after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _portfolioController.fetchActivePortfolios();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleWatchlist() {
    if (!_watchlistService.isWatchlistOpen.value) {
      _watchlistController.resetToDefaultWatchlist();
    }
    _watchlistService.toggleWatchlist();
  }

  void _toggleNewIdeaForm() {
    setState(() {
      _isNewIdeaExpanded = !_isNewIdeaExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
      body: GestureDetector(
        onTap: () {
          if (_watchlistService.isWatchlistOpen.value) {
            _watchlistService.closeWatchlist();
          }
        },
        child: Stack(
          children: [
            Column(
              children: [
                Obx(() => HomeTabBar(
                  showBackButton: true,
                  isWatchlistOpen: _watchlistService.isWatchlistOpen.value,
                  onWatchlistToggle: _toggleWatchlist,
                  onThemeToggle: () {
                    final currentTheme = Theme.of(context).brightness;
                    Get.changeThemeMode(
                      currentTheme == Brightness.dark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    );
                  },
                )),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: LayoutConstants.screenPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 16),
                          // Content will be added here
                          _buildPlaceholderContent(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Obx(() {
              if (!_watchlistService.isWatchlistOpen.value) {
                return const SizedBox.shrink();
              }
              return Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {},
                  child: WatchlistSidebar(
                    isDarkMode: isDark,
                    onClose: () => _watchlistService.closeWatchlist(),
                  ),
                ),
              );
            }),
              // Global FAB Overlay
              const GlobalFABOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolios',
              style: DashboardTextStyles.titleSmall.copyWith(
                fontSize: 20,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const Spacer(),
        _PrimaryPillButton(
          label: _isNewIdeaExpanded ? 'Cancel' : 'New Portfolio',
          icon: _isNewIdeaExpanded ? Icons.close : Icons.add,
          onTap: _toggleNewIdeaForm,
          isDarkMode: isDark,
        ),
      ],
    );
  }

  Widget _buildPlaceholderContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expandable New Idea Form
        if (_isNewIdeaExpanded) ...[
          PortfolioBuilderForm(
            onCancel: () {
              setState(() {
                _isNewIdeaExpanded = false;
              });
            },
            onSaveDraft: () {
              // Save draft logic
              setState(() {
                _isNewIdeaExpanded = false;
              });
            },
            onSavePortfolio: () {
              // Save portfolio logic
              setState(() {
                _isNewIdeaExpanded = false;
              });
            },
          ),
          const SizedBox(height: 16),
        ],
        // Tabs for Active/Drafts/Archived
        _buildTabs(context),
        const SizedBox(height: 16),
        // Existing Portfolios List
        _buildPortfoliosList(context),
      ],
    );
  }

  Widget _buildTabs(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = ['Active Portfolios', 'Drafts'];
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151718) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isSelected = _selectedTabIndex == index;
          
          return GestureDetector(
            onTap: () {
              if (index != _selectedTabIndex) {
              _tabController.animateTo(index);
                // Fetch immediately on tap to avoid waiting for animation
                setState(() {
                  _selectedTabIndex = index;
                  _previousTabIndex = index;
                });
                if (index == 0) {
                  _portfolioController.fetchActivePortfolios();
                } else if (index == 1) {
                  _portfolioController.fetchDraftPortfolios();
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF81AACE) : const Color(0xFF3B82F6))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(90),
              ),
              child: Text(
                label.toUpperCase(),
                style: DashboardTextStyles.columnHeader.copyWith(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPortfoliosList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB);
    final cardColor = isDark ? const Color(0xFF151718) : Colors.white;

    final tabLabels = ['Active Portfolios', 'Drafts'];
    final emptyMessages = [
      'No active portfolios',
      'No draft portfolios',
    ];

    return Obx(() {
      final isLoading = _portfolioController.isLoading.value;
      final portfolios = _selectedTabIndex == 0
          ? _portfolioController.activePortfolios
          : _portfolioController.draftPortfolios;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tabLabels[_selectedTabIndex],
              style: DashboardTextStyles.titleSmall.copyWith(
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (portfolios.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text(
                    emptyMessages[_selectedTabIndex],
                    style: DashboardTextStyles.stockName.copyWith(
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              )
            else
              _buildPortfolioTable(portfolios, isDark),
          ],
        ),
      );
    });
  }

  Widget _buildPortfolioTable(List<PortfolioSummary> portfolios, bool isDark) {
    final rows = portfolios.map((portfolio) {
      return SimpleRowModel(
        symbol: '', // Empty - don't show ID/ticker
        name: portfolio.portfolioName, // Portfolio name shows as companyName in MainTickerCell
        logo: null, // No logo
        fields: {
          'client': _wrappedTextCell(context, portfolio.clientName, width: 180),
          'capital': _formatCurrency(portfolio.initialCapital),
          'holdings': portfolio.holdingsCount.toString(),
          'allocation': '${portfolio.allocationPercent.toStringAsFixed(1)}%',
          'returns': _formatCurrency(portfolio.estimatedReturns),
          'updated': _formatDate(portfolio.lastUpdated),
          'actions': _buildActionsMenu(portfolio, isDark),
        },
      );
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        const fixedColumnWidth = 250.0;
        const baseClient = 180.0;
        const baseCapital = 120.0;
        const baseHoldings = 100.0;
        const baseAllocation = 120.0;
        const baseReturns = 130.0;
        const baseUpdated = 140.0;
        const baseActions = 80.0;
        const totalBaseWidth = baseClient +
            baseCapital +
            baseHoldings +
            baseAllocation +
            baseReturns +
            baseUpdated +
            baseActions;

        // Fill extra horizontal space on large screens while preserving minimum widths.
        final availableForDynamicColumns =
            (constraints.maxWidth - fixedColumnWidth - 32).clamp(0.0, double.infinity);
        final widthScale = availableForDynamicColumns > totalBaseWidth
            ? (availableForDynamicColumns / totalBaseWidth)
            : 1.0;

        final columns = [
          SimpleColumn(label: 'CLIENT', fieldName: 'client', width: baseClient * widthScale),
          SimpleColumn(label: 'CAPITAL', fieldName: 'capital', width: baseCapital * widthScale, isNumeric: true),
          SimpleColumn(label: 'HOLDINGS', fieldName: 'holdings', width: baseHoldings * widthScale, isNumeric: true),
          SimpleColumn(label: 'ALLOCATION %', fieldName: 'allocation', width: baseAllocation * widthScale, isNumeric: true),
          SimpleColumn(label: 'EST. RETURNS', fieldName: 'returns', width: baseReturns * widthScale, isNumeric: true),
          SimpleColumn(label: 'LAST UPDATED', fieldName: 'updated', width: baseUpdated * widthScale),
          SimpleColumn(label: 'ACTIONS', fieldName: 'actions', width: baseActions * widthScale),
        ];

        return DynamicTable(
          columns: columns,
          rows: rows,
          showFixedColumn: true,
          considerPadding: false,
          columnSpacing: 20,
          fixedColumnWidth: fixedColumnWidth,
          enableLivePrices: false,
          zebraStripes: true,
          evenRowColor: Colors.transparent,
          oddRowColor: isDark ? const Color(0xFF14171C) : const Color(0xFFF5F6F8),
          enableColumnCustomization: true,
          tableId: 'portfolio_ideas_table',
        );
      },
    );
  }

  Widget _wrappedTextCell(BuildContext context, String text, {double? width}) {
    final display = text.isEmpty ? '--' : text.trim();
    final widget = Text(
      display,
      style: DashboardTextStyles.dataCell,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (width != null) {
      return SizedBox(width: width, child: widget);
    }
    return widget;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##,###', 'en_US');
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\$${formatter.format(amount)}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Widget _buildActionsMenu(PortfolioSummary portfolio, bool isDark) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
      ),
      color: isDark ? const Color(0xFF1B1F25) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB),
        ),
      ),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        
        if (portfolio.status == 'active') {
          items.add(
            PopupMenuItem(
              value: 'make_draft',
              child: Row(
                children: [
                  Icon(Icons.save_outlined, size: 16, color: isDark ? Colors.white70 : const Color(0xFF111827)),
                  const SizedBox(width: 8),
                  Text(
                    'Make as Draft',
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 12,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          items.add(
            PopupMenuItem(
              value: 'make_active',
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: isDark ? Colors.white70 : const Color(0xFF111827)),
                  const SizedBox(width: 8),
                  Text(
                    'Make as Active',
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 12,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        items.add(
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 16, color: isDark ? Colors.white70 : const Color(0xFF111827)),
                const SizedBox(width: 8),
                Text(
                  'Edit',
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        );
        
        items.add(
          PopupMenuItem(
            value: 'view_details',
            child: Row(
              children: [
                Icon(Icons.visibility_outlined, size: 16, color: isDark ? Colors.white70 : const Color(0xFF111827)),
                const SizedBox(width: 8),
                Text(
                  'View Details',
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        );
        
        items.add(const PopupMenuDivider());
        
        items.add(
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Delete',
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
        
        return items;
      },
      onSelected: (value) async {
        switch (value) {
          case 'make_draft':
            await _convertToDraft(portfolio.id);
            break;
          case 'make_active':
            await _convertToActive(portfolio.id);
            break;
          case 'edit':
            await _editPortfolio(portfolio.id);
            break;
          case 'view_details':
            await _viewPortfolioDetails(portfolio.id);
            break;
          case 'delete':
            await _deletePortfolio(portfolio.id);
            break;
        }
      },
    );
  }

  Future<void> _convertToDraft(String portfolioId) async {
    final success = await _portfolioController.convertActiveToDraft(portfolioId);
    if (success && mounted) {
      SnackBarUtils.showSuccess(context, 'Portfolio converted to draft');
    } else if (mounted) {
      SnackBarUtils.showError(context, _portfolioController.errorMessage.value);
    }
  }

  Future<void> _convertToActive(String portfolioId) async {
    final success = await _portfolioController.convertDraftToActive(portfolioId);
    if (success && mounted) {
      SnackBarUtils.showSuccess(context, 'Portfolio converted to active');
    } else if (mounted) {
      SnackBarUtils.showError(context, _portfolioController.errorMessage.value);
    }
  }

  Future<void> _editPortfolio(String portfolioId) async {
    final portfolio = await _portfolioController.getPortfolio(portfolioId);
    if (portfolio != null && mounted) {
      // Show edit form in a dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 800),
            child: SingleChildScrollView(
              child: PortfolioBuilderForm(
                initialPortfolio: portfolio,
                onCancel: () {
                  Navigator.pop(context);
                },
                onSaveDraft: () {
                  Navigator.pop(context);
                  // Refresh the appropriate list
                  if (_selectedTabIndex == 0) {
                    _portfolioController.fetchActivePortfolios();
                  } else {
                    _portfolioController.fetchDraftPortfolios();
                  }
                },
                onSavePortfolio: () {
                  Navigator.pop(context);
                  // Refresh the appropriate list
                  if (_selectedTabIndex == 0) {
                    _portfolioController.fetchActivePortfolios();
                  } else {
                    _portfolioController.fetchDraftPortfolios();
                  }
                },
              ),
            ),
          ),
        ),
      );
    } else if (mounted) {
      SnackBarUtils.showError(context, _portfolioController.errorMessage.value);
    }
  }

  Future<void> _viewPortfolioDetails(String portfolioId) async {
    // TODO: Implement view details - show modal or navigate
    final portfolio = await _portfolioController.getPortfolio(portfolioId);
    if (portfolio != null && mounted) {
      // Show details modal
      showDialog(
        context: context,
        builder: (context) => _PortfolioDetailsDialog(portfolio: portfolio),
      );
    }
  }

  Future<void> _deletePortfolio(String portfolioId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFF8F9FA),
        title: Text(
          'Delete Portfolio',
          style: DashboardTextStyles.headerTitle.copyWith(fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to delete this portfolio?',
          style: DashboardTextStyles.tickerSymbol.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: DashboardTextStyles.tickerSymbol),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: DashboardTextStyles.tickerSymbol.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _portfolioController.deletePortfolio(portfolioId);
      if (success && mounted) {
        SnackBarUtils.showSuccess(context, 'Portfolio deleted');
        // Refresh list
        if (_selectedTabIndex == 0) {
          await _portfolioController.fetchActivePortfolios();
        } else {
          await _portfolioController.fetchDraftPortfolios();
        }
      } else if (mounted) {
        SnackBarUtils.showError(context, _portfolioController.errorMessage.value);
      }
    }
  }
}

// Portfolio Details Dialog
class _PortfolioDetailsDialog extends StatelessWidget {
  final Portfolio portfolio;

  const _PortfolioDetailsDialog({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF151718) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  portfolio.portfolioName,
                  style: DashboardTextStyles.titleSmall.copyWith(
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Client Name', portfolio.clientName, isDark),
                    if (portfolio.clientAge != null)
                      _buildDetailRow('Client Age', portfolio.clientAge.toString(), isDark),
                    if (portfolio.riskProfile != null)
                      _buildDetailRow('Risk Profile', portfolio.riskProfile!, isDark),
                    if (portfolio.strategyType != null)
                      _buildDetailRow('Strategy Type', portfolio.strategyType!, isDark),
                    if (portfolio.benchmark != null)
                      _buildDetailRow('Benchmark', portfolio.benchmark!, isDark),
                    if (portfolio.objective != null)
                      _buildDetailRow('Objective', portfolio.objective!, isDark),
                    _buildDetailRow('Initial Capital', '\$${NumberFormat('#,##,###', 'en_US').format(portfolio.initialCapital)}', isDark),
                    if (portfolio.investmentHorizon != null)
                      _buildDetailRow('Investment Horizon', portfolio.investmentHorizon!, isDark),
                    if (portfolio.expectedRateOfReturn != null)
                      _buildDetailRow('Expected Rate of Return', '${portfolio.expectedRateOfReturn!.toStringAsFixed(1)}%', isDark),
                    _buildDetailRow('Allocated Amount', '\$${NumberFormat('#,##,###', 'en_US').format(portfolio.allocatedAmount)}', isDark),
                    _buildDetailRow('Allocation %', '${portfolio.allocationPercent.toStringAsFixed(1)}%', isDark),
                    _buildDetailRow('Estimated Returns', '\$${NumberFormat('#,##,###', 'en_US').format(portfolio.estimatedReturns)}', isDark),
                    _buildDetailRow('Holdings Count', portfolio.holdingsCount.toString(), isDark),
                    if (portfolio.commentary != null && portfolio.commentary!.isNotEmpty)
                      _buildDetailRow('Commentary', portfolio.commentary!, isDark),
                    const SizedBox(height: 16),
                    Text(
                      'Holdings',
                      style: DashboardTextStyles.titleSmall.copyWith(
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...portfolio.holdings.map((holding) => _buildHoldingRow(holding, isDark)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: DashboardTextStyles.stockName.copyWith(
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: DashboardTextStyles.dataCell.copyWith(
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingRow(PortfolioHolding holding, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1F25) : const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(child: Text(holding.ticker, style: DashboardTextStyles.dataCell)),
          Expanded(child: Text(holding.company ?? '--', style: DashboardTextStyles.dataCell)),
          Expanded(child: Text('Qty: ${holding.quantity}', style: DashboardTextStyles.dataCell)),
          Expanded(child: Text('\$${holding.currentPrice.toStringAsFixed(2)}', style: DashboardTextStyles.dataCell)),
          Expanded(child: Text('\$${holding.targetPrice.toStringAsFixed(2)}', style: DashboardTextStyles.dataCell)),
          Expanded(child: Text('${holding.allocationPercent.toStringAsFixed(1)}%', style: DashboardTextStyles.dataCell)),
        ],
      ),
    );
  }
}

// Reusable Pill Button Components (matching trading_ideas_screen.dart style)
class _PrimaryPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isDarkMode;

  const _PrimaryPillButton({
    required this.label,
    this.icon,
    required this.isDarkMode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final primaryColor =
        isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6);
    final disabledBg =
        isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? primaryColor : disabledBg,
          borderRadius: BorderRadius.circular(90),
          border: Border.all(
            color: enabled ? primaryColor : disabledBg,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: enabled ? Colors.white : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label.toUpperCase(),
              style: DashboardTextStyles.columnHeader.copyWith(
                color: enabled ? Colors.white : const Color(0xFF9CA3AF),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

