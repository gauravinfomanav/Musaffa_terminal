import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Components/global_fab_overlay.dart';
import 'package:musaffa_terminal/Controllers/trading_ideas_controller.dart';
import 'package:musaffa_terminal/Controllers/search_service.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';

class TradingIdeasScreen extends StatefulWidget {
  const TradingIdeasScreen({super.key});

  @override
  State<TradingIdeasScreen> createState() => _TradingIdeasScreenState();
}

class _TradingIdeasScreenState extends State<TradingIdeasScreen> {
  late final TradingIdeasController _controller;
  late final WatchlistController _watchlistController;
  final GlobalWatchlistService _watchlistService = Get.find<GlobalWatchlistService>();

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.ideas);
    }
    _controller = Get.isRegistered<TradingIdeasController>()
        ? Get.find<TradingIdeasController>()
        : Get.put(TradingIdeasController());
    _watchlistController = WatchlistController.ensureRegistered();
    _controller.fetchTradingIdeas(force: true);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Color _actionColor(String action) {
    switch (action.toLowerCase()) {
      case 'buy':
        return const Color(0xFF34D399);
      case 'sell':
        return const Color(0xFFF87171);
      case 'hold':
        return const Color(0xFFEAB308);
      case 'reduce':
        return const Color(0xFFF87171);
      case 'add':
        return const Color(0xFF34D399);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  Future<void> _openAddIdeaModal() async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'New Trading Idea',
      barrierColor: Colors.black.withValues(alpha: 0.46),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AddTradingIdeaModal(controller: _controller);
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

    if (result == true && mounted) {
      SnackBarUtils.showSuccess(context, 'Trading idea added successfully.');
    }
  }

  void _toggleWatchlist() {
    if (!_watchlistService.isWatchlistOpen.value) {
      _watchlistController.resetToDefaultWatchlist();
    }
    _watchlistService.toggleWatchlist();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FeatureGuard(
      featureKey: FeatureKeys.tradingIdeas,
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
                          _buildIdeasCard(context),
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
              Text('Analyst Ideas Board', style: HomeUi.heading(isDark)),
              const SizedBox(height: 4),
              Text(
                'Research calls and conviction scores from your team.',
                style: HomeUi.subtitle(isDark),
              ),
            ],
          ),
        ),
        Obx(() {
          final isSubmitting = _controller.isSubmitting.value;
          return Row(
            children: [
              _HeaderGhostButton(
                label: 'Refresh',
                icon: Icons.refresh_rounded,
                isDarkMode: isDark,
                onTap: () => _controller.fetchTradingIdeas(force: true),
              ),
              const SizedBox(width: 8),
              IgnorePointer(
                ignoring: isSubmitting,
                child: Opacity(
                  opacity: isSubmitting ? 0.55 : 1,
                  child: HomeUi.primaryAction(
                    label: isSubmitting ? 'Submitting...' : 'Add Idea',
                    icon: Icons.add_rounded,
                    onTap: _openAddIdeaModal,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildIdeasCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final ideas = _controller.ideas;
      final isLoading = _controller.isLoading.value;
      final error = _controller.errorMessage.value;

      Widget content;
      if (isLoading && ideas.isEmpty) {
        content = Padding(
          padding: const EdgeInsets.all(16),
          child: _buildIdeasTableShimmer(isDark),
        );
      } else if (error.isNotEmpty && ideas.isEmpty) {
        content = Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Center(
            child: Text(
              error,
              style: HomeUi.subtitle(isDark).copyWith(
                color: HomeUi.negative(isDark),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      } else if (ideas.isEmpty) {
        content = Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text(
              'No trading ideas published yet.',
              style: HomeUi.subtitle(isDark),
              textAlign: TextAlign.center,
            ),
          ),
        );
      } else {
        final columns = _buildIdeaColumns(context);
        final rows = _mapIdeasToRows(context, ideas, columns);
        content = DynamicTable(
          columns: columns,
          rows: rows,
          title: 'Published Ideas',
          subtitle: ideas.length == 1
              ? '1 research idea from your team'
              : '${ideas.length} research ideas from your team',
          toolbarLeadingIcon: Icons.insights_rounded,
          showFixedColumn: true,
          considerPadding: false,
          showOuterShadow: false,
          columnSpacing: 4,
          fixedColumnWidth: 220,
          headerHeight: 44,
          rowHeight: 56,
          enableLivePrices: false,
          zebraStripes: true,
          enableColumnCustomization: true,
          showColumnActionMenu: true,
          showColumnResizeHandle: true,
          tickerHeaderLabel: 'COMPANY',
          tableId: 'trading_ideas_table',
        );
      }

      return Container(
        width: double.infinity,
        padding: ideas.isEmpty && !isLoading
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(0, 16, 0, 16),
        decoration: HomeUi.cardDecoration(isDark),
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    });
  }

  Widget _buildIdeasTableShimmer(bool isDark) {
    final baseColor =
        isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB);
    final highlightColor =
        isDark ? const Color(0xFF404040) : const Color(0xFFF3F4F6);

    return ShimmerWidgets.perShareTableShimmer(
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }

  List<SimpleColumn> _buildIdeaColumns(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const fixedTickerWidth = 220.0;
    final padding = LayoutConstants.screenPadding.horizontal + 48;
    final availableWidth = max(screenWidth - padding - fixedTickerWidth, 720.0);

    double clampWidth(double desired, double min, double max) {
      return desired.clamp(min, max);
    }

    final titleWidth = clampWidth(availableWidth * 0.42, 280, 640);
    final remainingWidth = availableWidth - titleWidth;

    const configs = [
      _ColumnConfig('ANALYST', 'analyst'),
      _ColumnConfig('RESEARCH ORG', 'researchOrg'),
      _ColumnConfig('ACTION', 'action'),
      _ColumnConfig('CONFIDENCE', 'conviction'),
      _ColumnConfig('TARGET', 'target', isNumeric: true),
      _ColumnConfig('CURRENT', 'current', isNumeric: true),
      _ColumnConfig('DATE ADDED', 'dateAdded'),
      _ColumnConfig('SUPPORTING REPORTS', 'reports'),
    ];

    final perWidth = clampWidth(
      remainingWidth / configs.length,
      140,
      260,
    );

    return [
      SimpleColumn(
        label: 'ANALYST',
        fieldName: 'analyst',
        width: perWidth,
      ),
      SimpleColumn(
        label: 'TITLE',
        fieldName: 'title',
        width: titleWidth,
      ),
      ...configs.skip(1).map(
            (config) => SimpleColumn(
              label: config.label,
              fieldName: config.fieldName,
              width: perWidth,
              isNumeric: config.isNumeric,
            ),
          ),
    ];
  }

  List<SimpleRowModel> _mapIdeasToRows(
    BuildContext context,
    List<TradingIdea> ideas,
    List<SimpleColumn> columns,
  ) {
    final widthByField = <String, double?>{
      for (final column in columns) column.fieldName: column.width
    };

    return ideas.map((idea) {
      final meta = _controller.tickerMeta[idea.ticker];
      return SimpleRowModel(
        symbol: idea.ticker,
        name: meta?.companyName ?? idea.company,
        logo: meta?.logo,
        price: idea.current,
        fields: {
          'analyst': idea.name.trim().isEmpty ? '--' : idea.name.trim(),
          'title': _wrappedTextCell(
            context,
            idea.title,
            width: widthByField['title'],
            maxLines: 1,
            enableTooltip: true,
            emphasized: true,
          ),
          'researchOrg':
              idea.researchOrg.trim().isEmpty ? '--' : idea.researchOrg.trim(),
          'action': _buildActionWidget(
            idea.action,
            width: widthByField['action'],
          ),
          'conviction': _buildConvictionCell(
            context,
            idea.conviction,
            widthByField['conviction'],
          ),
          'target': _formatNumber(idea.target),
          'current': _formatNumber(idea.current),
          'dateAdded': _formatDate(idea.createdAt),
          'reports': _buildReportsWidget(
            context,
            idea.supportingReports,
            width: widthByField['reports'],
          ),
        },
      );
    }).toList();
  }

  String _formatNumber(num value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  Widget _buildConvictionCell(
    BuildContext context,
    double? conviction,
    double? width,
  ) {
    if (conviction == null) {
      return _wrappedTextCell(
        context,
        '--',
        width: width,
        maxLines: 1,
      );
    }

    final double clamped = conviction.clamp(0, 5).toDouble();
    final double normalized = clamped / 5;
    final color = _convictionColor(clamped);
    final label = _convictionLabel(clamped);

    final content = Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  '${clamped.toStringAsFixed(1)} / 5',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: HomeUi.tableCellEmphasis(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(HomeUi.radiusPill),
                  color: color.withOpacity(0.12),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  softWrap: false,
                  style: HomeUi.control(
                    Theme.of(context).brightness == Brightness.dark,
                  ).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            child: Stack(
              children: [
                Container(
                  height: 5,
                  color: HomeUi.elevatedBg(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: normalized,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.75), color],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: content);
    }
    return content;
  }

  Color _convictionColor(double score) {
    if (score >= 4) return const Color(0xFF10B981); // green
    if (score >= 3) return const Color(0xFFFBBF24); // amber
    return const Color(0xFFEF4444); // red
  }

  String _convictionLabel(double score) {
    if (score >= 4.25) return 'High';
    if (score >= 3) return 'Medium';
    return 'Low';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Widget _buildActionWidget(String action, {double? width}) {
    final color = _actionColor(action);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chip = Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HomeUi.radiusPill),
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Text(
          action.toUpperCase(),
          maxLines: 1,
          softWrap: false,
          style: HomeUi.control(isDark).copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
    if (width == null) return chip;
    return SizedBox(width: width, child: chip);
  }

  Widget _buildReportsWidget(BuildContext context, List<String> reports,
      {double? width}) {
    if (reports.isEmpty) {
      return _wrappedTextCell(
        context,
        '--',
        width: width,
        maxLines: 1,
      );
    }

    final wrap = Wrap(
      spacing: 8,
      runSpacing: 6,
      children: List.generate(reports.length, (index) {
        return GestureDetector(
          onTap: () => launchUrlString(
            reports[index],
            mode: LaunchMode.externalApplication,
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Icon(
              Icons.picture_as_pdf,
              size: 20,
              color: const Color(0xFFDC2626),
            ),
          ),
        );
      }),
    );
    if (width == null) return wrap;
    return SizedBox(width: width, child: wrap);
  }

  Widget _wrappedTextCell(
    BuildContext context,
    String text, {
    double? width,
    int maxLines = 1,
    bool enableTooltip = false,
    bool emphasized = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final display = text.isEmpty ? '--' : text.trim();
    final label = Text(
      display,
      style: emphasized
          ? HomeUi.tableCellEmphasis(isDark)
          : HomeUi.tableCellSecondary(isDark),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
    Widget aligned = Align(
      alignment: Alignment.centerLeft,
      child: label,
    );
    aligned = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: aligned,
    );
    if (enableTooltip && display != '--') {
      aligned = Tooltip(
        message: display,
        waitDuration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: DashboardTextStyles.dataCell.copyWith(
          color: Colors.white,
          fontSize: 12,
        ),
        child: aligned,
      );
    }
    if (width == null) return aligned;
    return SizedBox(width: width, child: aligned);
  }
}

class _HeaderGhostButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDarkMode;

  const _HeaderGhostButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  State<_HeaderGhostButton> createState() => _HeaderGhostButtonState();
}

class _HeaderGhostButtonState extends State<_HeaderGhostButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: HomeUi.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _hover ? HomeUi.elevatedBg(dark) : HomeUi.cardBg(dark),
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            border: Border.all(
              color: _hover ? HomeUi.borderStrong(dark) : HomeUi.borderLight(dark),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: HomeUi.muted(dark)),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: HomeUi.control(dark).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColumnConfig {
  final String label;
  final String fieldName;
  final bool isNumeric;

  const _ColumnConfig(this.label, this.fieldName, {this.isNumeric = false});
}

class _NumericInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Allow empty string
    if (text.isEmpty) {
      return newValue;
    }

    // Only allow digits and one decimal point
    final regex = RegExp(r'^\d*\.?\d*$');
    if (!regex.hasMatch(text)) {
      return oldValue;
    }

    // Count decimal points - only allow one
    final dotCount = '.'.allMatches(text).length;
    if (dotCount > 1) {
      return oldValue;
    }

    return newValue;
  }
}

class AddTradingIdeaModal extends StatefulWidget {
  final TradingIdeasController controller;

  const AddTradingIdeaModal({super.key, required this.controller});

  @override
  State<AddTradingIdeaModal> createState() => _AddTradingIdeaModalState();
}

class _AddTradingIdeaModalState extends State<AddTradingIdeaModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _orgController = TextEditingController();
  final _tickerController = TextEditingController();
  final _targetController = TextEditingController();
  final _currentController = TextEditingController();
  final _reportsController = TextEditingController();

  String _selectedAction = kTradingIdeaActions.first;
  bool _submitting = false;
  double _convictionValue = 3.0;
  String? _reportsError;

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _orgController.dispose();
    _tickerController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    _reportsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tickerController.text.isEmpty) {
      SnackBarUtils.showError(context, 'Select a ticker via search.');
      return;
    }

    final target = num.tryParse(_targetController.text);
    final current = num.tryParse(_currentController.text);

    if (target == null || current == null) {
      SnackBarUtils.showError(
          context, 'Target and current prices must be numeric.');
      return;
    }

    final reports = _normalizeReports(_reportsController.text);
    if (reports == null) {
      setState(() {
        _reportsError =
            'Provide valid http/https links separated by comma or newline.';
      });
      return;
    } else {
      setState(() => _reportsError = null);
    }
    final conviction =
        double.parse(_convictionValue.clamp(0, 5).toStringAsFixed(1));

    setState(() => _submitting = true);
    final success = await widget.controller.createTradingIdea(
      CreateTradingIdeaRequest(
        name: _nameController.text.trim(),
        title: _titleController.text.trim(),
        company: _companyController.text.trim(),
        researchOrg: _orgController.text.trim(),
        ticker: _tickerController.text.trim(),
        action: _selectedAction,
        target: target,
        current: current,
        supportingReports: reports,
        conviction: conviction,
      ),
    );
    setState(() => _submitting = false);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    } else if (!success && mounted) {
      final msg = widget.controller.submitError.value.isNotEmpty
          ? widget.controller.submitError.value
          : 'Unable to add trading idea.';
      SnackBarUtils.showError(context, msg);
    }
  }

  List<String>? _normalizeReports(String input) {
    if (input.trim().isEmpty) return [];
    final entries = input
        .split(RegExp(r'[\n,]'))
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList();
    final invalid = entries.any((link) {
      final uri = Uri.tryParse(link);
      return uri == null ||
          !uri.hasScheme ||
          !(uri.isScheme('http') || uri.isScheme('https'));
    });
    if (invalid) return null;
    return entries;
  }

  void _onTickerSelected(TickerModel ticker) {
    _tickerController.text = ticker.symbol ?? ticker.ticker ?? '';
    _companyController.text = ticker.companyName ?? ticker.name ?? '';
    if (ticker.currentPrice != null) {
      _currentController.text = ticker.currentPrice!.toStringAsFixed(2);
    } else {
      _currentController.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxWidth = min(MediaQuery.of(context).size.width * 0.85, 880.0);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 20, 20),
                  child: _buildModalHeader(isDark),
                ),
                Divider(height: 1, thickness: 1, color: HomeUi.borderLight(isDark)),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Form(
                      key: _formKey,
                      child: _buildFormFields(isDark),
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: HomeUi.borderLight(isDark)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: _buildModalFooter(isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalFooter(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'All fields marked with validation are required.',
            style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
          ),
        ),
        IgnorePointer(
          ignoring: _submitting,
          child: Opacity(
            opacity: _submitting ? 0.55 : 1,
            child: _HeaderGhostButton(
              label: 'Cancel',
              icon: Icons.close_rounded,
              isDarkMode: isDark,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IgnorePointer(
          ignoring: _submitting,
          child: Opacity(
            opacity: _submitting ? 0.55 : 1,
            child: HomeUi.primaryAction(
              label: _submitting ? 'Saving...' : 'Save Idea',
              icon: Icons.check_rounded,
              onTap: _handleSubmit,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModalHeader(bool isDark) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: HomeUi.iconWellGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HomeUi.iconWellBorder),
          ),
          child: HomeUi.brandIcon(
            icon: Icons.lightbulb_outline_rounded,
            size: HomeUi.iconMd,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Trading Idea',
                style: HomeUi.heading(isDark).copyWith(fontSize: 18),
              ),
              const SizedBox(height: 2),
              Text(
                'Publish a research call with conviction and supporting links.',
                style: HomeUi.subtitle(isDark),
              ),
            ],
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: HomeUi.controlHeight,
              height: HomeUi.controlHeight,
              decoration: BoxDecoration(
                color: HomeUi.elevatedBg(isDark),
                shape: BoxShape.circle,
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
    );
  }

  Widget _buildFormFields(bool isDark) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FilterTextField(
                dark: isDark,
                label: 'Analyst Name',
                controller: _nameController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r"[A-Za-z\s&.,'\-]"),
                  ),
                ],
                validator: _requiredLettersValidator,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilterTextField(
                dark: isDark,
                label: 'Idea Title',
                controller: _titleController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r"[A-Za-z\s&.,'\-]"),
                  ),
                ],
                validator: _requiredLettersValidator,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilterTextField(
                dark: isDark,
                label: 'Research Org / Desk',
                controller: _orgController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r"[A-Za-z\s&.,'\-]"),
                  ),
                ],
                validator: _requiredLettersValidator,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TickerSearchField(
          tickerController: _tickerController,
          companyController: _companyController,
          onTickerSelected: _onTickerSelected,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildDropdownField(isDark)),
            const SizedBox(width: 12),
            Expanded(
              child: FilterTextField(
                dark: isDark,
                label: 'Target Price',
                controller: _targetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_NumericInputFormatter()],
                validator: _requiredNumericValidator,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilterTextField(
                dark: isDark,
                label: 'Current Price',
                controller: _currentController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_NumericInputFormatter()],
                validator: _requiredNumericValidator,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildConvictionField(isDark),
        const SizedBox(height: 14),
        _buildReportsField(isDark),
      ],
    );
  }

  String? _requiredLettersValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required field';
    }
    if (!RegExp(r"^[A-Za-z\s&.,'\-]+$").hasMatch(value.trim())) {
      return 'Only alphabetic characters are allowed';
    }
    return null;
  }

  String? _requiredNumericValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Required field';
    }
    if (trimmed != '.' && double.tryParse(trimmed) == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  Widget _buildDropdownField(bool isDark) {
    return FilterDropdown<String>(
      dark: isDark,
      label: 'Action',
      value: _selectedAction,
      items: kTradingIdeaActions
          .map(
            (action) => DropdownMenuItem(
              value: action,
              child: Text(action),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedAction = value);
        }
      },
    );
  }

  Widget _buildReportsField(bool isDark) {
    return FilterTextField(
      dark: isDark,
      label: 'Supporting Reports',
      controller: _reportsController,
      hintText: 'Comma or newline separated http/https links',
      minLines: 3,
      maxLines: 4,
      errorText: _reportsError,
    );
  }

  Widget _buildConvictionField(bool isDark) {
    final scoreColor = _convictionColor(_convictionValue);
    return FilterRangeSlider(
      dark: isDark,
      label: 'Confidence Score',
      value: _convictionValue,
      min: 0,
      max: 5,
      divisions: 10,
      midLabel: '2.5',
      activeColor: scoreColor,
      labelTrailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HomeUi.radiusPill),
          color: scoreColor.withValues(alpha: 0.12),
          border: Border.all(color: scoreColor.withValues(alpha: 0.35)),
        ),
        child: Text(
          '${_convictionValue.toStringAsFixed(1)} / 5',
          style: HomeUi.control(isDark, active: true).copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scoreColor,
          ),
        ),
      ),
      onChanged: (value) => setState(() => _convictionValue = value),
    );
  }

  Color _convictionColor(double score) {
    if (score >= 4) return const Color(0xFF10B981);
    if (score >= 3) return const Color(0xFFFBBF24);
    return const Color(0xFFEF4444);
  }
}

