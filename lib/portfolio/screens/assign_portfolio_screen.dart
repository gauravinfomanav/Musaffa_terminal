import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/Components/global_fab_overlay.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/Controllers/portfolio_assignment_controller.dart';
import 'package:musaffa_terminal/Controllers/portfolio_controller.dart';
import 'package:musaffa_terminal/models/customer_model.dart';
import 'package:musaffa_terminal/models/feature_keys.dart';
import 'package:musaffa_terminal/models/portfolio_assignment_model.dart';
import 'package:musaffa_terminal/models/portfolio_model.dart';
import 'package:musaffa_terminal/portfolio/controllers/model_portfolio_controller.dart';
import 'package:musaffa_terminal/portfolio/utils/allocation_format.dart';
import 'package:musaffa_terminal/portfolio/utils/portfolio_allocation_palette.dart';
import 'package:musaffa_terminal/services/company_enrichment_cache.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/feature_navigation.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Full-screen institutional assignment workflow —
/// mandate capture + capital briefing (sector/asset/holdings).
class AssignPortfolioScreen extends StatefulWidget {
  const AssignPortfolioScreen({super.key});

  @override
  State<AssignPortfolioScreen> createState() => _AssignPortfolioScreenState();
}

class _AssignPortfolioScreenState extends State<AssignPortfolioScreen> {
  final _watchlistService = Get.find<GlobalWatchlistService>();
  final _assignmentController = Get.put(PortfolioAssignmentController());
  final _modelController = Get.put(ModelPortfolioController());
  final _portfolioController = Get.put(PortfolioController());

  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedModelId;
  Customer? _selectedCustomer;
  AssignmentPreview? _preview;
  Portfolio? _selectedModel;
  bool _previewLoading = false;
  bool _saving = false;
  List<Customer> _customerResults = [];
  Timer? _previewDebounce;
  Timer? _customerDebounce;

