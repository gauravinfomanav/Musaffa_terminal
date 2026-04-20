import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/models/portfolio_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:intl/intl.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Controllers/search_service.dart';
import 'package:musaffa_terminal/Controllers/portfolio_controller.dart';
import 'package:musaffa_terminal/web_service.dart';

const double _kFieldGap = 16.0;
const double _kSectionGap = 24.0;
const double _kCompactGap = 12.0;
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
  double? quantity;
  String? researchSource;
  int confidence; // 0-5 stars
  String? notes;
  TickerModel? tickerModel;
  double? marketCap;
  double? peRatio;

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
    this.marketCap,
    this.peRatio,
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
      quantity = allocationAmount / currentPrice!;
    }
    _calculateDerivedFields();
  }

  void updateAllocationAmount(double amount, double totalCapital) {
    allocationAmount = amount;
    allocationPercent = totalCapital > 0 ? (amount / totalCapital) * 100 : 0.0;
    if (currentPrice != null && currentPrice! > 0) {
      quantity = allocationAmount / currentPrice!;
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
    // Recalculate amount if quantity is set
    if (quantity != null && quantity! > 0 && currentPrice != null) {
      allocationAmount = currentPrice! * quantity!;
    }
  }

  void updateQuantity(double qty, double totalCapital) {
    quantity = qty;
    if (currentPrice != null && currentPrice! > 0 && qty > 0) {
      allocationAmount = currentPrice! * qty;
      allocationPercent = totalCapital > 0 ? (allocationAmount / totalCapital) * 100 : 0.0;
    } else {
      allocationAmount = 0.0;
      allocationPercent = 0.0;
    }
    _calculateDerivedFields();
  }
}