class TickerSearchField extends StatefulWidget {
  final TextEditingController tickerController;
  final TextEditingController companyController;
  final ValueChanged<TickerModel> onTickerSelected;

  const TickerSearchField({
    super.key,
    required this.tickerController,
    required this.companyController,
    required this.onTickerSelected,
  });

  @override
  State<TickerSearchField> createState() => _TickerSearchFieldState();
}

class _TickerSearchFieldState extends State<TickerSearchField> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<TickerModel> _results = [];
  bool _isSearching = false;
  bool _hover = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final matches = await SearchService.searchStocks(query.trim());
      if (!mounted) return;
      setState(() {
        _results = matches;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _isSearching = false;
      });
    }
  }

  void _handleSelection(TickerModel ticker) {
    widget.onTickerSelected(ticker);
    _searchController.text = ticker.symbol ?? ticker.ticker ?? '';
    _results = [];
    setState(() {});
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final focused = _searchFocusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeUi.filterFieldColumn(
          dark: isDark,
          label: 'Search ticker / company',
          field: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: HomeUi.filterFieldShell(
              dark: isDark,
              accent: focused,
              hover: _hover,
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: HomeUi.muted(isDark),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onQueryChanged,
                      cursorColor: HomeUi.title(isDark),
                      style: HomeUi.control(isDark, active: true)
                          .copyWith(fontSize: 13),
                      decoration: HomeUi.filterTextFieldDecoration(
                        isDark,
                        hintText: 'Type symbol or company name',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.tickerController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          HomeUi.filterFieldShell(
            dark: isDark,
            child: Row(
              children: [
                HomeUi.brandIcon(
                  icon: Icons.check_circle_outline_rounded,
                  size: HomeUi.iconMd,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.tickerController.text,
                        style: HomeUi.control(isDark, active: true).copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.companyController.text.isNotEmpty)
                        Text(
                          widget.companyController.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildResultsPanel(isDark),
        ),
      ],
    );
  }

  Widget _buildResultsPanel(bool isDark) {
    final showPanel = _isSearching || _results.isNotEmpty;
    if (!showPanel) return const SizedBox.shrink();

    return KeyedSubtree(
      key: ValueKey('${_isSearching}_${_results.length}'),
      child: HomeUi.filterFieldShell(
      dark: isDark,
      height: 180,
      padding: EdgeInsets.zero,
      alignment: Alignment.topCenter,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: _isSearching
          ? ShimmerWidgets.NewlistItem(
              index: 0,
              avatarSize: 40,
              titleWidth: 120,
              titleHeight: 16,
              subtitleWidth: 180,
              subtitleHeight: 14,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              baseColor: isDark ? const Color(0xFF1F2530) : Colors.grey[200]!,
              highlightColor:
                  isDark ? const Color(0xFF2A2F33) : Colors.grey[100]!,
            )
          : _results.isNotEmpty
              ? ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    color: HomeUi.borderLight(isDark),
                  ),
                  itemBuilder: (_, index) {
                    final ticker = _results[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleSelection(ticker),
                        overlayColor:
                            const WidgetStatePropertyAll(Colors.transparent),
                        splashFactory: NoSplash.splashFactory,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ticker.symbol ?? ticker.ticker ?? '',
                                      style: HomeUi.control(
                                        isDark,
                                        active: true,
                                      ).copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ticker.companyName ?? ticker.name ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: HomeUi.subtitle(isDark).copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.north_west_rounded,
                                size: 14,
                                color: HomeUi.muted(isDark),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Text(
                    'No matches found.',
                    style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
                  ),
                ),
      ),
    ),
    );
  }
}
