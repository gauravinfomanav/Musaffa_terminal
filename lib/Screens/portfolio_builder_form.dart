import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:intl/intl.dart';

const double _kFieldGap = 16.0;
const double _kSectionGap = 24.0;
const double _kCompactGap = 12.0;

/// Model for a portfolio leg (single stock in portfolio)
class PortfolioLeg {
  String? ticker;
  String? company;
  String? exchange;
  String? sector;
  String action;
  double? currentPrice;
  double? targetPrice;
  double? upsidePercent;
  double allocationPercent;
  double allocationAmount;
  int? quantity;
  String? researchSource;
  int confidence; // 0-5 stars
  String? notes;
  TickerModel? tickerModel;

  PortfolioLeg({
    this.ticker,
    this.company,
    this.exchange,
    this.sector,
    this.action = 'Buy',
    this.currentPrice,
    this.targetPrice,
    this.allocationPercent = 0.0,
    this.allocationAmount = 0.0,
    this.quantity,
    this.researchSource,
    this.confidence = 3,
    this.notes,
    this.tickerModel,
  }) {
    _calculateDerivedFields();
  }

  void _calculateDerivedFields() {
    if (currentPrice != null && targetPrice != null && currentPrice! > 0) {
      upsidePercent = ((targetPrice! - currentPrice!) / currentPrice!) * 100;
    } else {
      upsidePercent = null;
    }
  }

  void updateAllocationPercent(double percent, double totalCapital) {
    allocationPercent = percent;
    allocationAmount = (percent * totalCapital) / 100;
    if (currentPrice != null && currentPrice! > 0) {
      quantity = (allocationAmount / currentPrice!).round();
    }
    _calculateDerivedFields();
  }

  void updateAllocationAmount(double amount, double totalCapital) {
    allocationAmount = amount;
    allocationPercent = totalCapital > 0 ? (amount / totalCapital) * 100 : 0.0;
    if (currentPrice != null && currentPrice! > 0) {
      quantity = (allocationAmount / currentPrice!).round();
    }
    _calculateDerivedFields();
  }

  void updateTicker(TickerModel model) {
    tickerModel = model;
    ticker = model.symbol ?? model.ticker ?? '';
    company = model.companyName ?? model.name ?? '';
    exchange = model.exchange ?? '';
    sector = model.sectorname ?? '';
    currentPrice = model.currentPrice?.toDouble();
    _calculateDerivedFields();
    if (allocationPercent > 0 && currentPrice != null && currentPrice! > 0) {
      quantity = (allocationAmount / currentPrice!).round();
    }
  }
}

/// Comprehensive Portfolio Builder Form
class PortfolioBuilderForm extends StatefulWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onSavePortfolio;

  const PortfolioBuilderForm({
    super.key,
    this.onCancel,
    this.onSaveDraft,
    this.onSavePortfolio,
  });

  @override
  State<PortfolioBuilderForm> createState() => _PortfolioBuilderFormState();
}

class _PortfolioBuilderFormState extends State<PortfolioBuilderForm> {
  // Section A: Client & Goal Context
  final _clientNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _initialCapitalController = TextEditingController();
  final _portfolioNameController = TextEditingController();
  final _objectiveController = TextEditingController();

  String _selectedRiskProfile = 'Moderate';
  String _selectedHorizon = '5 Years';
  String _selectedStrategy = 'Growth';
  String _selectedBenchmark = 'NIFTY 50';

  // Section B: Holdings
  final List<PortfolioLeg> _legs = [];
  final Map<int, TextEditingController> _tickerControllers = {};
  final Map<int, TextEditingController> _companyControllers = {};
  final Map<int, TextEditingController> _targetPriceControllers = {};
  final Map<int, TextEditingController> _allocationPercentControllers = {};
  final Map<int, TextEditingController> _allocationAmountControllers = {};
  final Map<int, TextEditingController> _notesControllers = {};

  // Section C: Supporting Information
  final _commentaryController = TextEditingController();
  final _referenceDocsController = TextEditingController();

  double _totalCapital = 0.0;
  double _allocatedAmount = 0.0;