/// Comprehensive Portfolio Builder Form
class PortfolioBuilderForm extends StatefulWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onSavePortfolio;
  final Portfolio? initialPortfolio; // For editing existing portfolio

  const PortfolioBuilderForm({
    super.key,
    this.onCancel,
    this.onSaveDraft,
    this.onSavePortfolio,
    this.initialPortfolio,
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
  String _selectedBenchmark = 'US 500';
  double _capitalSliderValue = 100000;
  double _horizonSliderValue = 3;
  double _rateOfReturnValue = 12.0; // Expected rate of return in percentage (range: 1-30)

  // Section B: Holdings
  final List<PortfolioLeg> _legs = [];
  final Map<int, TextEditingController> _tickerControllers = {};
  final Map<int, TextEditingController> _companyControllers = {};
  final Map<int, TextEditingController> _targetPriceControllers = {};
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, TextEditingController> _allocationPercentControllers = {};
  final Map<int, TextEditingController> _allocationAmountControllers = {};
  final Map<int, TextEditingController> _notesControllers = {};

  // Section C: Supporting Information
  final _commentaryController = TextEditingController();

  double _totalCapital = 0.0;
  double _allocatedAmount = 0.0;
  String? _portfolioId; // Track portfolio ID when editing

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
  final List<String> _benchmarks = ['US 500', 'S&P 500', 'NASDAQ', 'Dow Jones', 'Bank Nifty', 'Custom'];
 
  @override
  void initState() {
    super.initState();
    
    // If editing, populate form with existing portfolio data
    if (widget.initialPortfolio != null) {
      _populateFormForEdit(widget.initialPortfolio!);
    } else {
      // New portfolio - set defaults
    _totalCapital = 100000.0;
    _capitalSliderValue = _totalCapital.clamp(_kMinCapital, _kMaxCapital);
      // Format initial capital value
      final formatted = NumberFormat('#,##,###', 'en_US').format(_totalCapital.toInt());
      _initialCapitalController.text = formatted;
      // Set initial rate of return
      _rateOfReturnController.text = _rateOfReturnValue.toStringAsFixed(1);
    final horizonIndex = _horizons.indexOf(_selectedHorizon);
    _horizonSliderValue =
        (horizonIndex >= 0 ? horizonIndex : 0).toDouble();
    _addLeg(); 
    }
  }

  void _populateFormForEdit(Portfolio portfolio) {
    _portfolioId = portfolio.id;
    
    // Populate text fields
    _portfolioNameController.text = portfolio.portfolioName;
    _clientNameController.text = portfolio.clientName;
    if (portfolio.clientAge != null) {
      _ageController.text = portfolio.clientAge.toString();
    }
    if (portfolio.objective != null) {
      _objectiveController.text = portfolio.objective!;
    }
    if (portfolio.commentary != null) {
      _commentaryController.text = portfolio.commentary!;
    }
    
    // Populate dropdowns
    if (portfolio.riskProfile != null && _riskProfiles.contains(portfolio.riskProfile)) {
      _selectedRiskProfile = portfolio.riskProfile!;
    }
    if (portfolio.strategyType != null && _strategies.contains(portfolio.strategyType)) {
      _selectedStrategy = portfolio.strategyType!;
    }
    if (portfolio.benchmark != null && _benchmarks.contains(portfolio.benchmark)) {
      _selectedBenchmark = portfolio.benchmark!;
    }
    if (portfolio.investmentHorizon != null && _horizons.contains(portfolio.investmentHorizon)) {
      _selectedHorizon = portfolio.investmentHorizon!;
      final horizonIndex = _horizons.indexOf(_selectedHorizon);
      _horizonSliderValue = (horizonIndex >= 0 ? horizonIndex : 0).toDouble();
    }
    
    // Populate capital and rate of return
    _totalCapital = portfolio.initialCapital;
    _capitalSliderValue = _totalCapital.clamp(_kMinCapital, _kMaxCapital);
    final formatted = NumberFormat('#,##,###', 'en_US').format(_totalCapital.toInt());
    _initialCapitalController.text = formatted;
    
    if (portfolio.expectedRateOfReturn != null) {
      _rateOfReturnValue = portfolio.expectedRateOfReturn!;
      _rateOfReturnController.text = _rateOfReturnValue.toStringAsFixed(1);
    }
    
    // Populate holdings
    _legs.clear();
    for (var controller in _tickerControllers.values) controller.dispose();
    for (var controller in _companyControllers.values) controller.dispose();
    for (var controller in _targetPriceControllers.values) controller.dispose();
    for (var controller in _quantityControllers.values) controller.dispose();
    for (var controller in _allocationPercentControllers.values) controller.dispose();
    for (var controller in _allocationAmountControllers.values) controller.dispose();
    for (var controller in _notesControllers.values) controller.dispose();
    _tickerControllers.clear();
    _companyControllers.clear();
    _targetPriceControllers.clear();
    _quantityControllers.clear();
    _allocationPercentControllers.clear();
    _allocationAmountControllers.clear();
    _notesControllers.clear();
    
    for (int i = 0; i < portfolio.holdings.length; i++) {
      final holding = portfolio.holdings[i];
      final leg = PortfolioLeg(
        ticker: holding.ticker,
        company: holding.company,
        exchange: holding.exchange,
        sector: holding.sector,
        currentPrice: holding.currentPrice,
        targetPrice: holding.targetPrice,
        quantity: holding.quantity.toDouble(),
        allocationPercent: holding.allocationPercent,
        allocationAmount: holding.allocationAmount,
        marketCap: holding.marketCap,
        peRatio: holding.peRatio,
        notes: holding.notes,
      );
      _legs.add(leg);
      
      _tickerControllers[i] = TextEditingController(text: holding.ticker);
      _companyControllers[i] = TextEditingController(text: holding.company ?? '');
      _targetPriceControllers[i] = TextEditingController(text: holding.targetPrice.toStringAsFixed(2));
      _quantityControllers[i] = TextEditingController(text: holding.quantity.toStringAsFixed(2));
      _allocationPercentControllers[i] = TextEditingController(text: holding.allocationPercent.toStringAsFixed(2));
      _allocationAmountControllers[i] = TextEditingController(text: holding.allocationAmount.toStringAsFixed(2));
      _notesControllers[i] = TextEditingController(text: holding.notes ?? '');
    }
    
    // If no holdings, add one empty leg
    if (_legs.isEmpty) {
      _addLeg();
    }
    
    _recalculateAllocations();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _ageController.dispose();
    _initialCapitalController.dispose();
    _portfolioNameController.dispose();
    _objectiveController.dispose();
    _commentaryController.dispose();
    for (var controller in _tickerControllers.values) controller.dispose();
    for (var controller in _companyControllers.values) controller.dispose();
    for (var controller in _targetPriceControllers.values) controller.dispose();
    for (var controller in _quantityControllers.values) controller.dispose();
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
      _quantityControllers[index] = TextEditingController();
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
      _quantityControllers.remove(index);
      _allocationPercentControllers.remove(index);
      _allocationAmountControllers.remove(index);
      _notesControllers.remove(index);
      
      // Reindex controllers
      final keys = _tickerControllers.keys.toList()..sort();
      final newTickerControllers = <int, TextEditingController>{};
      final newCompanyControllers = <int, TextEditingController>{};
      final newTargetPriceControllers = <int, TextEditingController>{};
      final newQuantityControllers = <int, TextEditingController>{};
      final newAllocationPercentControllers = <int, TextEditingController>{};
      final newAllocationAmountControllers = <int, TextEditingController>{};
      final newNotesControllers = <int, TextEditingController>{};
      
      for (int i = 0; i < keys.length; i++) {
        if (keys[i] > index) {
          newTickerControllers[i] = _tickerControllers[keys[i]]!;
          newCompanyControllers[i] = _companyControllers[keys[i]]!;
          newTargetPriceControllers[i] = _targetPriceControllers[keys[i]]!;
          newQuantityControllers[i] = _quantityControllers[keys[i]]!;
          newAllocationPercentControllers[i] = _allocationPercentControllers[keys[i]]!;
          newAllocationAmountControllers[i] = _allocationAmountControllers[keys[i]]!;
          newNotesControllers[i] = _notesControllers[keys[i]]!;
        } else if (keys[i] < index) {
          newTickerControllers[i] = _tickerControllers[keys[i]]!;
          newCompanyControllers[i] = _companyControllers[keys[i]]!;
          newTargetPriceControllers[i] = _targetPriceControllers[keys[i]]!;
          newQuantityControllers[i] = _quantityControllers[keys[i]]!;
          newAllocationPercentControllers[i] = _allocationPercentControllers[keys[i]]!;
          newAllocationAmountControllers[i] = _allocationAmountControllers[keys[i]]!;
          newNotesControllers[i] = _notesControllers[keys[i]]!;
        }
      }
      
      _tickerControllers.clear();
      _companyControllers.clear();
      _targetPriceControllers.clear();
      _quantityControllers.clear();
      _allocationPercentControllers.clear();
      _allocationAmountControllers.clear();
      _notesControllers.clear();
      
      _tickerControllers.addAll(newTickerControllers);
      _companyControllers.addAll(newCompanyControllers);
      _targetPriceControllers.addAll(newTargetPriceControllers);
      _quantityControllers.addAll(newQuantityControllers);
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

  // Convert PortfolioLeg to PortfolioHolding
  List<PortfolioHolding> _convertLegsToHoldings() {
    return _legs.where((leg) {
      // Only include legs with required fields
      return leg.ticker != null && 
             leg.ticker!.isNotEmpty &&
             leg.currentPrice != null && 
             leg.currentPrice! > 0 &&
             leg.targetPrice != null &&
             leg.targetPrice! > 0 &&
             leg.quantity != null &&
             leg.quantity! > 0;
    }).map((leg) {
      return PortfolioHolding(
        ticker: leg.ticker ?? '',
        company: leg.company,
        exchange: leg.exchange,
        sector: leg.sector,
        currentPrice: leg.currentPrice ?? 0.0,
        targetPrice: leg.targetPrice ?? 0.0,
        quantity: (leg.quantity ?? 0).round(), // Round to int for API
        allocationPercent: leg.allocationPercent,
        allocationAmount: leg.allocationAmount,
        marketCap: leg.marketCap,
        peRatio: leg.peRatio,
        notes: leg.notes,
      );
    }).toList();
  }

  // Save draft portfolio
  Future<void> _handleSaveDraft() async {
    final portfolioName = _portfolioNameController.text.trim();
    if (portfolioName.isEmpty) {
      SnackBarUtils.showError(context, 'Portfolio name is required');
      return;
    }

    final controller = Get.put(PortfolioController());
    final holdings = _convertLegsToHoldings();

    final portfolio = _portfolioId != null
        ? await controller.updatePortfolio(
            portfolioId: _portfolioId!,
            portfolioName: portfolioName,
            clientName: _clientNameController.text.trim().isNotEmpty 
                ? _clientNameController.text.trim() 
                : null,
            initialCapital: _totalCapital > 0 ? _totalCapital : null,
            holdings: holdings.isNotEmpty ? holdings : null,
            clientAge: _ageController.text.trim().isNotEmpty 
                ? int.tryParse(_ageController.text.trim()) 
                : null,
            riskProfile: _selectedRiskProfile,
            strategyType: _selectedStrategy,
            benchmark: _selectedBenchmark,
            objective: _objectiveController.text.trim().isNotEmpty 
                ? _objectiveController.text.trim() 
                : null,
            investmentHorizon: _selectedHorizon,
            expectedRateOfReturn: _rateOfReturnValue,
            commentary: _commentaryController.text.trim().isNotEmpty 
                ? _commentaryController.text.trim() 
                : null,
          )
        : await controller.saveDraft(
      portfolioName: portfolioName,
      clientName: _clientNameController.text.trim().isNotEmpty 
          ? _clientNameController.text.trim() 
          : null,
      initialCapital: _totalCapital > 0 ? _totalCapital : null,
      holdings: holdings.isNotEmpty ? holdings : null,
      clientAge: _ageController.text.trim().isNotEmpty 
          ? int.tryParse(_ageController.text.trim()) 
          : null,
      riskProfile: _selectedRiskProfile,
      strategyType: _selectedStrategy,
      benchmark: _selectedBenchmark,
      objective: _objectiveController.text.trim().isNotEmpty 
          ? _objectiveController.text.trim() 
          : null,
      investmentHorizon: _selectedHorizon,
      expectedRateOfReturn: _rateOfReturnValue,
      commentary: _commentaryController.text.trim().isNotEmpty 
          ? _commentaryController.text.trim() 
          : null,
    );

    if (portfolio != null) {
      // Refresh draft portfolios list
      await controller.fetchDraftPortfolios();
      SnackBarUtils.showSuccess(context, 'Draft saved successfully');
      if (widget.onSaveDraft != null) {
        widget.onSaveDraft!();
      }
    } else {
      final errorMsg = controller.saveError.value.isNotEmpty 
          ? controller.saveError.value 
          : 'Failed to save draft';
      SnackBarUtils.showError(context, errorMsg);
    }
  }

  // Save active portfolio
  Future<void> _handleSavePortfolio() async {
    final portfolioName = _portfolioNameController.text.trim();
    if (portfolioName.isEmpty) {
      SnackBarUtils.showError(context, 'Portfolio name is required');
      return;
    }

    final clientName = _clientNameController.text.trim();
    if (clientName.isEmpty) {
      SnackBarUtils.showError(context, 'Client name is required');
      return;
    }

    if (_totalCapital <= 0) {
      SnackBarUtils.showError(context, 'Initial capital must be greater than 0');
      return;
    }

    final holdings = _convertLegsToHoldings();
    if (holdings.isEmpty) {
      SnackBarUtils.showError(context, 'At least one holding is required');
      return;
    }

    final controller = Get.put(PortfolioController());
    final portfolio = _portfolioId != null
        ? await controller.updatePortfolio(
            portfolioId: _portfolioId!,
            portfolioName: portfolioName,
            clientName: clientName,
            initialCapital: _totalCapital,
            holdings: holdings,
            clientAge: _ageController.text.trim().isNotEmpty 
                ? int.tryParse(_ageController.text.trim()) 
                : null,
            riskProfile: _selectedRiskProfile,
            strategyType: _selectedStrategy,
            benchmark: _selectedBenchmark,
            objective: _objectiveController.text.trim().isNotEmpty 
                ? _objectiveController.text.trim() 
                : null,
            investmentHorizon: _selectedHorizon,
            expectedRateOfReturn: _rateOfReturnValue,
            commentary: _commentaryController.text.trim().isNotEmpty 
                ? _commentaryController.text.trim() 
                : null,
          )
        : await controller.createPortfolio(
      portfolioName: portfolioName,
      clientName: clientName,
      initialCapital: _totalCapital,
      holdings: holdings,
      clientAge: _ageController.text.trim().isNotEmpty 
          ? int.tryParse(_ageController.text.trim()) 
          : null,
      riskProfile: _selectedRiskProfile,
      strategyType: _selectedStrategy,
      benchmark: _selectedBenchmark,
      objective: _objectiveController.text.trim().isNotEmpty 
          ? _objectiveController.text.trim() 
          : null,
      investmentHorizon: _selectedHorizon,
      expectedRateOfReturn: _rateOfReturnValue,
      commentary: _commentaryController.text.trim().isNotEmpty 
          ? _commentaryController.text.trim() 
          : null,
    );

    if (portfolio != null) {
      // Refresh active portfolios list
      await controller.fetchActivePortfolios();
      SnackBarUtils.showSuccess(context, 'Portfolio saved successfully');
      if (widget.onSavePortfolio != null) {
        widget.onSavePortfolio!();
      }
    } else {
      final errorMsg = controller.saveError.value.isNotEmpty 
          ? controller.saveError.value 
          : 'Failed to save portfolio';
      SnackBarUtils.showError(context, errorMsg);
    }
  }

  void _updateRateOfReturn(String value) {
    // Allow empty value while user is typing
    if (value.isEmpty) {
      return; // Don't update anything, let user continue typing
    }
    
    final rate = double.tryParse(value);
    if (rate == null) {
      return; // Invalid input, don't update
    }
    
    final minRate = 1.0;
    final maxRate = 30.0;
    final clamped = rate.clamp(minRate, maxRate);
    
    setState(() {
      _rateOfReturnValue = clamped;
      // Only update text field if value was clamped (out of range)
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
      final formatted = NumberFormat('#,##,###', 'en_US').format(clamped.toInt());
      _initialCapitalController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
      _recalculateAllocations();
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##,###', 'en_US');
    return '\$${formatter.format(amount)}';
  }

  InputDecoration _tableFieldDecoration(bool isDark, {String hintText = '--'}) {
    final baseFill = isDark ? const Color(0xFF1B1F25) : const Color(0xFFF4F6F8);
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontSize: 11,
        color: isDark ? const Color(0xFF8B91A1) : const Color(0xFF9CA3AF),
      ),
      filled: true,
      fillColor: baseFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide.none,
      ),
    );
  }

  String _formatMarketCap(double marketCap) {
    if (marketCap >= 1000000000) {
      return '\$${(marketCap / 1000000000).toStringAsFixed(2)}B';
    } else if (marketCap >= 1000000) {
      return '\$${(marketCap / 1000000).toStringAsFixed(2)}M';
    } else if (marketCap >= 1000) {
      return '\$${(marketCap / 1000).toStringAsFixed(2)}K';
    }
    return '\$${marketCap.toStringAsFixed(2)}';
  }

  Future<void> _fetchStockData(int index, String ticker) async {
    if (ticker.isEmpty) return;
    
    try {
      final response = await WebService.getTypesense([
        'collections', 'stocks_data', 'documents', 'search'
      ], {
        'q': '*',
        'filter_by': 'id:=[`$ticker`]',
        'include_fields': 'id,usdMarketCap,peTTM',
        'per_page': '1',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final hits = (data['hits'] as List?) ?? [];
        
        if (hits.isNotEmpty) {
          final document = hits[0]['document'] as Map<String, dynamic>?;
          if (document != null) {
            setState(() {
              final marketCapValue = document['usdMarketCap'];
              final peValue = document['peTTM'];
              
              if (marketCapValue != null) {
                _legs[index].marketCap = (marketCapValue is num) 
                    ? marketCapValue.toDouble() 
                    : double.tryParse(marketCapValue.toString());
              }
              
              if (peValue != null) {
                _legs[index].peRatio = (peValue is num) 
                    ? peValue.toDouble() 
                    : double.tryParse(peValue.toString());
              }
            });
          }
        }
      }
    } catch (e) {
      // Silently handle errors
    }
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
          _buildHoldingsTableSection(isDark, borderColor),
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
                  prefixText: '\$ ',
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
                onEditingComplete: () {
                  // When user finishes editing, validate and set minimum if empty
                  if (_rateOfReturnController.text.isEmpty) {
                    setState(() {
                      _rateOfReturnValue = 1.0;
                      _rateOfReturnController.text = '1.0';
                    });
                  } else {
                    // Validate the current value
                    final rate = double.tryParse(_rateOfReturnController.text);
                    if (rate != null) {
                      final clamped = rate.clamp(1.0, 30.0);
                      if (rate != clamped) {
                        setState(() {
                          _rateOfReturnValue = clamped;
                          _rateOfReturnController.text = clamped.toStringAsFixed(1);
                        });
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRateOfReturnSliderItem(BuildContext context, bool isDark) {
    final minRate = 1.0;
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
        color: isDark ? const Color(0xFF121417) : Colors.white,
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
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0.0,
              end: percentage / 100,
            ),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                  value: animatedValue.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF1F2530) : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingsTableSection(bool isDark, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Holdings',
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
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121417) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _buildHoldingsTable(isDark),
        ),
      ],
    );
  }

  Widget _buildHoldingsTable(bool isDark) {
    if (_legs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No holdings added yet. Click "Add Stock" to get started.',
            style: TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 13,
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      );
    }

    final columns = [
      SimpleColumn(label: 'TICKER', fieldName: 'ticker', width: 120),
      SimpleColumn(label: 'COMPANY', fieldName: 'company', width: 180),
      SimpleColumn(label: 'EXCHANGE', fieldName: 'exchange', width: 100),
      SimpleColumn(label: 'CURRENT', fieldName: 'current', isNumeric: true, width: 100),
      SimpleColumn(label: 'TARGET', fieldName: 'target', isNumeric: true, width: 100),
      SimpleColumn(label: 'MKT CAP', fieldName: 'marketCap', isNumeric: true, width: 120),
      SimpleColumn(label: 'P/E', fieldName: 'peRatio', isNumeric: true, width: 100),
      SimpleColumn(label: 'ALLOC %', fieldName: 'allocPct', isNumeric: true, width: 100),
      SimpleColumn(label: 'AMOUNT', fieldName: 'amount', isNumeric: true, width: 120),
      SimpleColumn(label: 'QTY', fieldName: 'qty', isNumeric: true, width: 100),
      SimpleColumn(label: '', fieldName: 'remove', width: 60),
    ];

    final rows = _legs.asMap().entries.map((entry) {
      final index = entry.key;
      final leg = entry.value;
      return SimpleRowModel(
        symbol: leg.ticker ?? '--',
        name: leg.company ?? '--',
        logo: leg.tickerModel?.logo,
        price: leg.currentPrice,
        fields: {
          'ticker': _buildTickerSearchCell(index, isDark),
          'company': leg.company ?? '--',
          'exchange': leg.exchange ?? '--',
          'current': leg.currentPrice != null ? '\$${leg.currentPrice!.toStringAsFixed(2)}' : '--',
          'target': _buildTargetPriceCell(index, isDark),
          'marketCap': leg.marketCap != null ? _formatMarketCap(leg.marketCap!) : '--',
          'peRatio': leg.peRatio != null ? leg.peRatio!.toStringAsFixed(2) : '--',
          'allocPct': leg.allocationPercent > 0 ? '${leg.allocationPercent.toStringAsFixed(2)}%' : '--',
          'amount': leg.allocationAmount > 0 ? _formatCurrency(leg.allocationAmount) : '--',
          'qty': _buildQuantityCell(index, isDark),
          'remove': _buildRemoveButton(index, isDark),
        },
      );
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: constraints.maxWidth,
            child: DynamicTable(
              columns: columns,
              rows: rows,
              showFixedColumn: true,
              considerPadding: false,
              columnSpacing: 20,
              horizontalMargin: 0,
              fixedColumnWidth: 320,
              enableLivePrices: false,
              zebraStripes: false,
              evenRowColor: Colors.transparent,
              oddRowColor: Colors.transparent,
              enableColumnCustomization: true,
              tableId: 'portfolio_builder_holdings_table',
            ),
          ),
        );
      },
    );
  }

  Widget _buildTickerSearchCell(int index, bool isDark) {
    final leg = _legs[index];
    final hasTicker = leg.ticker != null && leg.ticker!.isNotEmpty;
    
    // If ticker is selected, show read-only text
    if (hasTicker) {
      return SizedBox(
            width: 120,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            leg.ticker ?? '--',
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
          ),
        ),
      );
    }
    
    // Otherwise show search field
    return _TickerSearchCell(
      index: index,
      isDark: isDark,
      controller: _tickerControllers[index]!,
      companyController: _companyControllers[index]!,
      onTickerSelected: (ticker) async {
                setState(() {
          _legs[index].updateTicker(ticker);
          _tickerControllers[index]!.text = ticker.symbol ?? ticker.ticker ?? '';
          _companyControllers[index]!.text = ticker.companyName ?? ticker.name ?? '';
          // If quantity is already set, recalculate allocation
          if (_legs[index].quantity != null && _legs[index].quantity! > 0) {
            _legs[index].updateQuantity(_legs[index].quantity!, _totalCapital);
            _quantityControllers[index]!.text = _legs[index].quantity!.toStringAsFixed(2);
          }
          _recalculateAllocations();
        });
        // Fetch market cap and P/E data
        await _fetchStockData(index, ticker.symbol ?? ticker.ticker ?? '');
      },
    );
  }

  Widget _buildTargetPriceCell(int index, bool isDark) {
    final leg = _legs[index];
    return SizedBox(
            width: 100,
      height: 60,
      child: Center(
            child: TextField(
          controller: _targetPriceControllers[index]!,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
          decoration: _tableFieldDecoration(isDark),
          textAlignVertical: TextAlignVertical.center,
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
    );
  }

  Widget _buildQuantityCell(int index, bool isDark) {
    final leg = _legs[index];
    return SizedBox(
            width: 100,
      height: 60,
      child: Center(
            child: TextField(
          controller: _quantityControllers[index]!,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
          decoration: _tableFieldDecoration(isDark),
          textAlignVertical: TextAlignVertical.center,
              onChanged: (value) {
            if (value.isEmpty) {
                  setState(() {
                leg.updateQuantity(0, _totalCapital);
                    _recalculateAllocations();
                  });
              return;
            }
            final qty = double.tryParse(value);
            if (qty != null && qty >= 0) {
                  setState(() {
                leg.updateQuantity(qty, _totalCapital);
                    _recalculateAllocations();
                  });
                }
              },
            ),
          ),
    );
  }

  Widget _buildRemoveButton(int index, bool isDark) {
    if (_legs.length <= 1) {
      return const SizedBox(width: 60);
    }
    return SizedBox(
            width: 60,
            child: IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              color: const Color(0xFFEF4444),
              onPressed: () => _removeLeg(index),
            ),
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
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    // Get or create controller
    final controller = Get.put(PortfolioController());
    
    return Obx(() {
      final isSaving = controller.isSaving.value;
      
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _SecondaryPillButton(
          label: 'Cancel',
          icon: Icons.close,
            onTap: isSaving ? null : widget.onCancel,
          isDarkMode: isDark,
        ),
            const SizedBox(width: _kFieldGap),
        _SecondaryPillButton(
            label: isSaving ? 'Saving...' : 'Save Draft',
            icon: isSaving ? null : Icons.save_outlined,
            onTap: isSaving ? null : _handleSaveDraft,
          isDarkMode: isDark,
        ),
        const SizedBox(width: _kFieldGap),
        _PrimaryPillButton(
            label: isSaving ? 'Saving...' : 'Save Portfolio',
            icon: isSaving ? null : Icons.check,
            onTap: isSaving ? null : _handleSavePortfolio,
          isDarkMode: isDark,
        ),
      ],
    );
    });
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
    final formatted = NumberFormat('#,##,###', 'en_US').format(number);
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

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##,###', 'en_US');
    return '\$${formatter.format(amount)}';
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

// Ticker Search Cell for Holdings Table
class _TickerSearchCell extends StatefulWidget {
  final int index;
  final bool isDark;
  final TextEditingController controller;
  final TextEditingController companyController;
  final ValueChanged<TickerModel> onTickerSelected;

  const _TickerSearchCell({
    required this.index,
    required this.isDark,
    required this.controller,
    required this.companyController,
    required this.onTickerSelected,
  });

  @override
  State<_TickerSearchCell> createState() => _TickerSearchCellState();
}

class _TickerSearchCellState extends State<_TickerSearchCell> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<TickerModel> _results = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
      _removeOverlay();
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
      _showResultsOverlay();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _isSearching = false;
      });
      _removeOverlay();
    }
  }

  void _showResultsOverlay() {
    _removeOverlay();
    if (_results.isEmpty && !_isSearching) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: 300,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF111315) : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: widget.isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB),
              ),
            ),
            child: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _results.isEmpty
                    ? const SizedBox.shrink()
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _results.length,
                        itemBuilder: (_, index) {
                          final ticker = _results[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              ticker.symbol ?? ticker.ticker ?? '',
                              style: TextStyle(
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.isDark ? Colors.white : const Color(0xFF111827),
                              ),
                            ),
                            subtitle: Text(
                              ticker.companyName ?? ticker.name ?? '',
                              style: TextStyle(
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                                fontSize: 11,
                                color: widget.isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              widget.onTickerSelected(ticker);
                              _searchController.text = ticker.symbol ?? ticker.ticker ?? '';
                              _results = [];
                              _removeOverlay();
                              _searchFocusNode.unfocus();
                              setState(() {});
                            },
                          );
                        },
                      ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final fillColor =
        widget.isDark ? const Color(0xFF1B1F25) : const Color(0xFFF4F6F8);
    return SizedBox(
      width: 120,
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onQueryChanged,
        onTap: () {
          if (_results.isNotEmpty || _isSearching) {
            _showResultsOverlay();
          }
        },
        style: TextStyle(
          fontFamily: Constants.FONT_DEFAULT_NEW,
          fontSize: 12,
          color: widget.isDark ? Colors.white : const Color(0xFF111827),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          hintText: 'Search...',
          hintStyle: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 11,
            color: widget.isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: widget.isDark
                  ? const Color(0xFF81AACE).withOpacity(0.4)
                  : const Color(0xFF3B82F6).withOpacity(0.3),
              width: 1.2,
            ),
          ),
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

