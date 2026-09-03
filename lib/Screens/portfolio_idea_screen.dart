import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Components/global_fab_overlay.dart';
import 'package:musaffa_terminal/Components/sliding_pill_tabs.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/Controllers/portfolio_assignment_controller.dart';
import 'package:musaffa_terminal/models/portfolio_assignment_model.dart';
import 'package:musaffa_terminal/portfolio/screens/assign_portfolio_screen.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';

class PortfolioIdeaScreen extends StatefulWidget {
  const PortfolioIdeaScreen({super.key});

  @override
  State<PortfolioIdeaScreen> createState() => _PortfolioIdeaScreenState();
}

class _PortfolioIdeaScreenState extends State<PortfolioIdeaScreen>
    with SingleTickerProviderStateMixin {
  late final WatchlistController _watchlistController;
  final GlobalWatchlistService _watchlistService =
      Get.find<GlobalWatchlistService>();
  late TabController _tabController;
  int _selectedTabIndex = 0;
  int _previousTabIndex = 0;

  late PortfolioAssignmentController _assignmentController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.portfolio);
    }
    _watchlistController = WatchlistController.ensureRegistered();
    _assignmentController = Get.put(PortfolioAssignmentController());
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final newIndex = _tabController.index;
        if (newIndex != _previousTabIndex) {
          setState(() {
            _selectedTabIndex = newIndex;
            _previousTabIndex = newIndex;
          });
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _assignmentController.fetchAssignments(status: 'active');
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

  void _refreshAssignmentList() {
    if (_selectedTabIndex == 0) {
      _assignmentController.fetchAssignments(status: 'active');
    } else {
      _assignmentController.fetchAssignments(status: 'draft');
    }
  }

  Future<void> _openAssignPortfolioModal() async {
    final result = await Get.to(() => const AssignPortfolioScreen());
    if (result == true && mounted) {
      _refreshAssignmentList();
    }
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
              Text('Assign Portfolio', style: HomeUi.heading(isDark)),
              const SizedBox(height: 4),
              Text(
                'Assign an existing model portfolio to customers.',
                style: HomeUi.subtitle(isDark),
              ),
            ],
          ),
        ),
        HomeUi.primaryAction(
          label: 'Assign Portfolio',
          icon: Icons.person_add_rounded,
          onTap: _openAssignPortfolioModal,
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
    final tabs = ['Active Assignments', 'Pending Drafts'];

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
          _assignmentController.fetchAssignments(status: 'active');
        } else {
          _assignmentController.fetchAssignments(status: 'draft');
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
    final title = isActiveTab ? 'Active Assignments' : 'Pending Assignments';
    final emptyMessage = isActiveTab
        ? 'No active customer assignments yet.'
        : 'No pending assignment drafts.';

    return Obx(() {
      final isLoading = _assignmentController.isLoading.value;
      final assignments = isActiveTab
          ? _assignmentController.activeAssignments.toList()
          : _assignmentController.draftAssignments.toList();
      final countLabel = assignments.length == 1
          ? (isActiveTab
              ? '1 assignment in your book'
              : '1 draft in progress')
          : (isActiveTab
              ? '${assignments.length} assignments in your book'
              : '${assignments.length} drafts in progress');

      Widget content;
      if (isLoading && assignments.isEmpty) {
        content = Padding(
          padding: const EdgeInsets.all(16),
          child: ShimmerWidgets.perShareTableShimmer(
            baseColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
            highlightColor:
                isDark ? const Color(0xFF404040) : const Color(0xFFF3F4F6),
          ),
        );
      } else if (assignments.isEmpty) {
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
        content = _buildAssignmentTable(
          assignments,
          isDark,
          title: title,
          subtitle: countLabel,
        );
      }

      return Container(
        width: double.infinity,
        padding: assignments.isEmpty && !isLoading
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(0, 16, 0, 16),
        decoration: HomeUi.cardDecoration(isDark),
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    });
  }

  Widget _buildAssignmentTable(
    List<PortfolioAssignmentSummary> assignments,
    bool isDark, {
    required String title,
    required String subtitle,
  }) {
    final rows = assignments.map((assignment) {
      return SimpleRowModel(
        symbol: '',
        name: assignment.modelPortfolioName,
        logo: null,
        fields: {
          'client': assignment.customerName.trim().isEmpty
              ? '--'
              : assignment.customerName,
          'capital': _formatCurrency(assignment.investmentAmount),
          'holdings': assignment.holdingsCount.toString(),
          'allocation':
              '${assignment.allocationPercent.toStringAsFixed(1)}%',
          'code': assignment.assignmentCode ?? '--',
          'updated': assignment.lastUpdated != null
              ? _formatDate(assignment.lastUpdated!)
              : '--',
          'actions': _buildActionsMenu(assignment, isDark),
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
        const baseCode = 130.0;
        const baseUpdated = 140.0;
        const baseActions = 80.0;
        const totalBaseWidth = baseClient +
            baseCapital +
            baseHoldings +
            baseAllocation +
            baseCode +
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
            label: 'AMOUNT',
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
            label: 'CODE',
            fieldName: 'code',
            width: baseCode * widthScale,
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
          tickerHeaderLabel: 'MODEL',
          tableId: 'portfolio_assignments_table',
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##,###.##', 'en_US');
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

  Widget _buildActionsMenu(
    PortfolioAssignmentSummary assignment,
    bool isDark,
  ) {
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

        if (assignment.status != 'active') {
          items.add(
            PopupMenuItem(
              value: 'make_active',
              height: 44,
              child: HomeUi.actionMenuItem(
                dark: isDark,
                icon: Icons.check_circle_rounded,
                label: 'Activate',
              ),
            ),
          );
        }

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
              label: 'Archive',
              destructive: true,
            ),
          ),
        );

        return items;
      },
      onSelected: (value) async {
        switch (value) {
          case 'make_active':
            await _activateAssignment(assignment.id);
            break;
          case 'view_details':
            await _viewAssignmentDetails(assignment.id);
            break;
          case 'delete':
            await _archiveAssignment(assignment.id);
            break;
        }
      },
    );
  }

  Future<void> _activateAssignment(String id) async {
    final success = await _assignmentController.activateAssignment(id);
    if (success && mounted) {
      SnackBarUtils.showSuccess(context, 'Assignment activated');
      _refreshAssignmentList();
    } else if (mounted) {
      SnackBarUtils.showError(context, _assignmentController.errorMessage.value);
    }
  }

  Future<void> _viewAssignmentDetails(String id) async {
    final assignment = await _assignmentController.getAssignment(id);
    if (assignment != null && mounted) {
      await _showPremiumPortfolioDialog(
        child: _AssignmentDetailsDialog(assignment: assignment),
      );
    } else if (mounted) {
      SnackBarUtils.showError(context, _assignmentController.errorMessage.value);
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

  Future<void> _archiveAssignment(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: HomeUi.cardBg(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          ),
          title: Text('Archive Assignment', style: HomeUi.sectionTitle(isDark)),
          content: Text(
            'Archive this customer assignment?',
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
                    label: 'Archive',
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
      final success = await _assignmentController.deleteAssignment(id);
      if (success && mounted) {
        SnackBarUtils.showSuccess(context, 'Assignment archived');
        _refreshAssignmentList();
      } else if (mounted) {
        SnackBarUtils.showError(
          context,
          _assignmentController.errorMessage.value,
        );
      }
    }
  }
}

class _AssignmentDetailsDialog extends StatelessWidget {
  const _AssignmentDetailsDialog({required this.assignment});

  final PortfolioAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogHeight =
        (MediaQuery.of(context).size.height * 0.82).clamp(480.0, 680.0);
    final currency = NumberFormat.currency(symbol: '\$');
    final statusLabel = assignment.status.trim().isEmpty
        ? '—'
        : assignment.status[0].toUpperCase() +
            assignment.status.substring(1).toLowerCase();
    final isActive = assignment.status.toLowerCase() == 'active';

    return Container(
      width: 860,
      height: dialogHeight,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeUi.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Material(
        color: HomeUi.cardBg(isDark),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          side: BorderSide(color: HomeUi.borderLight(isDark)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1C1F2A),
                          HomeUi.cardBg(isDark),
                        ]
                      : [
                          const Color(0xFFFFF8F4),
                          const Color(0xFFFCFCFD),
                          Colors.white,
                        ],
                ),
                border: Border(
                  bottom: BorderSide(color: HomeUi.borderLight(isDark)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: HomeUi.tableToolbarHeader(
                      isDark,
                      title: assignment.modelPortfolioName,
                      subtitleText:
                          '${assignment.customerName} · ${assignment.assignmentCode ?? assignment.id}',
                      icon: Icons.account_balance_wallet_rounded,
                      titleFontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isActive)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: HomeUi.positive(isDark)
                            .withValues(alpha: isDark ? 0.16 : 0.1),
                        borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                        border: Border.all(
                          color: HomeUi.positive(isDark).withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 13,
                            color: HomeUi.positive(isDark),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel,
                            style: HomeUi.control(isDark).copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: HomeUi.positive(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: HomeUi.muted(isDark)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 640;
                      final tiles = [
                        _SummaryMetricTile(
                          isDark: isDark,
                          label: 'Amount',
                          value: currency.format(assignment.investmentAmount),
                          accent: HomeUi.accent(isDark),
                          icon: Icons.payments_outlined,
                        ),
                        _SummaryMetricTile(
                          isDark: isDark,
                          label: 'Status',
                          value: statusLabel,
                          accent: isActive
                              ? HomeUi.positive(isDark)
                              : HomeUi.muted(isDark),
                          icon: Icons.flag_outlined,
                          valueColor: isActive
                              ? HomeUi.positive(isDark)
                              : null,
                        ),
                        _SummaryMetricTile(
                          isDark: isDark,
                          label: 'Allocation',
                          value:
                              '${assignment.totalAllocationPercent.toStringAsFixed(1)}%',
                          accent: const Color(0xFFD97706),
                          icon: Icons.pie_chart_outline_rounded,
                        ),
                        _SummaryMetricTile(
                          isDark: isDark,
                          label: 'Holdings',
                          value: '${assignment.holdingsCount}',
                          accent: HomeUi.accent(isDark),
                          icon: Icons.layers_outlined,
                        ),
                      ];

                      if (wide) {
                        return Row(
                          children: [
                            for (var i = 0; i < tiles.length; i++) ...[
                              if (i > 0) const SizedBox(width: 10),
                              Expanded(child: tiles[i]),
                            ],
                          ],
                        );
                      }

                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: tiles
                            .map(
                              (t) => SizedBox(
                                width: (constraints.maxWidth - 10) / 2,
                                child: t,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  HomeUi.tableToolbarHeader(
                    isDark,
                    title: 'How capital is invested',
                    subtitleText:
                        '${assignment.holdings.length} positions · weighted allocation',
                    icon: Icons.account_tree_outlined,
                    titleFontSize: 15,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                      border: Border.all(color: HomeUi.borderLight(isDark)),
                      color: isDark
                          ? const Color(0xFF151822)
                          : const Color(0xFFFCFCFD),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: HomeUi.borderLight(isDark),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'TICKER',
                                  style: _colHeader(isDark),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'COMPANY',
                                  style: _colHeader(isDark),
                                ),
                              ),
                              SizedBox(
                                width: 72,
                                child: Text(
                                  'WEIGHT',
                                  textAlign: TextAlign.right,
                                  style: _colHeader(isDark),
                                ),
                              ),
                              SizedBox(
                                width: 108,
                                child: Text(
                                  'AMOUNT',
                                  textAlign: TextAlign.right,
                                  style: _colHeader(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (assignment.holdings.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(28),
                            child: Text(
                              'No holdings in this assignment',
                              style: HomeUi.subtitle(isDark),
                            ),
                          )
                        else
                          ...assignment.holdings.asMap().entries.map((entry) {
                            final index = entry.key;
                            final h = entry.value;
                            final zebra = index.isOdd;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: zebra
                                    ? (isDark
                                        ? Colors.white.withValues(alpha: 0.02)
                                        : const Color(0xFFF8F9FB))
                                    : Colors.transparent,
                                border: index == assignment.holdings.length - 1
                                    ? null
                                    : Border(
                                        bottom: BorderSide(
                                          color: HomeUi.borderLight(isDark)
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      h.ticker,
                                      style: HomeUi.control(isDark).copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      h.company ?? '—',
                                      style: HomeUi.subtitle(isDark).copyWith(
                                        fontSize: 12.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 72,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: HomeUi.accent(isDark)
                                              .withValues(
                                            alpha: isDark ? 0.16 : 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            HomeUi.radiusPill,
                                          ),
                                        ),
                                        child: Text(
                                          '${h.allocationPercent.toStringAsFixed(1)}%',
                                          style: HomeUi.control(isDark).copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11.5,
                                            color: HomeUi.accent(isDark),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 108,
                                    child: Text(
                                      currency.format(h.allocationAmount),
                                      textAlign: TextAlign.right,
                                      style: HomeUi.control(isDark).copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
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

  TextStyle _colHeader(bool isDark) => HomeUi.subtitle(isDark).copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
      );
}

class _SummaryMetricTile extends StatelessWidget {
  const _SummaryMetricTile({
    required this.isDark,
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
    this.valueColor,
  });

  final bool isDark;
  final String label;
  final String value;
  final Color accent;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151822) : Colors.white,
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: HomeUi.subtitle(isDark).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HomeUi.control(isDark).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: valueColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