  final List<String> _riskProfiles = [
    'Conservative',
    'Moderate',
    'Aggressive',
    'Tactical',
    'Income',
    'Balanced',
  ];
  final List<String> _horizons = ['6 Months', '1 Year', '3 Years', '5 Years', '7 Years', '10 Years'];
  final List<String> _strategies = ['Growth', 'Value', 'Dividend', 'Thematic', 'Balanced'];
  final List<String> _benchmarks = ['NIFTY 50', 'Bank Nifty', 'S&P 500', 'Custom'];
 
  @override
  void initState() {
    super.initState();
    _initialCapitalController.text = '100000';
    _totalCapital = 100000.0;
    _addLeg(); 
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _ageController.dispose();
    _initialCapitalController.dispose();
    _portfolioNameController.dispose();
    _objectiveController.dispose();
    _commentaryController.dispose();
    _referenceDocsController.dispose();
    for (var controller in _tickerControllers.values) controller.dispose();
    for (var controller in _companyControllers.values) controller.dispose();
    for (var controller in _targetPriceControllers.values) controller.dispose();
    for (var controller in _allocationPercentControllers.values) controller.dispose();
    for (var controller in _allocationAmountControllers.values) controller.dispose();
    for (var controller in _notesControllers.values) controller.dispose();
    super.dispose();
  }

  void _addLeg() {
    setState(() {
      final index = _legs.length;
      _legs.add(PortfolioLeg());
      _tickerControllers[index] = TextEditingController();
      _companyControllers[index] = TextEditingController();
      _targetPriceControllers[index] = TextEditingController();
      _allocationPercentControllers[index] = TextEditingController();
      _allocationAmountControllers[index] = TextEditingController();
      _notesControllers[index] = TextEditingController();
    });
  }

  void _removeLeg(int index) {
    if (_legs.length <= 1) return; 
    setState(() {
      _legs.removeAt(index);
      _tickerControllers.remove(index);
      _companyControllers.remove(index);
      _targetPriceControllers.remove(index);
      _allocationPercentControllers.remove(index);
      _allocationAmountControllers.remove(index);
      _notesControllers.remove(index);
      
      final keys = _tickerControllers.keys.toList()..sort();
      final newTickerControllers = <int, TextEditingController>{};
      final newCompanyControllers = <int, TextEditingController>{};
      final newTargetPriceControllers = <int, TextEditingController>{};
      final newAllocationPercentControllers = <int, TextEditingController>{};
      final newAllocationAmountControllers = <int, TextEditingController>{};
      final newNotesControllers = <int, TextEditingController>{};
      for (int i = 0; i < keys.length; i++) {
        if (keys[i] > index) {
          newTickerControllers[i] = _tickerControllers[keys[i]]!;
          newCompanyControllers[i] = _companyControllers[keys[i]]!;
          newTargetPriceControllers[i] = _targetPriceControllers[keys[i]]!;
          newAllocationPercentControllers[i] = _allocationPercentControllers[keys[i]]!;
          newAllocationAmountControllers[i] = _allocationAmountControllers[keys[i]]!;
          newNotesControllers[i] = _notesControllers[keys[i]]!;
        } else if (keys[i] < index) {
          newTickerControllers[i] = _tickerControllers[keys[i]]!;
          newCompanyControllers[i] = _companyControllers[keys[i]]!;
          newTargetPriceControllers[i] = _targetPriceControllers[keys[i]]!;
          newAllocationPercentControllers[i] = _allocationPercentControllers[keys[i]]!;
          newAllocationAmountControllers[i] = _allocationAmountControllers[keys[i]]!;
          newNotesControllers[i] = _notesControllers[keys[i]]!;
        }
      }
      _tickerControllers.clear();
      _companyControllers.clear();
      _targetPriceControllers.clear();
      _allocationPercentControllers.clear();
      _allocationAmountControllers.clear();
      _notesControllers.clear();
      _tickerControllers.addAll(newTickerControllers);
      _companyControllers.addAll(newCompanyControllers);
      _targetPriceControllers.addAll(newTargetPriceControllers);
      _allocationPercentControllers.addAll(newAllocationPercentControllers);
      _allocationAmountControllers.addAll(newAllocationAmountControllers);
      _notesControllers.addAll(newNotesControllers);
      _recalculateAllocations();
    });
  }

