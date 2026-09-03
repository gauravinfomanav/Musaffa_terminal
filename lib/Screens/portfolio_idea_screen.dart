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

    return Container(
      width: 860,
      height: dialogHeight,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: HomeUi.cardBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusCard),
        border: Border.all(color: HomeUi.borderLight(isDark)),
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
                    title: assignment.modelPortfolioName,
                    subtitleText:
                        '${assignment.customerName} · ${assignment.assignmentCode ?? assignment.id}',
                    icon: Icons.pie_chart_outline_rounded,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: HomeUi.muted(isDark)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: HomeUi.borderLight(isDark)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _metaChip(isDark, 'Amount', currency.format(assignment.investmentAmount)),
                    _metaChip(isDark, 'Status', assignment.status),
                    _metaChip(
                      isDark,
                      'Allocation',
                      '${assignment.totalAllocationPercent.toStringAsFixed(1)}%',
                    ),
                    _metaChip(isDark, 'Holdings', '${assignment.holdingsCount}'),
                  ],
                ),
                const SizedBox(height: 20),
                Text('How capital is invested', style: HomeUi.sectionTitle(isDark)),
                const SizedBox(height: 12),
                ...assignment.holdings.map((h) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: HomeUi.elevatedBg(isDark),
                        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                        border: Border.all(color: HomeUi.borderLight(isDark)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              h.ticker,
                              style: HomeUi.control(isDark).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              h.company ?? '—',
                              style: HomeUi.subtitle(isDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              '${h.allocationPercent.toStringAsFixed(1)}%',
                              textAlign: TextAlign.right,
                              style: HomeUi.control(isDark),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              currency.format(h.allocationAmount),
                              textAlign: TextAlign.right,
                              style: HomeUi.control(isDark).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(bool isDark, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: HomeUi.elevatedBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: HomeUi.subtitle(isDark).copyWith(fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: HomeUi.control(isDark).copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