  final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _moneyCompact = NumberFormat.compactCurrency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<GlobalSidebarService>()) {
      Get.find<GlobalSidebarService>().setActive(SidebarNavItem.portfolio);
    }
    _modelController.fetchModels();
    _assignmentController.searchCustomers('').then((list) {
      if (mounted) setState(() => _customerResults = list);
    });
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _customerDebounce?.cancel();
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _toggleWatchlist() => _watchlistService.toggleWatchlist();

  void _onCustomerQueryChanged(String value) {
    if (_selectedCustomer != null) {
      setState(() => _selectedCustomer = null);
    }
    _customerDebounce?.cancel();
    _customerDebounce = Timer(const Duration(milliseconds: 280), () async {
      final list = await _assignmentController.searchCustomers(value);
      if (mounted) setState(() => _customerResults = list);
    });
  }

  Future<void> _onModelChanged(String? id) async {
    setState(() {
      _selectedModelId = id;
      _selectedModel = null;
      _preview = null;
    });
    if (id == null) return;

    final model = await _portfolioController.getPortfolio(id);
    if (!mounted) return;
    setState(() => _selectedModel = model);

    final tickers = (model?.holdings ?? [])
        .map((h) => h.ticker)
        .where((t) => t.trim().isNotEmpty)
        .toList();
    if (tickers.isNotEmpty) {
      await CompanyEnrichmentCache.ensureSymbols(tickers);
      if (mounted) setState(() {});
    }
    _schedulePreview();
  }

  void _schedulePreview() {
    _previewDebounce?.cancel();
    // Clear while typing so partial amounts (e.g. "1" of "1000") don't flash charts.
    if (_preview != null || _previewLoading) {
      setState(() {
        _preview = null;
        _previewLoading = false;
      });
    }
    _previewDebounce = Timer(
      const Duration(milliseconds: 900),
      _refreshPreview,
    );
  }

  Future<void> _refreshPreview() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (_selectedModelId == null || amount == null || amount <= 0) {
      setState(() {
        _preview = null;
        _previewLoading = false;
      });
      return;
    }

    setState(() => _previewLoading = true);
    final preview = await _assignmentController.previewAssignment(
      modelPortfolioId: _selectedModelId!,
      investmentAmount: amount,
    );
    if (!mounted) return;

    if (preview != null) {
      final tickers = preview.holdings.map((h) => h.ticker).toList();
      await CompanyEnrichmentCache.ensureSymbols(tickers);
    }

    if (!mounted) return;
    setState(() {
      _preview = preview;
      _previewLoading = false;
    });
  }

  PortfolioHolding? _modelHolding(String ticker) {
    final list = _selectedModel?.holdings;
    if (list == null) return null;
    for (final h in list) {
      if (h.ticker.toUpperCase() == ticker.toUpperCase()) return h;
    }
    return null;
  }

  String _sectorFor(AssignmentHolding h) {
    final fromApi = h.sector?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;

    final fromModel = _modelHolding(h.ticker)?.sector?.trim();
    if (fromModel != null && fromModel.isNotEmpty) return fromModel;

    final enriched = CompanyEnrichmentCache.getCached(h.ticker);
    final sector = enriched?.sector?.trim();
    if (sector != null && sector.isNotEmpty) return sector;

    if (h.ticker.toUpperCase().startsWith('GOLD')) return 'Gold';
    if (h.ticker.toUpperCase().startsWith('CASH')) return 'Cash';
    return 'Unclassified';
  }

  String _companyFor(AssignmentHolding h) {
    if (h.company != null && h.company!.trim().isNotEmpty) return h.company!;
    final fromModel = _modelHolding(h.ticker)?.company;
    if (fromModel != null && fromModel.trim().isNotEmpty) return fromModel;
    return CompanyEnrichmentCache.getCached(h.ticker)?.name ?? h.ticker;
  }

  String _assetClassFor(AssignmentHolding h) {
    final fromModel = _modelHolding(h.ticker)?.assetType;
    final raw = (fromModel ?? h.assetType ?? 'Stock').toLowerCase();
    if (raw.contains('gold')) return 'Gold';
    if (raw.contains('bond')) return 'Bonds';
    if (raw.contains('reit') || raw.contains('real')) return 'Real Estate';
    if (raw.contains('cash')) return 'Cash';
    if (raw.contains('commodity')) return 'Commodity';
    if (raw.contains('etf')) return 'Equity';
    return 'Equity';
  }

  List<({String label, double percent, double amount, Color color})>
      _sectorSlices(bool isDark) {
    final preview = _preview;
    if (preview == null) return const [];
    final map = <String, double>{};
    for (final h in preview.holdings) {
      final sector = _sectorFor(h);
      map[sector] = (map[sector] ?? 0) + h.allocationPercent;
    }
    final total = map.values.fold<double>(0, (a, b) => a + b);
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map(
          (e) => (
            label: e.key,
            percent: total > 0 ? (e.value / total) * 100 : e.value,
            amount: preview.investmentAmount * (e.value / 100),
            color: PortfolioAllocationPalette.sectorColor(e.key, isDark),
          ),
        )
        .toList();
  }

  List<({String label, double percent, Color color})> _assetSlices(bool isDark) {
    final preview = _preview;
    if (preview == null) return const [];
    final map = <String, double>{};
    for (final h in preview.holdings) {
      final label = _assetClassFor(h);
      map[label] = (map[label] ?? 0) + h.allocationPercent;
    }
    return map.entries
        .map(
          (e) => (
            label: e.key,
            percent: e.value,
            color: PortfolioAllocationPalette.assetType(e.key, isDark),
          ),
        )
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent));
  }

  Future<void> _assign({required bool asDraft}) async {
    final name = _customerNameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (_selectedModelId == null) {
      SnackBarUtils.showError(context, 'Select a model portfolio');
      return;
    }
    if (amount == null || amount <= 0) {
      SnackBarUtils.showError(context, 'Enter a valid investment amount');
      return;
    }

    setState(() => _saving = true);

    Customer? customer = _selectedCustomer;
    if (customer == null) {
      if (name.isEmpty) {
        setState(() => _saving = false);
        SnackBarUtils.showError(context, 'Enter customer name or select one');
        return;
      }
      customer = await _assignmentController.createCustomer(
        fullName: name,
        email: _customerEmailController.text.trim().isEmpty
            ? null
            : _customerEmailController.text.trim(),
      );
      if (customer == null) {
        setState(() => _saving = false);
        if (mounted) {
          SnackBarUtils.showError(
            context,
            _assignmentController.saveError.value.isNotEmpty
                ? _assignmentController.saveError.value
                : 'Failed to create customer',
          );
        }
        return;
      }
    }

    final assignment = await _assignmentController.createAssignment(
      modelPortfolioId: _selectedModelId!,
      customerId: customer.id,
      investmentAmount: amount,
      status: asDraft ? 'draft' : 'active',
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (assignment != null) {
      SnackBarUtils.showSuccess(
        context,
        asDraft
            ? 'Assignment saved as draft'
            : 'Portfolio assigned successfully',
      );
      Get.back(result: true);
    } else {
      SnackBarUtils.showError(
        context,
        _assignmentController.saveError.value.isNotEmpty
            ? _assignmentController.saveError.value
            : 'Failed to assign portfolio',
      );
    }
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
                Obx(
                  () => HomeTabBar(
                    showBackButton: true,
                    isWatchlistOpen: _watchlistService.isWatchlistOpen.value,
                    onWatchlistToggle: _toggleWatchlist,
                    onThemeToggle: () {
                      Get.changeThemeMode(
                        isDark ? ThemeMode.light : ThemeMode.dark,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: LayoutConstants.screenPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPageHeader(isDark),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: 340,
                                child: _MandatePanel(
                                  isDark: isDark,
                                  customerNameController: _customerNameController,
                                  customerEmailController:
                                      _customerEmailController,
                                  amountController: _amountController,
                                  customerResults: _customerResults,
                                  selectedCustomer: _selectedCustomer,
                                  selectedModelId: _selectedModelId,
                                  models: _modelController.publishedModels,
                                  saving: _saving,
                                  onCustomerQueryChanged: _onCustomerQueryChanged,
                                  onSelectCustomer: (c) {
                                    setState(() {
                                      _selectedCustomer = c;
                                      _customerNameController.text = c.fullName;
                                      _customerEmailController.text =
                                          c.email ?? '';
                                    });
                                  },
                                  onModelChanged: _onModelChanged,
                                  onAmountChanged: (_) => _schedulePreview(),
                                  onCancel: () => Get.back(),
                                  onSaveDraft: () => _assign(asDraft: true),
                                  onAssign: () => _assign(asDraft: false),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _BriefingPanel(
                                  isDark: isDark,
                                  preview: _preview,
                                  previewLoading: _previewLoading,
                                  money: _money,
                                  moneyCompact: _moneyCompact,
                                  sectorSlices: _sectorSlices(isDark),
                                  assetSlices: _assetSlices(isDark),
                                  sectorFor: _sectorFor,
                                  companyFor: _companyFor,
                                  assetClassFor: _assetClassFor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildPageHeader(bool isDark) {
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
                'Mandate intake with live capital briefing — show the client exactly how funds are deployed.',
                style: HomeUi.subtitle(isDark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MandatePanel extends StatelessWidget {
  const _MandatePanel({
    required this.isDark,
    required this.customerNameController,
    required this.customerEmailController,
    required this.amountController,
    required this.customerResults,
    required this.selectedCustomer,
    required this.selectedModelId,
    required this.models,
    required this.saving,
    required this.onCustomerQueryChanged,
    required this.onSelectCustomer,
    required this.onModelChanged,
    required this.onAmountChanged,
    required this.onCancel,
    required this.onSaveDraft,
    required this.onAssign,
  });

  final bool isDark;
  final TextEditingController customerNameController;
  final TextEditingController customerEmailController;
  final TextEditingController amountController;
  final List<Customer> customerResults;
  final Customer? selectedCustomer;
  final String? selectedModelId;
  final List models;
  final bool saving;
  final ValueChanged<String> onCustomerQueryChanged;
  final ValueChanged<Customer> onSelectCustomer;
  final ValueChanged<String?> onModelChanged;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onCancel;
  final VoidCallback onSaveDraft;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: HomeUi.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CLIENT MANDATE', style: _overline(isDark)),
                const SizedBox(height: 6),
                Text(
                  'Capture investor identity and capital before confirming allocation.',
                  style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: HomeUi.borderLight(isDark)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: customerNameController,
                    onChanged: onCustomerQueryChanged,
                    decoration: HomeUi.filterFieldDecoration(
                      isDark,
                      labelText: 'Customer name',
                      hintText: 'Search or create walk-in',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: customerEmailController,
                    decoration: HomeUi.filterFieldDecoration(
                      isDark,
                      labelText: 'Email (optional)',
                    ),
                  ),
                  if (customerResults.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                        border: Border.all(color: HomeUi.borderLight(isDark)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: math.min(customerResults.length, 6),
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: HomeUi.borderLight(isDark),
                        ),
                        itemBuilder: (context, index) {
                          final c = customerResults[index];
                          final selected = selectedCustomer?.id == c.id;
                          return ListTile(
                            dense: true,
                            selected: selected,
                            selectedTileColor:
                                HomeUi.accent(isDark).withValues(alpha: 0.08),
                            title: Text(
                              c.fullName,
                              style: HomeUi.control(isDark)
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              c.email ?? c.customerCode ?? c.id,
                              style: HomeUi.subtitle(isDark).copyWith(fontSize: 11),
                            ),
                            onTap: () => onSelectCustomer(c),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Obx(() {
                    final _ = Get.find<ModelPortfolioController>()
                        .portfolioController
                        .activePortfolios
                        .length;
                    return DropdownButtonFormField<String>(
                      value: selectedModelId,
                      decoration: HomeUi.filterFieldDecoration(
                        isDark,
                        labelText: 'Model portfolio',
                      ),
                      dropdownColor: HomeUi.cardBg(isDark),
                      hint: Text(
                        'Select published model…',
                        style: HomeUi.subtitle(isDark),
                      ),
                      items: Get.find<ModelPortfolioController>()
                          .publishedModels
                          .map(
                            (m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(
                                m.portfolioName,
                                style: HomeUi.control(isDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: onModelChanged,
                    );
                  }),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: onAmountChanged,
                    decoration: HomeUi.filterFieldDecoration(
                      isDark,
                      labelText: 'Investment amount (USD)',
                      hintText: '2000',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: HomeUi.elevatedBg(isDark),
                      borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                      border: Border.all(color: HomeUi.borderLight(isDark)),
                    ),
                    child: Text(
                      'Model weights stay percentage-based. This screen converts them into dollar tickets for the client mandate.',
                      style: HomeUi.subtitle(isDark).copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: HomeUi.borderLight(isDark)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HomeUi.primaryAction(
                  label: saving ? 'Assigning…' : 'Confirm Assignment',
                  icon: Icons.check_circle_outline_rounded,
                  onTap: () {
                    if (!saving) onAssign();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: HomeUi.ghostAction(
                        label: saving ? '…' : 'Save Draft',
                        dark: isDark,
                        onTap: saving ? null : onSaveDraft,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: HomeUi.ghostAction(
                        label: 'Cancel',
                        dark: isDark,
                        onTap: saving ? null : onCancel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _overline(bool isDark) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: HomeUi.muted(isDark),
      );
}

class _BriefingPanel extends StatelessWidget {
  const _BriefingPanel({
    required this.isDark,
    required this.preview,
    required this.previewLoading,
    required this.money,
    required this.moneyCompact,
    required this.sectorSlices,
    required this.assetSlices,
    required this.sectorFor,
    required this.companyFor,
    required this.assetClassFor,
  });

  final bool isDark;
  final AssignmentPreview? preview;
  final bool previewLoading;
  final NumberFormat money;
  final NumberFormat moneyCompact;
  final List<({String label, double percent, double amount, Color color})>
      sectorSlices;
  final List<({String label, double percent, Color color})> assetSlices;
  final String Function(AssignmentHolding) sectorFor;
  final String Function(AssignmentHolding) companyFor;
  final String Function(AssignmentHolding) assetClassFor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: HomeUi.cardDecoration(isDark),
      child: previewLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : preview == null
              ? _emptyState(isDark)
              : _filledBriefing(isDark),
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_rounded,
              size: 36,
              color: HomeUi.muted(isDark),
            ),
            const SizedBox(height: 12),
            Text(
              'Capital briefing',
              style: HomeUi.sectionTitle(isDark),
            ),
            const SizedBox(height: 6),
            Text(
              'Select a model and enter investment amount to preview sector mix, asset classes, and per-holding dollar tickets.',
              textAlign: TextAlign.center,
              style: HomeUi.subtitle(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filledBriefing(bool isDark) {
    final p = preview!;
    final sorted = [...p.holdings]
      ..sort((a, b) => b.allocationPercent.compareTo(a.allocationPercent));
    final top1 = sorted.isNotEmpty ? sorted.first.allocationPercent : 0.0;
    final top3 = sorted.take(3).fold<double>(0, (s, h) => s + h.allocationPercent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('INVESTMENT BRIEFING', style: _overline(isDark)),
                    const SizedBox(height: 4),
                    Text(
                      p.modelPortfolioName,
                      style: HomeUi.sectionTitle(isDark),
                    ),
                  ],
                ),
              ),
              Text(
                money.format(p.investmentAmount),
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: HomeUi.title(isDark),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: _KpiTile(
                  isDark: isDark,
                  label: 'Holdings',
                  value: '${p.holdings.length}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiTile(
                  isDark: isDark,
                  label: 'Top position',
                  value: formatAllocationPercent(top1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiTile(
                  isDark: isDark,
                  label: 'Top 3 weight',
                  value: formatAllocationPercent(top3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiTile(
                  isDark: isDark,
                  label: 'Allocated',
                  value: formatAllocationPercent(p.totalAllocationPercent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Divider(height: 1, color: HomeUi.borderLight(isDark)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _SectionCard(
                        isDark: isDark,
                        title: 'Sector exposure',
                        subtitle: 'Industry mix of this mandate',
                        child: sectorSlices.isEmpty
                            ? Text(
                                'Sector tags unavailable for this model.',
                                style: HomeUi.subtitle(isDark),
                              )
                            : SizedBox(
                                height: 260,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: SfCircularChart(
                                        margin: EdgeInsets.zero,
                                        legend: const Legend(isVisible: false),
                                        tooltipBehavior: TooltipBehavior(
                                          enable: true,
                                          format: 'point.x : point.y%',
                                        ),
                                        series: <CircularSeries<_ChartSlice, String>>[
                                          DoughnutSeries<_ChartSlice, String>(
                                            dataSource: sectorSlices
                                                .map(
                                                  (s) => _ChartSlice(
                                                    s.label,
                                                    s.percent,
                                                    s.color,
                                                  ),
                                                )
                                                .toList(),
                                            xValueMapper: (s, _) => s.label,
                                            yValueMapper: (s, _) => s.value,
                                            pointColorMapper: (s, _) => s.color,
                                            innerRadius: '62%',
                                            radius: '95%',
                                            animationDuration: 650,
                                            dataLabelSettings:
                                                const DataLabelSettings(
                                              isVisible: false,
                                            ),
                                          ),
                                        ],
                                        annotations: <CircularChartAnnotation>[
                                          CircularChartAnnotation(
                                            widget: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${sectorSlices.length}',
                                                  style: HomeUi.control(isDark)
                                                      .copyWith(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  'sectors',
                                                  style: HomeUi.subtitle(isDark)
                                                      .copyWith(fontSize: 10),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 5,
                                      child: ListView(
                                        children: [
                                          for (final s in sectorSlices.take(6))
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration: BoxDecoration(
                                                      color: s.color,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        3,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      s.label,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: HomeUi.control(
                                                        isDark,
                                                      ).copyWith(fontSize: 11),
                                                    ),
                                                  ),
                                                  Text(
                                                    formatAllocationPercent(
                                                      s.percent,
                                                    ),
                                                    style: HomeUi.control(isDark)
                                                        .copyWith(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: _SectionCard(
                        isDark: isDark,
                        title: 'Asset-class mix',
                        subtitle: 'Equity vs alternatives',
                        child: assetSlices.isEmpty
                            ? Text(
                                'No asset-class data',
                                style: HomeUi.subtitle(isDark),
                              )
                            : SizedBox(
                                height: 260,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: SfCircularChart(
                                        margin: EdgeInsets.zero,
                                        legend: const Legend(isVisible: false),
                                        tooltipBehavior: TooltipBehavior(
                                          enable: true,
                                          format: 'point.x : point.y%',
                                        ),
                                        series: <CircularSeries<_ChartSlice, String>>[
                                          DoughnutSeries<_ChartSlice, String>(
                                            dataSource: assetSlices
                                                .map(
                                                  (s) => _ChartSlice(
                                                    s.label,
                                                    s.percent,
                                                    s.color,
                                                  ),
                                                )
                                                .toList(),
                                            xValueMapper: (s, _) => s.label,
                                            yValueMapper: (s, _) => s.value,
                                            pointColorMapper: (s, _) => s.color,
                                            innerRadius: '58%',
                                            radius: '92%',
                                            animationDuration: 650,
                                            dataLabelMapper: (s, _) =>
                                                '${s.value.toStringAsFixed(0)}%',
                                            dataLabelSettings:
                                                const DataLabelSettings(
                                              isVisible: true,
                                              labelPosition:
                                                  ChartDataLabelPosition.outside,
                                              connectorLineSettings:
                                                  ConnectorLineSettings(
                                                type: ConnectorType.curve,
                                                length: '8%',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    for (final s in assetSlices)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: s.color,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                s.label,
                                                style: HomeUi.control(isDark)
                                                    .copyWith(fontSize: 12),
                                              ),
                                            ),
                                            Text(
                                              formatAllocationPercent(s.percent),
                                              style: HomeUi.control(isDark)
                                                  .copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (sectorSlices.isNotEmpty) ...[
                  _SectionCard(
                    isDark: isDark,
                    title: 'Sector capital bars',
                    subtitle: 'Dollar weight by industry for this mandate',
                    child: SizedBox(
                      height: (48.0 + sectorSlices.length * 36)
                          .clamp(140.0, 320.0),
                      child: SfCartesianChart(
                        margin: const EdgeInsets.only(top: 8, right: 8),
                        plotAreaBorderWidth: 0,
                        primaryXAxis: CategoryAxis(
                          majorGridLines: const MajorGridLines(width: 0),
                          axisLine: const AxisLine(width: 0),
                          labelStyle: HomeUi.subtitle(isDark).copyWith(
                            fontSize: 11,
                          ),
                        ),
                        primaryYAxis: NumericAxis(
                          minimum: 0,
                          maximum: 100,
                          interval: 25,
                          axisLine: const AxisLine(width: 0),
                          majorTickLines: const MajorTickLines(size: 0),
                          labelFormat: '{value}%',
                          labelStyle: HomeUi.subtitle(isDark).copyWith(
                            fontSize: 10,
                          ),
                          majorGridLines: MajorGridLines(
                            width: 1,
                            color: HomeUi.borderLight(isDark),
                          ),
                        ),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CartesianSeries<_ChartSlice, String>>[
                          BarSeries<_ChartSlice, String>(
                            dataSource: sectorSlices
                                .map(
                                  (s) => _ChartSlice(s.label, s.percent, s.color),
                                )
                                .toList(),
                            xValueMapper: (s, _) => s.label.length > 18
                                ? '${s.label.substring(0, 16)}…'
                                : s.label,
                            yValueMapper: (s, _) => s.value,
                            pointColorMapper: (s, _) => s.color,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(4),
                            ),
                            width: 0.55,
                            animationDuration: 700,
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              textStyle: HomeUi.control(isDark).copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _SectionCard(
                  isDark: isDark,
                  title: 'Holdings ledger',
                  subtitle:
                      '${money.format(p.investmentAmount)} ticketed across ${p.holdings.length} lines',
                  child: Column(
                    children: [
                      _LedgerHeader(isDark: isDark),
                      const SizedBox(height: 6),
                      for (final h in sorted)
                        _LedgerRow(
                          isDark: isDark,
                          ticker: h.ticker,
                          company: companyFor(h),
                          sector: sectorFor(h),
                          asset: assetClassFor(h),
                          weight: h.allocationPercent,
                          amount: h.allocationAmount,
                          shares: h.quantity,
                          price: h.currentPrice,
                          money: money,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _overline(bool isDark) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: HomeUi.muted(isDark),
      );
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.isDark,
    required this.label,
    required this.value,
  });

  final bool isDark;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: HomeUi.elevatedBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: HomeUi.muted(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: HomeUi.control(isDark).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final bool isDark;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: HomeUi.elevatedBg(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: HomeUi.sectionTitle(isDark).copyWith(fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, style: HomeUi.subtitle(isDark).copyWith(fontSize: 11)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LedgerHeader extends StatelessWidget {
  const _LedgerHeader({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: HomeUi.muted(isDark),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('TICKER', style: style)),
          Expanded(flex: 3, child: Text('NAME / SECTOR', style: style)),
          SizedBox(width: 70, child: Text('WEIGHT', style: style, textAlign: TextAlign.right)),
          SizedBox(width: 90, child: Text('AMOUNT', style: style, textAlign: TextAlign.right)),
          SizedBox(width: 56, child: Text('QTY', style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.isDark,
    required this.ticker,
    required this.company,
    required this.sector,
    required this.asset,
    required this.weight,
    required this.amount,
    required this.shares,
    required this.price,
    required this.money,
  });

  final bool isDark;
  final String ticker;
  final String company;
  final String sector;
  final String asset;
  final double weight;
  final double amount;
  final double shares;
  final double price;
  final NumberFormat money;

  String get _qtyLabel {
    if (shares <= 0 && price > 0 && amount > 0) {
      final est = amount / price;
      return est >= 1 ? est.toStringAsFixed(2) : est.toStringAsFixed(4);
    }
    if (shares <= 0) return '—';
    if (shares == shares.roundToDouble()) return shares.toStringAsFixed(0);
    if (shares >= 1) return shares.toStringAsFixed(2);
    return shares.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: HomeUi.cardBg(isDark),
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
        border: Border.all(color: HomeUi.borderLight(isDark)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticker,
                  style: HomeUi.control(isDark).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  asset,
                  style: HomeUi.subtitle(isDark).copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HomeUi.control(isDark).copyWith(fontSize: 12),
                ),
                Text(
                  sector,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HomeUi.subtitle(isDark).copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              formatAllocationPercent(weight),
              textAlign: TextAlign.right,
              style: HomeUi.control(isDark).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              money.format(amount),
              textAlign: TextAlign.right,
              style: HomeUi.control(isDark).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              _qtyLabel,
              textAlign: TextAlign.right,
              style: HomeUi.subtitle(isDark).copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartSlice {
  const _ChartSlice(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}
