import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Components/global_fab_overlay.dart';
import 'package:musaffa_terminal/Components/sliding_pill_tabs.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/Controllers/portfolio_controller.dart';
import 'package:musaffa_terminal/models/portfolio_model.dart';
import 'package:musaffa_terminal/Screens/portfolio_builder_form.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';

class PortfolioIdeaScreen extends StatefulWidget {
  const PortfolioIdeaScreen({super.key});

  @override
  State<PortfolioIdeaScreen> createState() => _PortfolioIdeaScreenState();
}

class _PortfolioIdeaScreenState extends State<PortfolioIdeaScreen> with SingleTickerProviderStateMixin {
  late final WatchlistController _watchlistController;
  final GlobalWatchlistService _watchlistService = Get.find<GlobalWatchlistService>();
  late TabController _tabController;
  int _selectedTabIndex = 0;
  int _previousTabIndex = 0;

  late PortfolioController _portfolioController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.portfolio);
    }
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

  void _refreshPortfolioList() {
    if (_selectedTabIndex == 0) {
      _portfolioController.fetchActivePortfolios();
    } else {
      _portfolioController.fetchDraftPortfolios();
    }
  }

  Future<void> _openNewPortfolioModal() async {
    await _showPremiumPortfolioDialog(
      barrierDismissible: false,
      child: _PortfolioBuilderModal(
        title: 'New Portfolio',
        subtitle: 'Define client mandate, holdings, and allocation targets.',
        child: PortfolioBuilderForm(
          embeddedInModal: true,
          onCancel: () => Navigator.pop(context),
          onSaveDraft: () {
            Navigator.pop(context);
            _refreshPortfolioList();
          },
          onSavePortfolio: () {
            Navigator.pop(context);
            _refreshPortfolioList();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FeatureGuard(
      featureKey: FeatureKeys.portfolios,
      child: Scaffold(
      backgroundColor: HomeUi.pageBg(isDark),
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
    ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Portfolios', style: HomeUi.heading(isDark)),
              const SizedBox(height: 4),
              Text(
                'Client books, allocations, and estimated returns.',
                style: HomeUi.subtitle(isDark),
              ),
            ],
          ),
        ),
        HomeUi.primaryAction(
          label: 'New Portfolio',
          icon: Icons.add_rounded,
          onTap: _openNewPortfolioModal,
        ),
      ],
    );
  }

  Widget _buildPlaceholderContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTabs(context),
        const SizedBox(height: 16),
        _buildPortfoliosList(context),
      ],
    );
  }

  Widget _buildTabs(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = ['Active Portfolios', 'Drafts'];

    return SlidingPillTabs(
      itemCount: tabs.length,
      selectedIndex: _selectedTabIndex,
      controller: _tabController,
      isDarkMode: isDark,
      onSelect: (index) {
        if (index == _selectedTabIndex) return;
        _tabController.animateTo(index);
        setState(() {
          _selectedTabIndex = index;
          _previousTabIndex = index;
        });
        if (index == 0) {
          _portfolioController.fetchActivePortfolios();
        } else {
          _portfolioController.fetchDraftPortfolios();
        }
      },
      itemBuilder: (context, index, isSelected) {
        return Text(
          tabs[index],
          style: HomeUi.control(isDark, active: isSelected).copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : HomeUi.muted(isDark),
          ),
        );
      },
    );
  }

  Widget _buildPortfoliosList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActiveTab = _selectedTabIndex == 0;
    final title = isActiveTab ? 'Active Portfolios' : 'Draft Portfolios';
    final emptyMessage = isActiveTab
        ? 'No active portfolios yet.'
        : 'No draft portfolios yet.';

    return Obx(() {
      final isLoading = _portfolioController.isLoading.value;
      final portfolios = isActiveTab
          ? _portfolioController.activePortfolios
          : _portfolioController.draftPortfolios;
      final countLabel = portfolios.length == 1
          ? (isActiveTab
              ? '1 portfolio in your book'
              : '1 draft in progress')
          : (isActiveTab
              ? '${portfolios.length} portfolios in your book'
              : '${portfolios.length} drafts in progress');

      Widget content;
      if (isLoading && portfolios.isEmpty) {
        content = Padding(
          padding: const EdgeInsets.all(16),
          child: ShimmerWidgets.perShareTableShimmer(
            baseColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
            highlightColor:
                isDark ? const Color(0xFF404040) : const Color(0xFFF3F4F6),
          ),
        );
      } else if (portfolios.isEmpty) {
        content = Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeUi.tableToolbarHeader(
                isDark,
                title: title,
                subtitleText: emptyMessage,
                icon: Icons.pie_chart_outline_rounded,
              ),
              const SizedBox(height: 28),
              Center(
                child: Text(emptyMessage, style: HomeUi.subtitle(isDark)),
              ),
            ],
          ),
        );
      } else {
        content = _buildPortfolioTable(
          portfolios,
          isDark,
          title: title,
          subtitle: countLabel,
        );
      }

      return Container(
        width: double.infinity,
        padding: portfolios.isEmpty && !isLoading
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(0, 16, 0, 16),
        decoration: HomeUi.cardDecoration(isDark),
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    });
  }

  Widget _buildPortfolioTable(
    List<PortfolioSummary> portfolios,
    bool isDark, {
    required String title,
    required String subtitle,
  }) {
    final rows = portfolios.map((portfolio) {
      return SimpleRowModel(
        symbol: '',
        name: portfolio.portfolioName,
        logo: null,
        fields: {
          'client':
              portfolio.clientName.trim().isEmpty ? '--' : portfolio.clientName,
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
        const fixedColumnWidth = 220.0;
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

        final availableForDynamicColumns =
            (constraints.maxWidth - fixedColumnWidth - 32)
                .clamp(0.0, double.infinity);
        final widthScale = availableForDynamicColumns > totalBaseWidth
            ? (availableForDynamicColumns / totalBaseWidth)
            : 1.0;

        final columns = [
          SimpleColumn(
            label: 'CLIENT',
            fieldName: 'client',
            width: baseClient * widthScale,
          ),
          SimpleColumn(
            label: 'CAPITAL',
            fieldName: 'capital',
            width: baseCapital * widthScale,
            isNumeric: true,
          ),
          SimpleColumn(
            label: 'HOLDINGS',
            fieldName: 'holdings',
            width: baseHoldings * widthScale,
            isNumeric: true,
          ),
          SimpleColumn(
            label: 'ALLOCATION %',
            fieldName: 'allocation',
            width: baseAllocation * widthScale,
            isNumeric: true,
          ),
          SimpleColumn(
            label: 'EST. RETURNS',
            fieldName: 'returns',
            width: baseReturns * widthScale,
            isNumeric: true,
          ),
          SimpleColumn(
            label: 'LAST UPDATED',
            fieldName: 'updated',
            width: baseUpdated * widthScale,
          ),
          SimpleColumn(
            label: 'ACTIONS',
            fieldName: 'actions',
            width: baseActions * widthScale,
          ),
        ];

        return DynamicTable(
          columns: columns,
          rows: rows,
          title: title,
          subtitle: subtitle,
          toolbarLeadingIcon: Icons.pie_chart_outline_rounded,
          showFixedColumn: true,
          considerPadding: false,
          showOuterShadow: false,
          columnSpacing: 40,
          horizontalMargin: 16,
          fixedColumnWidth: fixedColumnWidth,
          headerHeight: 44,
          rowHeight: 56,
          enableLivePrices: false,
          zebraStripes: true,
          enableColumnCustomization: true,
          showColumnActionMenu: true,
          showColumnResizeHandle: true,
          tickerHeaderLabel: 'PORTFOLIO',
          tableId: 'portfolio_ideas_table',
        );
      },
    );
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
      icon: Icon(Icons.more_vert_rounded, size: 18, color: HomeUi.muted(isDark)),
      color: HomeUi.cardBg(isDark),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        side: BorderSide(color: HomeUi.borderLight(isDark)),
      ),
      offset: const Offset(0, 8),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        if (portfolio.status == 'active') {
          items.add(
            PopupMenuItem(
              value: 'make_draft',
              height: 44,
              child: HomeUi.actionMenuItem(
                dark: isDark,
                icon: Icons.drafts_rounded,
                label: 'Make as Draft',
              ),
            ),
          );
        } else {
          items.add(
            PopupMenuItem(
              value: 'make_active',
              height: 44,
              child: HomeUi.actionMenuItem(
                dark: isDark,
                icon: Icons.check_circle_rounded,
                label: 'Make as Active',
              ),
            ),
          );
        }

        items.add(
          PopupMenuItem(
            value: 'edit',
            height: 44,
            child: HomeUi.actionMenuItem(
              dark: isDark,
              icon: Icons.edit_rounded,
              label: 'Edit',
            ),
          ),
        );

        items.add(
          PopupMenuItem(
            value: 'view_details',
            height: 44,
            child: HomeUi.actionMenuItem(
              dark: isDark,
              icon: Icons.visibility_rounded,
              label: 'View Details',
            ),
          ),
        );

        items.add(const PopupMenuDivider());

        items.add(
          PopupMenuItem(
            value: 'delete',
            height: 44,
            child: HomeUi.actionMenuItem(
              dark: isDark,
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              destructive: true,
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
      await _showPremiumPortfolioDialog(
        barrierDismissible: false,
        child: _PortfolioBuilderModal(
          title: 'Edit Portfolio',
          subtitle: 'Update client mandate, holdings, and allocation targets.',
          child: PortfolioBuilderForm(
            embeddedInModal: true,
            initialPortfolio: portfolio,
            onCancel: () {
              Navigator.pop(context);
            },
            onSaveDraft: () {
              Navigator.pop(context);
              _refreshPortfolioList();
            },
            onSavePortfolio: () {
              Navigator.pop(context);
              _refreshPortfolioList();
            },
          ),
        ),
      );
    } else if (mounted) {
      SnackBarUtils.showError(context, _portfolioController.errorMessage.value);
    }
  }

  Future<void> _viewPortfolioDetails(String portfolioId) async {
    final portfolio = await _portfolioController.getPortfolio(portfolioId);
    if (portfolio != null && mounted) {
      await _showPremiumPortfolioDialog(
        child: _PortfolioDetailsDialog(portfolio: portfolio),
      );
    }
  }

  Future<T?> _showPremiumPortfolioDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Portfolio',
      barrierColor: Colors.black.withValues(alpha: 0.46),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 800),
              child: child,
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.018),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Future<void> _deletePortfolio(String portfolioId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: HomeUi.cardBg(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          ),
          title: Text('Delete Portfolio', style: HomeUi.sectionTitle(isDark)),
          content: Text(
            'Are you sure you want to delete this portfolio?',
            style: HomeUi.subtitle(isDark),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: HomeUi.ghostAction(
                    label: 'Cancel',
                    dark: isDark,
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HomeUi.primaryAction(
                    label: 'Delete',
                    onTap: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        );
      },
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

class _PortfolioBuilderModal extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _PortfolioBuilderModal({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final modalWidth = math.min(size.width * 0.92, 1200.0);
    final modalHeight = (size.height * 0.9).clamp(560.0, 860.0);

    return Container(
      width: modalWidth,
      height: modalHeight,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: HomeUi.cardBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusCard),
        border: Border.all(color: HomeUi.borderLight(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.10),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: HomeUi.tableToolbarHeader(
                    isDark,
                    title: title,
                    subtitleText: subtitle,
                    icon: Icons.pie_chart_outline_rounded,
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: HomeUi.controlHeight,
                      height: HomeUi.controlHeight,
                      decoration: BoxDecoration(
                        color: HomeUi.elevatedBg(isDark),
                        shape: BoxShape.circle,
                        border: Border.all(color: HomeUi.borderLight(isDark)),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: HomeUi.muted(isDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: HomeUi.borderLight(isDark)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// Portfolio Details Dialog
class _PortfolioDetailsDialog extends StatelessWidget {
  final Portfolio portfolio;

  const _PortfolioDetailsDialog({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogHeight =
        (MediaQuery.of(context).size.height * 0.82).clamp(480.0, 680.0);

    return Container(
      width: 860,
      height: dialogHeight,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: HomeUi.cardBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusCard),
        border: Border.all(color: HomeUi.borderLight(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.10),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: HomeUi.tableToolbarHeader(
                    isDark,
                    title: portfolio.portfolioName,
                    subtitleText: portfolio.clientName,
                    icon: Icons.pie_chart_outline_rounded,
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: HomeUi.controlHeight,
                      height: HomeUi.controlHeight,
                      decoration: BoxDecoration(
                        color: HomeUi.elevatedBg(isDark),
                        shape: BoxShape.circle,
                        border: Border.all(color: HomeUi.borderLight(isDark)),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: HomeUi.muted(isDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: HomeUi.borderLight(isDark)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryStrip(isDark),
                  const SizedBox(height: 16),
                  _buildDetailsPanels(isDark),
                  if (portfolio.commentary != null &&
                      portfolio.commentary!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    HomeUi.detailCallout(
                      dark: isDark,
                      label: 'Commentary',
                      body: portfolio.commentary!,
                    ),
                  ],
                  const SizedBox(height: 20),
                  HomeUi.tableToolbarHeader(
                    isDark,
                    title: 'Holdings',
                    subtitleText:
                        '${portfolio.holdingsCount} position${portfolio.holdingsCount == 1 ? '' : 's'}',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildHoldingsHeader(isDark),
                  const SizedBox(height: 8),
                  ...portfolio.holdings
                      .map((holding) => _buildHoldingRow(holding, isDark)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStrip(bool isDark) {
    final currency = NumberFormat('#,##,###', 'en_US');
    final allocationColor = portfolio.allocationPercent >= 99.9
        ? const Color(0xFF10B981)
        : portfolio.allocationPercent > 100
            ? HomeUi.negative(isDark)
            : HomeUi.accent(isDark);

    return Row(
      children: [
        Expanded(
          child: HomeUi.detailSummaryMetric(
            dark: isDark,
            label: 'Initial Capital',
            value: '\$${currency.format(portfolio.initialCapital)}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HomeUi.detailSummaryMetric(
            dark: isDark,
            label: 'Allocated',
            value: '\$${currency.format(portfolio.allocatedAmount)}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HomeUi.detailSummaryMetric(
            dark: isDark,
            label: 'Est. Returns',
            value: '\$${currency.format(portfolio.estimatedReturns)}',
            valueColor: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HomeUi.detailSummaryMetric(
            dark: isDark,
            label: 'Allocation',
            value: '${portfolio.allocationPercent.toStringAsFixed(1)}%',
            valueColor: allocationColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsPanels(bool isDark) {
    final clientRows = <(String, String)>[
      ('Client Name', portfolio.clientName),
      if (portfolio.clientAge != null)
        ('Client Age', portfolio.clientAge.toString()),
      if (portfolio.riskProfile != null)
        ('Risk Profile', portfolio.riskProfile!),
      if (portfolio.strategyType != null)
        ('Strategy Type', portfolio.strategyType!),
      if (portfolio.benchmark != null) ('Benchmark', portfolio.benchmark!),
      if (portfolio.objective != null) ('Objective', portfolio.objective!),
    ];

    final investmentRows = <(String, String)>[
      if (portfolio.investmentHorizon != null)
        ('Investment Horizon', portfolio.investmentHorizon!),
      if (portfolio.expectedRateOfReturn != null)
        (
          'Expected Return',
          '${portfolio.expectedRateOfReturn!.toStringAsFixed(1)}%',
        ),
      ('Holdings Count', portfolio.holdingsCount.toString()),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: HomeUi.detailPanel(
            dark: isDark,
            title: 'Client & Mandate',
            rows: clientRows,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HomeUi.detailPanel(
            dark: isDark,
            title: 'Investment Profile',
            rows: investmentRows,
          ),
        ),
      ],
    );
  }

  Widget _buildHoldingsHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: HomeUi.tableHeaderBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Row(
        children: [
          Expanded(child: Text('TICKER', style: HomeUi.tableHeader(isDark))),
          Expanded(child: Text('COMPANY', style: HomeUi.tableHeader(isDark))),
          Expanded(
            child: Text(
              'QTY',
              style: HomeUi.tableHeader(isDark),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              'PRICE',
              style: HomeUi.tableHeader(isDark),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              'TARGET',
              style: HomeUi.tableHeader(isDark),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              'ALLOC %',
              style: HomeUi.tableHeader(isDark),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingRow(PortfolioHolding holding, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: HomeUi.elevatedBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              holding.ticker,
              style: HomeUi.tableCellEmphasis(isDark),
            ),
          ),
          Expanded(
            child: Text(
              holding.company ?? '--',
              style: HomeUi.tableCellSecondary(isDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              holding.quantity.toString(),
              style: HomeUi.tableCell(isDark),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              '\$${holding.currentPrice.toStringAsFixed(2)}',
              style: HomeUi.tableCellEmphasis(isDark),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              '\$${holding.targetPrice.toStringAsFixed(2)}',
              style: HomeUi.tableCellEmphasis(isDark),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              '${holding.allocationPercent.toStringAsFixed(1)}%',
              style: HomeUi.tableNumeric(isDark),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

