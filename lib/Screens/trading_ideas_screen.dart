import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Controllers/trading_ideas_controller.dart';
import 'package:musaffa_terminal/Controllers/search_service.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';

class TradingIdeasScreen extends StatefulWidget {
  const TradingIdeasScreen({super.key});

  @override
  State<TradingIdeasScreen> createState() => _TradingIdeasScreenState();
}

class _TradingIdeasScreenState extends State<TradingIdeasScreen> {
  late final TradingIdeasController _controller;
  late final WatchlistController _watchlistController;
  bool _isWatchlistOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<TradingIdeasController>()
        ? Get.find<TradingIdeasController>()
        : Get.put(TradingIdeasController());
    _watchlistController = Get.put(WatchlistController());
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
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddTradingIdeaModal(controller: _controller),
    );

    if (result == true && mounted) {
      SnackBarUtils.showSuccess(context, 'Trading idea added successfully.');
    }
  }

  void _toggleWatchlist() {
    setState(() {
      _isWatchlistOpen = !_isWatchlistOpen;
      if (_isWatchlistOpen) {
        _watchlistController.resetToDefaultWatchlist();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
      body: GestureDetector(
        onTap: () {
          if (_isWatchlistOpen) {
            setState(() => _isWatchlistOpen = false);
          }
        },
        child: Stack(
          children: [
            Column(
              children: [
                HomeTabBar(
                  showBackButton: true,
                  isWatchlistOpen: _isWatchlistOpen,
                  onWatchlistToggle: _toggleWatchlist,
                  onThemeToggle: () {
                    final currentTheme = Theme.of(context).brightness;
                    Get.changeThemeMode(
                      currentTheme == Brightness.dark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    );
                  },
                ),
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
            if (_isWatchlistOpen)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {},
                  child: WatchlistSidebar(
                    isDarkMode: isDark,
                    onClose: () => setState(() => _isWatchlistOpen = false),
                  ),
                ),
              ),
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
              'Analyst Ideas Board',
              style: DashboardTextStyles.titleSmall.copyWith(
                fontSize: 20,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const Spacer(),
        Obx(() {
          final isSubmitting = _controller.isSubmitting.value;
          return Row(
            children: [
              _SecondaryPillButton(
                label: 'Refresh',
                icon: Icons.refresh,
                onTap: () => _controller.fetchTradingIdeas(force: true),
                isDarkMode: isDark,
              ),
              const SizedBox(width: 8),
              _PrimaryPillButton(
                label: isSubmitting ? 'Submitting...' : 'Add Idea',
                icon: Icons.add,
                onTap: isSubmitting ? null : _openAddIdeaModal,
                isDarkMode: isDark,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildIdeasCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB);
    final cardColor = isDark ? const Color(0xFF151718) : Colors.white;

    return Obx(() {
      final ideas = _controller.ideas;
      final isLoading = _controller.isLoading.value;
      final error = _controller.errorMessage.value;

      Widget content;
      if (isLoading && ideas.isEmpty) {
        content = const Center(child: CircularProgressIndicator());
      } else if (error.isNotEmpty && ideas.isEmpty) {
        content = Center(
          child: Text(
            error,
            style: DashboardTextStyles.errorMessage.copyWith(
              color: const Color(0xFFF87171),
            ),
          ),
        );
      } else if (ideas.isEmpty) {
        content = SizedBox(
          height: 400,
          child: Center(
            child: Text(
              'No trading ideas published yet.',
              style: DashboardTextStyles.noData.copyWith(
                color:
                    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ),
        );
      } else {
        final columns = _buildIdeaColumns(context);
        final rows = _mapIdeasToRows(context, ideas, columns);
        content = Padding(
          padding: const EdgeInsets.all(12),
          child: DynamicTable(
            columns: columns,
            rows: rows,
            showFixedColumn: true,
            considerPadding: false,
            columnSpacing: 20,
            fixedColumnWidth: 320,
            enableLivePrices: false,
            zebraStripes: true,
            evenRowColor: Colors.transparent,
            oddRowColor:
                isDark ? const Color(0xFF14171C) : const Color(0xFFF5F6F8),
          ),
        );
      }

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: content,
      );
    });
  }

  List<SimpleColumn> _buildIdeaColumns(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const fixedTickerWidth = 320.0;
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
          'analyst': _wrappedTextCell(
            context,
            idea.name,
            width: widthByField['analyst'],
            maxLines: 2,
          ),
          'title': _wrappedTextCell(
            context,
            idea.title,
            width: widthByField['title'],
            maxLines: 2,
            enableTooltip: true,
          ),
          'researchOrg': _wrappedTextCell(
            context,
            idea.researchOrg.isEmpty ? '--' : idea.researchOrg,
            width: widthByField['researchOrg'],
            maxLines: 2,
          ),
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
          'dateAdded': _wrappedTextCell(
            context,
            _formatDate(idea.createdAt),
            width: widthByField['dateAdded'],
            maxLines: 1,
          ),
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
      padding: const EdgeInsets.only(top: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${clamped.toStringAsFixed(1)} / 5',
                style: DashboardTextStyles.dataCell.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: color.withOpacity(0.12),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(
                  label.toUpperCase(),
                  style: DashboardTextStyles.tickerSymbol.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF272B30)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: normalized,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.8),
                          color,
                        ],
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
    final chip = Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withOpacity(0.6), width: 0.8),
          color: color.withOpacity(0.12),
        ),
        child: Text(
          action.toUpperCase(),
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
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
    int maxLines = 2,
    bool enableTooltip = false,
  }) {
    final display = text.isEmpty ? '--' : text.trim();
    final label = Text(
      display,
      style: DashboardTextStyles.dataCell.copyWith(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFE5E7EB)
            : const Color(0xFF1F2937),
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
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

class _SecondaryPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isDarkMode;

  const _SecondaryPillButton({
    required this.label,
    this.icon,
    required this.isDarkMode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final accent =
        isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6);
    final disabledColor =
        isDarkMode ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(90),
          border: Border.all(
            color: enabled ? accent : disabledColor,
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
                color: enabled ? accent : disabledColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label.toUpperCase(),
              style: DashboardTextStyles.columnHeader.copyWith(
                color: enabled ? accent : disabledColor,
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
    final width = min(MediaQuery.of(context).size.width * 0.75, 960.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D1F) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModalHeader(isDark),
                  const SizedBox(height: 20),
                  _buildFormFields(isDark),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _PrimaryPillButton(
                      label: _submitting ? 'Saving...' : 'Save Idea',
                      icon: Icons.save_outlined,
                      isDarkMode: isDark,
                      onTap: _submitting ? null : _handleSubmit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'New Trading Idea',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close,
              color: isDark ? Colors.white70 : Colors.black87),
        ),
      ],
    );
  }

  Widget _buildFormFields(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildTextField(_nameController, 'Analyst Name',
                    onlyLetters: true)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildTextField(_titleController, 'Idea Title',
                    onlyLetters: true)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildTextField(_orgController, 'Research Org / Desk',
                    onlyLetters: true)),
          ],
        ),
        const SizedBox(height: 12),
        TickerSearchField(
          tickerController: _tickerController,
          companyController: _companyController,
          onTickerSelected: _onTickerSelected,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(isDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                _targetController,
                'Target Price',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                numericOnly: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                _currentController,
                'Current Price',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                numericOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildConvictionField(isDark),
        const SizedBox(height: 12),
        _buildReportsField(),
      ],
    );
  }

  Widget _buildDropdownField(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _selectedAction,
      decoration: _fieldDecoration('Action'),
      icon: const Icon(Icons.keyboard_arrow_down),
      dropdownColor: isDark ? const Color(0xFF111315) : Colors.white,
      items: kTradingIdeaActions
          .map(
            (action) => DropdownMenuItem(
              value: action,
              child: Text(
                action,
                style: const TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 13,
                ),
              ),
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

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text,
      bool onlyLetters = false,
      bool numericOnly = false,
      bool readOnly = false,
      Widget? suffix}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      autovalidateMode: AutovalidateMode.disabled,
      inputFormatters: [
        if (onlyLetters)
          FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s&.,'\-]")),
        if (numericOnly) _NumericInputFormatter(),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required field';
        }
        if (onlyLetters &&
            !RegExp(r"^[A-Za-z\s&.,'\-]+$").hasMatch(value.trim())) {
          return 'Only alphabetic characters are allowed';
        }
        if (numericOnly) {
          final trimmed = value.trim();
          if (trimmed.isEmpty) {
            return 'Required field';
          }
          // Allow intermediate states like "5." but validate final number
          if (trimmed != '.' && double.tryParse(trimmed) == null) {
            return 'Enter a valid number';
          }
        }
        return null;
      },
      decoration: suffix != null
          ? _fieldDecoration(label).copyWith(suffixIcon: suffix)
          : _fieldDecoration(label),
      style: const TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 13,
        height: 1.2,
      ),
    );
  }

  Widget _buildReportsField() {
    return TextFormField(
      controller: _reportsController,
      minLines: 3,
      maxLines: 4,
      decoration: _fieldDecoration(
        'Supporting Reports (comma or newline separated links)',
      ).copyWith(errorText: _reportsError),
      style: const TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 13,
        height: 1.2,
      ),
    );
  }

  Widget _buildConvictionField(bool isDark) {
    final textColor =
        isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121417) : const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF2F3338) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confidence Score (0 – 5)',
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Current: ${_convictionValue.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                        fontSize: 13,
                        height: 1.2,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _convictionValue,
            onChanged: (value) {
              setState(() => _convictionValue = value);
            },
            min: 0,
            max: 5,
            divisions: 10,
            label: _convictionValue.toStringAsFixed(1),
            activeColor: const Color(0xFF81AACE),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0', style: TextStyle(fontSize: 11, color: textColor)),
              Text('2.5', style: TextStyle(fontSize: 11, color: textColor)),
              Text('5', style: TextStyle(fontSize: 11, color: textColor)),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 13,
        height: 1.2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF81AACE), width: 1.5),
      ),
    );
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
  Timer? _debounceTimer;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _onQueryChanged,
          decoration: InputDecoration(
            labelText: 'Search ticker / company',
            prefixIcon: const Icon(Icons.search, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide:
                  const BorderSide(color: Color(0xFF81AACE), width: 1.5),
            ),
          ),
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontFamilyFallback: ['SFMono-Regular', 'Menlo', 'monospace'],
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
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

    return Container(
      key: ValueKey('${_isSearching}_${_results.length}'),
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111315) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: _isSearching
          ? ShimmerWidgets.NewlistItem(
              index: 0,
              avatarSize: 40,
              titleWidth: 120,
              titleHeight: 16,
              subtitleWidth: 180,
              subtitleHeight: 14,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              baseColor: isDark ? const Color(0xFF1F2530) : Colors.grey[200],
              highlightColor:
                  isDark ? const Color(0xFF2A2F33) : Colors.grey[100],
            )
          : _results.isNotEmpty
              ? ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _results.length,
                  itemBuilder: (_, index) {
                    final ticker = _results[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        ticker.symbol ?? ticker.ticker ?? '',
                        style: TextStyle(
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        ticker.companyName ?? ticker.name ?? '',
                        style: TextStyle(
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      onTap: () => _handleSelection(ticker),
                    );
                  },
                )
              : Center(
                  child: Text(
                    'No matches found.',
                    style: TextStyle(
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF4B5563),
                    ),
                  ),
                ),
    );
  }
}
