import 'dart:math';

import 'package:flutter/material.dart';
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
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
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
    final borderColor = isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB);
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
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
    final padding = LayoutConstants.screenPadding.horizontal + 64;
    final availableWidth = max(screenWidth - padding - 320, 600.0);

    double flexibleWidth(double fraction, double minWidth, double maxWidth) {
      final target = availableWidth * fraction;
      return target.clamp(minWidth, maxWidth);
    }

    return [
      SimpleColumn(
        label: 'ANALYST',
        fieldName: 'analyst',
        width: flexibleWidth(0.15, 140, 220),
      ),
      SimpleColumn(
        label: 'TITLE',
        fieldName: 'title',
        width: flexibleWidth(0.35, 240, 520),
      ),
      const SimpleColumn(label: 'ACTION', fieldName: 'action'),
      const SimpleColumn(label: 'TARGET', fieldName: 'target', isNumeric: true),
      const SimpleColumn(label: 'CURRENT', fieldName: 'current', isNumeric: true),
      const SimpleColumn(label: 'DATE ADDED', fieldName: 'dateAdded'),
      SimpleColumn(
        label: 'SUPPORTING REPORTS',
        fieldName: 'reports',
        width: flexibleWidth(0.2, 200, 360),
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
          'action': _buildActionWidget(
            idea.action,
            width: widthByField['action'],
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
          borderRadius: BorderRadius.circular(4),
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
        final label = 'Report ${index + 1}';
        return GestureDetector(
          onTap: () => launchUrlString(
            reports[index],
            mode: LaunchMode.externalApplication,
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Text(
              label,
              style: DashboardTextStyles.tickerSymbol.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF81AACE),
              ),
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
  final _tickerController = TextEditingController();
  final _targetController = TextEditingController();
  final _currentController = TextEditingController();
  final _reportsController = TextEditingController();

  String _selectedAction = kTradingIdeaActions.first;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
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
      SnackBarUtils.showError(context, 'Target and current prices must be numeric.');
      return;
    }

    final reports = _reportsController.text
        .split(RegExp(r'[\n,]'))
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList();

    setState(() => _submitting = true);
    final success = await widget.controller.createTradingIdea(
      CreateTradingIdeaRequest(
        name: _nameController.text.trim(),
        title: _titleController.text.trim(),
        company: _companyController.text.trim(),
        ticker: _tickerController.text.trim(),
        action: _selectedAction,
        target: target,
        current: current,
        supportingReports: reports,
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

  void _onTickerSelected(TickerModel ticker) {
    _tickerController.text = ticker.symbol ?? ticker.ticker ?? '';
    _companyController.text = ticker.companyName ?? ticker.name ?? '';
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
            fontFamily: 'RobotoMono',
            fontFamilyFallback: const ['SFMono-Regular', 'Menlo', 'monospace'],
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black87),
        ),
      ],
    );
  }

  Widget _buildFormFields(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTextField(_nameController, 'Analyst Name')),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_titleController, 'Idea Title')),
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
              child: _buildDropdownField(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                _targetController,
                'Target Price',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                _currentController,
                'Current Price',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildReportsField(),
      ],
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedAction,
      decoration: _fieldDecoration('Action'),
      icon: const Icon(Icons.keyboard_arrow_down),
      items: kTradingIdeaActions
          .map(
            (action) => DropdownMenuItem(
              value: action,
              child: Text(
                action,
                style: const TextStyle(
                  fontFamily: 'RobotoMono',
                  fontFamilyFallback: ['SFMono-Regular', 'Menlo', 'monospace'],
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
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Required field' : null,
      decoration: _fieldDecoration(label),
      style: const TextStyle(
        fontFamily: 'RobotoMono',
        fontFamilyFallback: ['SFMono-Regular', 'Menlo', 'monospace'],
        fontSize: 13,
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
          ),
      style: const TextStyle(
        fontFamily: 'RobotoMono',
        fontFamilyFallback: ['SFMono-Regular', 'Menlo', 'monospace'],
        fontSize: 12,
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'RobotoMono',
        fontFamilyFallback: ['SFMono-Regular', 'Menlo', 'monospace'],
        fontSize: 12,
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

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final matches = await SearchService.searchStocks(query.trim());
      setState(() {
        _results = matches;
        _isSearching = false;
      });
    } catch (_) {
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
          onChanged: _performSearch,
          decoration: InputDecoration(
            labelText: 'Search ticker / company',
            prefixIcon: const Icon(Icons.search, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF81AACE), width: 1.5),
            ),
          ),
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontFamilyFallback: ['SFMono-Regular', 'Menlo', 'monospace'],
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(),
          )
        else if (_results.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111315) : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (_, index) {
                final ticker = _results[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    ticker.symbol ?? ticker.ticker ?? '',
                    style: const TextStyle(
                      fontFamily: 'RobotoMono',
                      fontFamilyFallback: ['SFMono-Regular', 'Menlo', 'monospace'],
                      fontSize: 12,
                    ),
                  ),
                  subtitle: Text(
                    ticker.companyName ?? ticker.name ?? '',
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontFamilyFallback: const ['SFMono-Regular', 'Menlo', 'monospace'],
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  onTap: () => _handleSelection(ticker),
                );
              },
            ),
          ),
      ],
    );
  }
}

