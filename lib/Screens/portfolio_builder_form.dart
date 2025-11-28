import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:intl/intl.dart';

const double _kFieldGap = 16.0;
const double _kSectionGap = 24.0;
const double _kCompactGap = 12.0;
const EdgeInsets _kFieldPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
const double _kMinCapital = 50000;
const double _kMaxCapital = 2000000;

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
  final _rateOfReturnController = TextEditingController();

  String _selectedRiskProfile = 'Moderate';
  String _selectedHorizon = '5 Years';
  String _selectedStrategy = 'Growth';
  String _selectedBenchmark = 'NIFTY 50';
  double _capitalSliderValue = 100000;
  double _horizonSliderValue = 3;
  double _rateOfReturnValue = 12.0; // Expected rate of return in percentage

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
    _totalCapital = 100000.0;
    _capitalSliderValue = _totalCapital.clamp(_kMinCapital, _kMaxCapital);
    // Format initial capital value
    final formatted = NumberFormat('#,##,###').format(_totalCapital.toInt());
    _initialCapitalController.text = formatted;
    // Set initial rate of return
    _rateOfReturnController.text = _rateOfReturnValue.toStringAsFixed(1);
    final horizonIndex = _horizons.indexOf(_selectedHorizon);
    _horizonSliderValue =
        (horizonIndex >= 0 ? horizonIndex : 0).toDouble();
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
    final cleanValue = value.replaceAll(',', '').trim();
    if (cleanValue.isEmpty) {
      setState(() {
        _totalCapital = _kMinCapital;
        _capitalSliderValue = _kMinCapital;
      });
      return;
    }
    final capital = double.tryParse(cleanValue) ?? 0.0;
    final clamped = capital.clamp(_kMinCapital, _kMaxCapital);
    setState(() {
      _totalCapital = clamped;
      _capitalSliderValue = clamped; // Update slider to exact position
      _recalculateAllocations();
    });
  }

  void _recalculateAllocations() {
    _allocatedAmount = _legs.fold(0.0, (sum, leg) => sum + leg.allocationAmount);
    setState(() {});
  }

  void _updateRateOfReturn(String value) {
    final rate = double.tryParse(value) ?? 0.0;
    final minRate = 8.0;
    final maxRate = 30.0;
    final clamped = rate.clamp(minRate, maxRate);
    setState(() {
      _rateOfReturnValue = clamped;
      // Update slider position
      if (rate != clamped) {
        _rateOfReturnController.text = clamped.toStringAsFixed(1);
      }
    });
  }

  void _onCapitalSliderChanged(double value) {
    final clamped = value.clamp(_kMinCapital, _kMaxCapital);
    setState(() {
      _capitalSliderValue = clamped;
      _totalCapital = clamped;
      // Update text field with formatted value
      final formatted = NumberFormat('#,##,###').format(clamped.toInt());
      _initialCapitalController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
      _recalculateAllocations();
    });
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
          // Sliders and Chart Container
          _buildSlidersAndChartContainer(context, isDark, borderColor),
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
        // Row 2: Portfolio Name, Strategy Type, Benchmark
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
                'Strategy Type',
                _strategies,
                _selectedStrategy,
                (value) => setState(() => _selectedStrategy = value ?? _selectedStrategy),
                isDark: isDark,
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
          ],
        ),
        const SizedBox(height: _kFieldGap),
        _buildTextField(
          _objectiveController,
          'Objective',
          isDark: isDark,
          hintText: 'Enter portfolio objective',
        ),
      ],
    );
  }

  // Calculate estimated returns using compound interest
  double _calculateEstimatedReturns() {
    final principal = _totalCapital;
    final years = _getYearsFromHorizon(_selectedHorizon);
    final rate = _rateOfReturnValue / 100;
    
    // Compound interest formula: A = P(1 + r)^t
    final totalValue = principal * math.pow(1 + rate, years);
    return totalValue - principal; // Returns only
  }

  double _getYearsFromHorizon(String horizon) {
    if (horizon.contains('6 Months')) return 0.5;
    if (horizon.contains('1 Year')) return 1.0;
    if (horizon.contains('3 Years')) return 3.0;
    if (horizon.contains('5 Years')) return 5.0;
    if (horizon.contains('7 Years')) return 7.0;
    if (horizon.contains('10 Years')) return 10.0;
    return 5.0; // Default
  }


  Widget _buildSliderItem({
    required BuildContext context,
    required bool isDark,
    required String label,
    required String value,
    required String minLabel,
    required String maxLabel,
    required double sliderValue,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF81AACE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF81AACE),
            inactiveTrackColor:
                isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB),
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayColor: const Color(0xFF81AACE).withOpacity(0.15),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            trackHeight: 4,
          ),
          child: Slider(
            value: sliderValue,
            min: min,
            max: max,
            divisions: divisions,
            label: value,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              minLabel,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 11,
                color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              ),
            ),
            Text(
              maxLabel,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 11,
                color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCapitalSliderItem(BuildContext context, bool isDark) {
    final valueLabel = _formatCurrency(_capitalSliderValue);
    final minLabel = _formatCurrency(_kMinCapital);
    final maxLabel = _formatCurrency(_kMaxCapital);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Initial Capital',
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            Text(
              valueLabel,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF81AACE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF81AACE),
            inactiveTrackColor:
                isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB),
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayColor: const Color(0xFF81AACE).withOpacity(0.15),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            trackHeight: 4,
          ),
          child: Slider(
            value: _capitalSliderValue,
            min: _kMinCapital,
            max: _kMaxCapital,
            label: valueLabel,
            onChanged: _onCapitalSliderChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              minLabel,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 11,
                color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              ),
            ),
            Text(
              maxLabel,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 11,
                color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: TextField(
                controller: _initialCapitalController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
                  _CurrencyInputFormatter(),
                ],
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  labelText: 'Enter Amount',
                  labelStyle: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  hintText: 'Enter amount',
                  hintStyle: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF2A2F33) : const Color(0xFFD1D5DB),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF2A2F33) : const Color(0xFFD1D5DB),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF81AACE), width: 1.5),
                  ),
                ),
                onChanged: _updateCapital,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _rateOfReturnController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
                style: TextStyle(
                  fontFamily: Constants.FONT_DEFAULT_NEW,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  labelText: 'Expected Rate of Return',
                  labelStyle: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                  suffixText: '%',
                  suffixStyle: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  hintText: 'e.g., 8.5',
                  hintStyle: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 12,
                    color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF2A2F33) : const Color(0xFFD1D5DB),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF2A2F33) : const Color(0xFFD1D5DB),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF81AACE), width: 1.5),
                  ),
                ),
                onChanged: _updateRateOfReturn,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRateOfReturnSliderItem(BuildContext context, bool isDark) {
    final minRate = 8.0;
    final maxRate = 30.0;
    final currentRate = _rateOfReturnValue.toStringAsFixed(1);

    return _buildSliderItem(
      context: context,
      isDark: isDark,
      label: 'Expected Rate of Return',
      value: '$currentRate %',
      minLabel: '${minRate.toStringAsFixed(0)}%',
      maxLabel: '${maxRate.toStringAsFixed(0)}%',
      sliderValue: _rateOfReturnValue,
      min: minRate,
      max: maxRate,
      divisions: ((maxRate - minRate) * 2).round(),
      onChanged: (value) {
        setState(() {
          _rateOfReturnValue = value;
          // Update text field
          _rateOfReturnController.text = value.toStringAsFixed(1);
        });
      },
    );
  }

  Widget _buildSlidersAndChartContainer(BuildContext context, bool isDark, Color borderColor) {
    final estimatedReturns = _calculateEstimatedReturns();
    final investedAmount = _totalCapital;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121417) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Sliders
          Expanded(
            flex: 1,
            child: _buildCombinedSlidersContent(context, isDark),
          ),
          const SizedBox(width: 32),
          // Right side: Chart and Legend
          Expanded(
            flex: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use container width for better responsiveness
                final availableWidth = constraints.maxWidth;
                final chartDimension = (availableWidth * 0.75).clamp(250.0, 380.0);
                
                return Center(
                  child: SizedBox(
                    width: chartDimension,
                    height: chartDimension,
                    child: _AnimatedDonutChart(
                      investedAmount: investedAmount,
                      estimatedReturns: estimatedReturns,
                      isDark: isDark,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedSlidersContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Investment Horizon
        _buildSliderItem(
          context: context,
          isDark: isDark,
          label: 'Investment Horizon',
          value: _horizons[_horizonSliderValue.round().clamp(0, _horizons.length - 1)],
          minLabel: _horizons.first,
          maxLabel: _horizons.last,
          sliderValue: _horizonSliderValue,
          min: 0,
          max: (_horizons.length - 1).toDouble(),
          divisions: _horizons.length - 1,
          onChanged: (value) {
            final index = value.round().clamp(0, _horizons.length - 1);
            setState(() {
              _horizonSliderValue = index.toDouble();
              _selectedHorizon = _horizons[index];
            });
          },
        ),
        const SizedBox(height: 24),
        // Initial Capital
        _buildCapitalSliderItem(context, isDark),
        const SizedBox(height: 24),
        // Expected Rate of Return
        _buildRateOfReturnSliderItem(context, isDark),
      ],
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
                contentPadding: _kFieldPadding,
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
                contentPadding: _kFieldPadding,
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
                contentPadding: _kFieldPadding,
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
                contentPadding: _kFieldPadding,
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
                contentPadding: _kFieldPadding,
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
        contentPadding: _kFieldPadding,
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
    final labelColor = isDark ? Colors.white : const Color(0xFF111827);
    final baseLabelStyle = TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontSize: 13,
      height: 1.2,
      color: labelColor,
    );

    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: baseLabelStyle,
      floatingLabelStyle: baseLabelStyle,
      hintStyle: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 13,
        color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF6B7280),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF2A2F33) : const Color(0xFFD1D5DB),
        ),
      ),
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
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
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

