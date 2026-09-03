import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Components/global_fab_overlay.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Components/sliding_pill_tabs.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/models/portfolio_model.dart';
import 'package:musaffa_terminal/portfolio/controllers/model_portfolio_controller.dart';
import 'package:musaffa_terminal/portfolio/screens/model_portfolio_builder_screen.dart';
import 'package:musaffa_terminal/portfolio/services/portfolio_builder_session.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';

class ModelPortfoliosScreen extends StatefulWidget {
  const ModelPortfoliosScreen({super.key});

  @override
  State<ModelPortfoliosScreen> createState() => _ModelPortfoliosScreenState();
}

class _ModelPortfoliosScreenState extends State<ModelPortfoliosScreen>
    with SingleTickerProviderStateMixin {
  final _watchlistService = Get.find<GlobalWatchlistService>();
  final _modelController = Get.put(ModelPortfolioController());
  late TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.modelPortfolio);
    }
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _tabIndex = _tabController.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _modelController.fetchModels();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreate() {
    PortfolioBuilderSession.ensureRegistered().clear();
    Get.to(() => const ModelPortfolioBuilderScreen());
  }

  void _openEdit(String id) {
    PortfolioBuilderSession.ensureRegistered().clear();
    Get.to(() => ModelPortfolioBuilderScreen(portfolioId: id));
  }

  Future<void> _confirmDelete(PortfolioSummary portfolio) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: HomeUi.cardBg(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          ),
          title: Text('Delete Model Portfolio', style: HomeUi.sectionTitle(isDark)),
          content: Text(
            'Delete "${portfolio.portfolioName}"? This cannot be undone.',
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

    if (confirmed != true || !mounted) return;

    final success = await _modelController.portfolioController
        .deletePortfolio(portfolio.id);
    if (!mounted) return;

    if (success) {
      SnackBarUtils.showSuccess(context, 'Model portfolio deleted');
      await _modelController.fetchModels();
    } else {
      SnackBarUtils.showError(
        context,
        _modelController.portfolioController.errorMessage.value.isNotEmpty
            ? _modelController.portfolioController.errorMessage.value
            : 'Failed to delete portfolio',
      );
    }
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
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          height: 44,
          child: HomeUi.actionMenuItem(
            dark: isDark,
            icon: Icons.edit_rounded,
            label: 'Edit',
          ),
        ),
        const PopupMenuDivider(),
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
      ],
      onSelected: (value) async {
        if (value == 'edit') {
          _openEdit(portfolio.id);
        } else if (value == 'delete') {
          await _confirmDelete(portfolio);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FeatureGuard(
      featureKey: FeatureKeys.portfolios,
      child: Scaffold(
        backgroundColor: HomeUi.pageBg(isDark),
        body: Stack(
          children: [
            Column(
              children: [
                Obx(() => HomeTabBar(
                      showBackButton: true,
                      isWatchlistOpen: _watchlistService.isWatchlistOpen.value,
                      onWatchlistToggle: () => _watchlistService.toggleWatchlist(),
                      onThemeToggle: () {
                        Get.changeThemeMode(
                          isDark ? ThemeMode.light : ThemeMode.dark,
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Model Portfolios',
                                        style: HomeUi.heading(isDark)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Percentage-based strategies for analyst research and customer assignment.',
                                      style: HomeUi.subtitle(isDark),
                                    ),
                                  ],
                                ),
                              ),
                              HomeUi.primaryAction(
                                label: 'Create Model Portfolio',
                                icon: Icons.add_rounded,
                                onTap: _openCreate,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SlidingPillTabs(
                            itemCount: 2,
                            selectedIndex: _tabIndex,
                            controller: _tabController,
                            isDarkMode: isDark,
                            onSelect: (i) => _tabController.animateTo(i),
                            itemBuilder: (ctx, i, selected) => Text(
                              i == 0 ? 'Published' : 'Drafts',
                              style: HomeUi.control(isDark, active: selected)
                                  .copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : HomeUi.muted(isDark),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Obx(() => _buildTable(isDark)),
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
                child: WatchlistSidebar(
                  isDarkMode: isDark,
                  onClose: () => _watchlistService.closeWatchlist(),
                ),
              );
            }),
            const GlobalFABOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(bool isDark) {
    final loading = _modelController.portfolioController.isLoading.value;
    final list = _tabIndex == 0
        ? _modelController.publishedModels
        : _modelController.draftModels;
    final title = _tabIndex == 0 ? 'Published Models' : 'Draft Models';

    if (loading && list.isEmpty) {
      return ShimmerWidgets.perShareTableShimmer(
        baseColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
        highlightColor:
            isDark ? const Color(0xFF404040) : const Color(0xFFF3F4F6),
      );
    }

    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: HomeUi.cardDecoration(isDark),
        child: Center(
          child: Text(
            _tabIndex == 0
                ? 'No published model portfolios yet.'
                : 'No draft models in progress.',
            style: HomeUi.subtitle(isDark),
          ),
        ),
      );
    }

    final rows = list.map((p) {
      return SimpleRowModel(
        symbol: '',
        name: p.portfolioName,
        logo: null,
        fields: {
          'strategy': p.strategyType ?? '—',
          'risk': p.riskProfile ?? '—',
          'holdings': p.holdingsCount.toString(),
          'allocation': '${p.allocationPercent.toStringAsFixed(0)}%',
          'status': p.status,
          'updated': DateFormat('MMM dd, yyyy').format(p.lastUpdated),
          'actions': _buildActionsMenu(p, isDark),
        },
      );
    }).toList();

    return Container(
      decoration: HomeUi.cardDecoration(isDark),
      clipBehavior: Clip.antiAlias,
      child: DynamicTable(
        columns: [
          SimpleColumn(label: 'STRATEGY', fieldName: 'strategy', width: 120),
          SimpleColumn(label: 'RISK', fieldName: 'risk', width: 100),
          SimpleColumn(
            label: 'HOLDINGS',
            fieldName: 'holdings',
            width: 90,
            isNumeric: true,
          ),
          SimpleColumn(
            label: 'ALLOC %',
            fieldName: 'allocation',
            width: 90,
            isNumeric: true,
          ),
          SimpleColumn(label: 'STATUS', fieldName: 'status', width: 90),
          SimpleColumn(label: 'UPDATED', fieldName: 'updated', width: 120),
          SimpleColumn(label: 'ACTIONS', fieldName: 'actions', width: 64),
        ],
        rows: rows,
        title: title,
        subtitle: '${list.length} model portfolio${list.length == 1 ? '' : 's'}',
        toolbarLeadingIcon: Icons.pie_chart_outline_rounded,
        showFixedColumn: true,
        considerPadding: false,
        showOuterShadow: false,
        fixedColumnWidth: 220,
        tickerHeaderLabel: 'MODEL',
        tableId: 'model_portfolios_table',
        zebraStripes: true,
      ),
    );
  }
}