  void _updateCapital(String value) {
    final capital = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    setState(() {
      _totalCapital = capital;
      _recalculateAllocations();
    });
  }

  void _recalculateAllocations() {
    _allocatedAmount = _legs.fold(0.0, (sum, leg) => sum + leg.allocationAmount);
    setState(() {});
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##,###');
    return '₹${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB);
    final cardColor = isDark ? const Color(0xFF151718) : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section A: Client & Goal Context
          _buildSectionA(isDark, borderColor),
          const SizedBox(height: 24),
          // Allocation Progress Bar
          _buildAllocationProgressBar(isDark),
          const SizedBox(height: 24),
          // Section B: Holdings Table
          _buildSectionB(isDark, borderColor),
          const SizedBox(height: 24),
          // Section C: Supporting Information
          _buildSectionC(isDark, borderColor),
          const SizedBox(height: 24),
          // Action Buttons
          _buildActionButtons(isDark),
        ],
      ),
    );
  }

  Widget _buildSectionA(bool isDark, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client & Goal Context',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: _kSectionGap),
        // Row 1: Client Name, Age, Risk Profile
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _clientNameController,
                'Client Name/ID',
                isDark: isDark,
                hintText: 'Enter client name or ID',
              ),
            ),
            const SizedBox(width: _kFieldGap),
            Expanded(
              flex: 0,
              child: SizedBox(
                width: 100,
                child: _buildTextField(
                  _ageController,
                  'Age',
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  hintText: '--',
                ),
              ),
            ),
            const SizedBox(width: _kFieldGap),
            Expanded(
              child: _buildPillSelector(
                'Risk Profile',
                _riskProfiles,
                _selectedRiskProfile,
                (value) => setState(() => _selectedRiskProfile = value),
                isDark: isDark,
                showLabel: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: _kFieldGap),
        // Row 2: Investment Horizon, Initial Capital, Strategy
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                'Investment Horizon',
                _horizons,
                _selectedHorizon,
                (value) => setState(() => _selectedHorizon = value ?? _selectedHorizon),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: _kFieldGap),
            Expanded(
              child: _buildCapitalInput(isDark),
            ),
            const SizedBox(width: _kFieldGap),
            Expanded(
              child: _buildDropdown(
                'Strategy Type',
                _strategies,
                _selectedStrategy,
                (value) => setState(() => _selectedStrategy = value ?? _selectedStrategy),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: _kFieldGap),
        // Row 3: Portfolio Name, Benchmark, Objective
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _portfolioNameController,
                'Portfolio Name',
                isDark: isDark,
                hintText: 'e.g., AI Acceleration Basket',
              ),
            ),
            const SizedBox(width: _kFieldGap),
            Expanded(
              child: _buildDropdown(
                'Benchmark',
                _benchmarks,
                _selectedBenchmark,
                (value) => setState(() => _selectedBenchmark = value ?? _selectedBenchmark),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: _kFieldGap),
            Expanded(
              child: _buildTextField(
                _objectiveController,
                'Objective',
                isDark: isDark,
                hintText: 'Enter portfolio objective',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCapitalInput(bool isDark) {
    return TextField(
      controller: _initialCapitalController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
        _CurrencyInputFormatter(),
      ],
      onChanged: (value) => _updateCapital(value),
      decoration: _fieldDecoration(
        'Initial Capital',
        hintText: 'Enter amount',
        isDark: isDark,
      ).copyWith(
        prefixText: '₹ ',
        prefixStyle: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF111827),
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 13,
        ),
      ),
      style: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 13,
        color: isDark ? Colors.white : const Color(0xFF111827),
      ),
    );
  }

  Widget _buildAllocationProgressBar(bool isDark) {
    final percentage = _totalCapital > 0 ? (_allocatedAmount / _totalCapital * 100) : 0.0;
    final isComplete = (percentage - 100.0).abs() < 0.01;
    final progressColor = isComplete
        ? const Color(0xFF10B981)
        : percentage > 100
            ? const Color(0xFFEF4444)
            : const Color(0xFF81AACE);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121417) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Allocation Progress',
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              Text(
                '${_formatCurrency(_allocatedAmount)} / ${_formatCurrency(_totalCapital)} (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: progressColor,
                ),
              ),
            ],
          ),
        const SizedBox(height: _kCompactGap),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF1F2530) : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionB(bool isDark, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Holdings Table',
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            _SecondaryPillButton(
              label: 'Add Stock',
              icon: Icons.add,
              onTap: _addLeg,
              isDarkMode: isDark,
            ),
          ],
        ),
        const SizedBox(height: _kSectionGap),
        // Scrollable table with all columns
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121417) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildHoldingsTable(isDark, borderColor),
          ),
        ),
      ],
    );
  }

  Widget _buildHoldingsTable(bool isDark, Color borderColor) {
    const columnWidths = {
      'ticker': 120.0,
      'company': 180.0,
      'exchange': 100.0,
      'sector': 120.0,
      'action': 100.0,
      'current': 100.0,
      'target': 100.0,
      'upside': 100.0,
      'allocation_pct': 100.0,
      'amount': 120.0,
      'qty': 100.0,
      'source': 100.0,
      'confidence': 120.0,
      'notes': 150.0,
      'remove': 60.0,
    };

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        isDark ? const Color(0xFF1F2530) : const Color(0xFFE5E7EB),
      ),
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return isDark ? const Color(0xFF2A2F33) : const Color(0xFFF3F4F6);
        }
        return Colors.transparent;
      }),
      headingTextStyle: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF111827),
      ),
      dataTextStyle: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 12,
        color: isDark ? Colors.white : const Color(0xFF111827),
      ),
      columns: [
        _buildDataColumn('Ticker', columnWidths['ticker']!),
        _buildDataColumn('Company', columnWidths['company']!),
        _buildDataColumn('Exchange', columnWidths['exchange']!),
        _buildDataColumn('Sector', columnWidths['sector']!),
        _buildDataColumn('Action', columnWidths['action']!),
        _buildDataColumn('Current', columnWidths['current']!),
        _buildDataColumn('Target', columnWidths['target']!),
        _buildDataColumn('Upside %', columnWidths['upside']!),
        _buildDataColumn('Alloc %', columnWidths['allocation_pct']!),
        _buildDataColumn('Amount (₹)', columnWidths['amount']!),
        _buildDataColumn('Qty', columnWidths['qty']!),
        _buildDataColumn('Source', columnWidths['source']!),
        _buildDataColumn('Confidence', columnWidths['confidence']!),
        _buildDataColumn('Notes', columnWidths['notes']!),
        _buildDataColumn('', columnWidths['remove']!),
      ],
      rows: List.generate(_legs.length, (index) {
        return _buildHoldingsRow(index, isDark);
      }),
    );
  }

  DataColumn _buildDataColumn(String label, double width) {
    return DataColumn(
      label: SizedBox(
        width: width,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  DataRow _buildHoldingsRow(int index, bool isDark) {
    final leg = _legs[index];
    final actions = ['Buy', 'Hold', 'Sell', 'Reduce'];
    final sources = ['ICICI', 'HDFC', 'Axis', 'Morgan Stanley', 'Custom'];

    return DataRow(
      cells: [
        // Ticker - Search field (compact)
        DataCell(
          SizedBox(
            width: 120,
            child: _buildCompactTickerSearch(index, isDark),
          ),
        ),
        // Company
        DataCell(
          SizedBox(
            width: 180,
            child: TextField(
              controller: _companyControllers[index],
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                hintText: '--',
                hintStyle: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 11,
                  color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF81AACE), width: 1.5),
                ),
              ),
            ),
          ),
        ),
        // Exchange - Badge
        DataCell(
          SizedBox(
            width: 100,
            child: _buildBadge(leg.exchange ?? '--', isDark),
          ),
        ),
        // Sector
        DataCell(
          SizedBox(
            width: 120,
            child: Text(
              leg.sector ?? '--',
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
        // Action - Dropdown
        DataCell(
          SizedBox(
            width: 100,
            child: DropdownButton<String>(
              value: leg.action,
              isDense: true,
              isExpanded: true,
              underline: const SizedBox(),
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
              items: actions.map((action) {
                return DropdownMenuItem(
                  value: action,
                  child: _buildActionBadge(action, isDark),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  leg.action = value ?? 'Buy';
                });
              },
            ),
          ),
        ),
        // Current Price
        DataCell(
          SizedBox(
            width: 100,
            child: Text(
              leg.currentPrice != null ? '₹${leg.currentPrice!.toStringAsFixed(2)}' : '--',
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
        // Target Price - Editable
        DataCell(
          SizedBox(
            width: 100,
            child: TextField(
              controller: _targetPriceControllers[index],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                hintText: '--',
                hintStyle: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 11,
                  color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF81AACE), width: 1.5),
                ),
              ),
              onChanged: (value) {
                final price = double.tryParse(value);
                if (price != null) {
                  setState(() {
                    leg.targetPrice = price;
                    leg._calculateDerivedFields();
                  });
                }
              },
            ),
          ),
        ),
        // Upside % - Auto-calculated
        DataCell(
          SizedBox(
            width: 100,
            child: Text(
              leg.upsidePercent != null
                  ? '${leg.upsidePercent! >= 0 ? '+' : ''}${leg.upsidePercent!.toStringAsFixed(2)}%'
                  : '--',
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                color: leg.upsidePercent != null && leg.upsidePercent! >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
          ),
        ),
        // Allocation % - Editable
        DataCell(
          SizedBox(
            width: 100,
            child: TextField(
              controller: _allocationPercentControllers[index],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                hintText: '--',
                hintStyle: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 11,
                  color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                ),
                suffixText: '%',
                suffixStyle: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 10,
                  color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF81AACE), width: 1.5),
                ),
              ),
              onChanged: (value) {
                final percent = double.tryParse(value);
                if (percent != null) {
                  setState(() {
                    leg.updateAllocationPercent(percent, _totalCapital);
                    _recalculateAllocations();
                  });
                }
              },
            ),
          ),
        ),
        // Amount (₹) - Auto-calculated or editable
        DataCell(
          SizedBox(
            width: 120,
            child: TextField(
              controller: _allocationAmountControllers[index],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                hintText: '--',
                hintStyle: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 11,
                  color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                ),
                prefixText: '₹ ',
                prefixStyle: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 10,
                  color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF81AACE), width: 1.5),
                ),
              ),
              onChanged: (value) {
                final amount = double.tryParse(value);
                if (amount != null) {
                  setState(() {
                    leg.updateAllocationAmount(amount, _totalCapital);
                    _recalculateAllocations();
                  });
                }
              },
            ),
          ),
        ),
        // Quantity - Auto-calculated
        DataCell(
          SizedBox(
            width: 100,
            child: Text(
              leg.quantity?.toString() ?? '--',
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
        // Source - Dropdown
        DataCell(
          SizedBox(
            width: 100,
            child: DropdownButton<String>(
              value: leg.researchSource ?? sources.first,
              isDense: true,
              isExpanded: true,
              underline: const SizedBox(),
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
              items: sources.map((source) {
                return DropdownMenuItem(
                  value: source,
                  child: _buildBadge(source, isDark),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  leg.researchSource = value;
                });
              },
            ),
          ),
        ),
        // Confidence - Star rating
        DataCell(
          SizedBox(
            width: 120,
            child: _buildStarRating(index, isDark),
          ),
        ),
        // Notes
        DataCell(
          SizedBox(
            width: 150,
            child: TextField(
              controller: _notesControllers[index],
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                hintText: '--',
                hintStyle: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 11,
                  color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF81AACE), width: 1.5),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  leg.notes = value;
                });
              },
            ),
          ),
        ),
        // Remove button
        DataCell(
          SizedBox(
            width: 60,
            child: IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              color: const Color(0xFFEF4444),
              onPressed: () => _removeLeg(index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTickerSearch(int index, bool isDark) {
    // This will be a compact version - for now using simple text field
    // Full ticker search can be implemented later
    return TextField(
      controller: _tickerControllers[index],
      style: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 12,
        height: 1.2,
        color: isDark ? Colors.white : const Color(0xFF111827),
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        hintText: '--',
        hintStyle: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 11,
          color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF81AACE), width: 1.5),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _legs[index].ticker = value;
        });
      },
    );
  }

  Widget _buildBadge(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2530) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 11,
          color: isDark ? Colors.white70 : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildActionBadge(String action, bool isDark) {
    Color color;
    switch (action.toLowerCase()) {
      case 'buy':
        color = const Color(0xFF10B981);
        break;
      case 'sell':
      case 'reduce':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = const Color(0xFFEAB308);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        action,
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStarRating(int index, bool isDark) {
    final leg = _legs[index];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (starIndex) {
        return GestureDetector(
          onTap: () {
            setState(() {
              leg.confidence = starIndex + 1;
            });
          },
          child: Icon(
            starIndex < leg.confidence ? Icons.star : Icons.star_border,
            size: 16,
            color: starIndex < leg.confidence
                ? const Color(0xFFFCD34D)
                : (isDark ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF)),
          ),
        );
      }),
    );
  }

  Widget _buildSectionC(bool isDark, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Supporting Information',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: _kSectionGap),
        TextField(
          controller: _commentaryController,
          maxLines: 4,
          decoration: _fieldDecoration(
            'Supporting Commentary',
            hintText: 'Enter rationale, key points, or market outlook...',
            isDark: isDark,
          ),
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 13,
            height: 1.2,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: _kFieldGap),
        TextField(
          controller: _referenceDocsController,
          maxLines: 2,
          decoration: _fieldDecoration(
            'Reference Documents (comma or newline separated)',
            hintText: 'https://example.com/report1.pdf, https://example.com/report2.pdf',
            isDark: isDark,
          ),
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 13,
            height: 1.2,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _SecondaryPillButton(
          label: 'Cancel',
          icon: Icons.close,
          onTap: widget.onCancel,
          isDarkMode: isDark,
        ),
            const SizedBox(width: _kFieldGap),
        _SecondaryPillButton(
          label: 'Save Draft',
          icon: Icons.save_outlined,
          onTap: widget.onSaveDraft,
          isDarkMode: isDark,
        ),
        const SizedBox(width: _kFieldGap),
        _PrimaryPillButton(
          label: 'Save Portfolio',
          icon: Icons.check,
          onTap: widget.onSavePortfolio,
          isDarkMode: isDark,
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String label, {String? hintText, bool isDark = false}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: const TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 13,
        height: 1.2,
      ),
      hintStyle: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 13,
        color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF81AACE), width: 1.5),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: _fieldDecoration(label, hintText: hintText, isDark: isDark),
      style: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 13,
        height: 1.2,
        color: isDark ? Colors.white : const Color(0xFF111827),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String selected,
    ValueChanged<String?> onChanged, {
    required bool isDark,
  }) {
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: _fieldDecoration(label, isDark: isDark),
      dropdownColor: isDark ? const Color(0xFF111315) : Colors.white,
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(
          item,
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
      )).toList(),
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 13,
        height: 1.2,
        color: isDark ? Colors.white : const Color(0xFF111827),
      ),
    );
  }

  Widget _buildPillSelector(
    String label,
    List<String> options,
    String selected,
    ValueChanged<String> onChanged, {
    required bool isDark,
    bool showLabel = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            label,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 12,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        const SizedBox(height: _kCompactGap),
        ],
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = option == selected;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF81AACE) : const Color(0xFF3B82F6))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? const Color(0xFF81AACE) : const Color(0xFF3B82F6))
                        : (isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB)),
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF111827)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final cleanText = newValue.text.replaceAll(',', '');
    if (cleanText.isEmpty) return newValue;
    final number = int.tryParse(cleanText);
    if (number == null) return oldValue;
    final formatted = NumberFormat('#,##,###').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
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
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
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
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
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