// Animated Donut Chart Widget
class _AnimatedDonutChart extends StatefulWidget {
  final double investedAmount;
  final double estimatedReturns;
  final bool isDark;

  const _AnimatedDonutChart({
    required this.investedAmount,
    required this.estimatedReturns,
    required this.isDark,
  });

  @override
  State<_AnimatedDonutChart> createState() => _AnimatedDonutChartState();
}

class _AnimatedDonutChartState extends State<_AnimatedDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Tween<double> _investedAmountTween;
  late Tween<double> _estimatedReturnsTween;
  double _previousInvestedAmount = 0;
  double _previousEstimatedReturns = 0;
  Offset? _mousePosition;
  String? _hoveredSegment;

  @override
  void initState() {
    super.initState();
    _previousInvestedAmount = widget.investedAmount;
    _previousEstimatedReturns = widget.estimatedReturns;
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _investedAmountTween = Tween<double>(
      begin: _previousInvestedAmount,
      end: widget.investedAmount,
    );
    
    _estimatedReturnsTween = Tween<double>(
      begin: _previousEstimatedReturns,
      end: widget.estimatedReturns,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.investedAmount != widget.investedAmount ||
        oldWidget.estimatedReturns != widget.estimatedReturns) {
      // Update previous values to current animated values
      _previousInvestedAmount = _investedAmountTween.evaluate(_animation);
      _previousEstimatedReturns = _estimatedReturnsTween.evaluate(_animation);
      
      // Create new tweens from current animated values to new target values
      _investedAmountTween = Tween<double>(
        begin: _previousInvestedAmount,
        end: widget.investedAmount,
      );
      
      _estimatedReturnsTween = Tween<double>(
        begin: _previousEstimatedReturns,
        end: widget.estimatedReturns,
      );
      
      // Reset and restart animation
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##,###');
    return '₹${formatter.format(amount)}';
  }

  String? _getHoveredSegment(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.85;
    final innerRadius = radius * 0.7;
    
    // Calculate distance from center
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    
    // Check if mouse is within donut ring
    if (distance < innerRadius || distance > radius) {
      return null;
    }
    
    // Calculate angle
    double angle = math.atan2(dy, dx);
    // Normalize to 0-2π range starting from top
    angle = (angle + math.pi / 2 + 2 * math.pi) % (2 * math.pi);
    
    final currentInvested = _investedAmountTween.evaluate(_animation);
    final currentReturns = _estimatedReturnsTween.evaluate(_animation);
    final total = currentInvested + currentReturns;
    
    if (total == 0) return null;
    
    final investedAngle = (currentInvested / total) * 2 * math.pi;
    
    if (angle <= investedAngle) {
      return 'invested';
    } else {
      return 'returns';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentInvested = _investedAmountTween.evaluate(_animation);
        final currentReturns = _estimatedReturnsTween.evaluate(_animation);
        
        return LayoutBuilder(
          builder: (context, constraints) {
            return MouseRegion(
              onHover: (event) {
                setState(() {
                  _mousePosition = event.localPosition;
                  _hoveredSegment = _getHoveredSegment(
                    event.localPosition,
                    Size(constraints.maxWidth, constraints.maxHeight),
                  );
                });
              },
              onExit: (event) {
                setState(() {
                  _mousePosition = null;
                  _hoveredSegment = null;
                });
              },
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _DonutChartPainter(
                      investedAmount: currentInvested,
                      estimatedReturns: currentReturns,
                      isDark: widget.isDark,
                    ),
                  ),
                  if (_hoveredSegment != null && _mousePosition != null)
                    _buildPositionedTooltip(
                      mousePosition: _mousePosition!,
                      constraints: constraints,
                      segment: _hoveredSegment!,
                      investedAmount: currentInvested,
                      estimatedReturns: currentReturns,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPositionedTooltip({
    required Offset mousePosition,
    required BoxConstraints constraints,
    required String segment,
    required double investedAmount,
    required double estimatedReturns,
  }) {
    final tooltipWidth = 140.0;
    final tooltipHeight = 60.0;
    
    // Calculate position, keeping tooltip within bounds
    double left = mousePosition.dx + 15;
    double top = mousePosition.dy - tooltipHeight / 2;
    
    // Adjust if tooltip goes outside right edge
    if (left + tooltipWidth > constraints.maxWidth) {
      left = mousePosition.dx - tooltipWidth - 15;
    }
    
    // Adjust if tooltip goes outside left edge
    if (left < 0) {
      left = 10;
    }
    
    // Adjust if tooltip goes outside top edge
    if (top < 0) {
      top = 10;
    }
    
    // Adjust if tooltip goes outside bottom edge
    if (top + tooltipHeight > constraints.maxHeight) {
      top = constraints.maxHeight - tooltipHeight - 10;
    }
    
    return Positioned(
      left: left,
      top: top,
      child: _buildTooltip(
        segment: segment,
        investedAmount: investedAmount,
        estimatedReturns: estimatedReturns,
      ),
    );
  }

  Widget _buildTooltip({
    required String segment,
    required double investedAmount,
    required double estimatedReturns,
  }) {
    final isDark = widget.isDark;
    String label;
    String value;
    Color color;
    
    if (segment == 'invested') {
      label = 'Invested Amount';
      value = _formatCurrency(investedAmount);
      color = const Color(0xFFFB923C);
    } else {
      label = 'Est. Returns';
      value = _formatCurrency(estimatedReturns);
      color = const Color(0xFF81AACE);
    }
    
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2530) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    fontSize: 11,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Donut Chart Painter
class _DonutChartPainter extends CustomPainter {
  final double investedAmount;
  final double estimatedReturns;
  final bool isDark;

  _DonutChartPainter({
    required this.investedAmount,
    required this.estimatedReturns,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.85;
    final innerRadius = radius * 0.7; // Donut hole size

    final total = investedAmount + estimatedReturns;
    if (total == 0) return;

    // Colors
    const investedColor = Color(0xFFFB923C); // Orange
    const returnsColor = Color(0xFF81AACE); // Blue
    final backgroundColor = isDark ? const Color(0xFF121417) : const Color(0xFFF4F5F7);

    double startAngle = -math.pi / 2; // Start from top

    // Draw invested amount (orange) as donut segment
    if (investedAmount > 0) {
      final investedSweep = (investedAmount / total) * 2 * math.pi;
      final investedPaint = Paint()
        ..color = investedColor
        ..style = PaintingStyle.fill;

      // Draw outer arc
      final outerRect = Rect.fromCircle(center: center, radius: radius);
      final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
      
      // Create path for donut segment
      final path = Path()
        ..arcTo(outerRect, startAngle, investedSweep, false)
        ..arcTo(innerRect, startAngle + investedSweep, -investedSweep, false)
        ..close();

      canvas.drawPath(path, investedPaint);
      startAngle += investedSweep;
    }

    // Draw estimated returns (blue) as donut segment
    if (estimatedReturns > 0) {
      final returnsSweep = (estimatedReturns / total) * 2 * math.pi;
      final returnsPaint = Paint()
        ..color = returnsColor
        ..style = PaintingStyle.fill;

      // Draw outer arc
      final outerRect = Rect.fromCircle(center: center, radius: radius);
      final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
      
      // Create path for donut segment
      final path = Path()
        ..arcTo(outerRect, startAngle, returnsSweep, false)
        ..arcTo(innerRect, startAngle + returnsSweep, -returnsSweep, false)
        ..close();

      canvas.drawPath(path, returnsPaint);
    }

    // Draw separator line between segments
    if (investedAmount > 0 && estimatedReturns > 0) {
      final borderPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final borderAngle = -math.pi / 2 + (investedAmount / total) * 2 * math.pi;
      canvas.drawLine(
        Offset(
          center.dx + math.cos(borderAngle) * innerRadius,
          center.dy + math.sin(borderAngle) * innerRadius,
        ),
        Offset(
          center.dx + math.cos(borderAngle) * radius,
          center.dy + math.sin(borderAngle) * radius,
        ),
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.investedAmount != investedAmount ||
        oldDelegate.estimatedReturns != estimatedReturns ||
        oldDelegate.isDark != isDark;
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

