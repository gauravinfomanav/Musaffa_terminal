import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/web_service.dart';
import 'package:musaffa_terminal/watchlist/models/target_price_model.dart';

class TargetPriceDialog extends StatefulWidget {
  final String ticker;
  final TargetPriceModel? existingTarget;
  final Function(double price, String alertType) onSave;

  const TargetPriceDialog({
    super.key,
    required this.ticker,
    this.existingTarget,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String ticker,
    TargetPriceModel? existingTarget,
    required Function(double price, String alertType) onSave,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Set Target Price',
      barrierColor: Colors.black.withValues(alpha: 0.46),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: TargetPriceDialog(
              ticker: ticker,
              existingTarget: existingTarget,
              onSave: onSave,
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
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<TargetPriceDialog> createState() => _TargetPriceDialogState();
}

class _TargetPriceDialogState extends State<TargetPriceDialog> {
  final TextEditingController _priceController = TextEditingController();
  String _selectedAlertType = 'above';
  double? _currentPrice;
  bool _isLoadingPrice = true;
  String? _errorMessage;

  bool get _isEditing => widget.existingTarget != null;

  @override
  void initState() {
    super.initState();
    _loadCurrentPrice();
    if (widget.existingTarget != null) {
      _priceController.text = widget.existingTarget!.targetPrice.toString();
      _selectedAlertType = widget.existingTarget!.alertType;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPrice() async {
    try {
      final response = await WebService.getTypesense([
        'collections',
        'stocks_data',
        'documents',
        'search'
      ], {
        'q': '*',
        'filter_by': 'id:=[`${widget.ticker}`]',
        'per_page': '1'
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['hits'] != null && data['hits'].isNotEmpty) {
          final stockData = data['hits'][0]['document'];
          final price = stockData['currentPrice'] ?? stockData['price'] ?? 0.0;
          if (mounted) {
            setState(() {
              _currentPrice = (price as num).toDouble();
              _isLoadingPrice = false;
            });
          }
        } else if (mounted) {
          setState(() => _isLoadingPrice = false);
        }
      } else if (mounted) {
        setState(() => _isLoadingPrice = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingPrice = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alertLabel =
        _selectedAlertType == 'above' ? 'Above Target' : 'Below Target';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: HomeUi.tableToolbarHeader(
                      isDark,
                      icon: Icons.ads_click_rounded,
                      title: _isEditing ? 'Edit Target Price' : 'Set Target Price',
                      subtitleText:
                          'Alert when ${widget.ticker} hits your level',
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
                          border: Border.all(color: HomeUi.borderLight(isDark)),
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
              ),
            ),
            Divider(height: 1, color: HomeUi.borderLight(isDark)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeUi.detailSummaryMetricsRow(
                    dark: isDark,
                    items: [
                      (
                        label: 'Ticker',
                        value: widget.ticker,
                        valueColor: null,
                      ),
                      (
                        label: 'Current Price',
                        value: _isLoadingPrice
                            ? '…'
                            : _currentPrice != null
                                ? '\$${_currentPrice!.toStringAsFixed(2)}'
                                : '--',
                        valueColor: null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilterTextField(
                    dark: isDark,
                    label: 'Target Price',
                    controller: _priceController,
                    hintText: '0.00',
                    errorText: _errorMessage,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,4}'),
                      ),
                    ],
                    prefix: Text(
                      '\$',
                      style: HomeUi.tableCellEmphasis(isDark),
                    ),
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  FilterSegmentedSelector(
                    dark: isDark,
                    label: 'Alert When Price Goes',
                    options: const ['Above Target', 'Below Target'],
                    selected: alertLabel,
                    onChanged: (value) {
                      setState(() {
                        _selectedAlertType =
                            value == 'Above Target' ? 'above' : 'below';
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Divider(height: 1, color: HomeUi.borderLight(isDark)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: HomeUi.ghostAction(
                      label: 'Cancel',
                      dark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HomeUi.primaryAction(
                      label: _isEditing ? 'Update' : 'Set Target',
                      icon: _isEditing
                          ? Icons.check_rounded
                          : Icons.add_rounded,
                      onTap: _saveTargetPrice,
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

  void _saveTargetPrice() {
    final priceText = _priceController.text.trim();

    setState(() => _errorMessage = null);

    if (priceText.isEmpty) {
      setState(() => _errorMessage = 'Please enter a target price');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      setState(() => _errorMessage = 'Please enter a valid target price');
      return;
    }

    if (_currentPrice != null) {
      if (_selectedAlertType == 'above' && price <= _currentPrice!) {
        setState(() {
          _errorMessage =
              'Must be higher than current (\$${_currentPrice!.toStringAsFixed(2)})';
        });
        return;
      }
      if (_selectedAlertType == 'below' && price >= _currentPrice!) {
        setState(() {
          _errorMessage =
              'Must be lower than current (\$${_currentPrice!.toStringAsFixed(2)})';
        });
        return;
      }
    }

    Navigator.of(context).pop();
    widget.onSave(price, _selectedAlertType);
  }
}

class TargetPriceDeleteDialog extends StatelessWidget {
  final String ticker;

  const TargetPriceDeleteDialog({
    super.key,
    required this.ticker,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String ticker,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete Target Price',
      barrierColor: Colors.black.withValues(alpha: 0.46),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: TargetPriceDeleteDialog(ticker: ticker),
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
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: HomeUi.tableToolbarHeader(
                      isDark,
                      icon: Icons.delete_outline_rounded,
                      title: 'Delete Target Price',
                      subtitle: Text.rich(
                        TextSpan(
                          text: 'This alert will be removed from ',
                          children: [
                            TextSpan(
                              text: ticker,
                              style: HomeUi.tableCellEmphasis(isDark).copyWith(
                                fontSize: 12,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        width: HomeUi.controlHeight,
                        height: HomeUi.controlHeight,
                        decoration: BoxDecoration(
                          color: HomeUi.elevatedBg(isDark),
                          shape: BoxShape.circle,
                          border: Border.all(color: HomeUi.borderLight(isDark)),
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
              ),
            ),
            Divider(height: 1, color: HomeUi.borderLight(isDark)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  color: HomeUi.negativeSoft(isDark),
                  borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                  border: Border.all(
                    color: HomeUi.negative(isDark).withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: HomeUi.negative(isDark).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: HomeUi.negative(isDark).withValues(alpha: 0.22),
                        ),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: HomeUi.negative(isDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remove this target?',
                            style: HomeUi.tableCellEmphasis(isDark),
                          ),
                          const SizedBox(height: 4),
                          Text.rich(
                            TextSpan(
                              text:
                                  'Are you sure you want to delete the target price for ',
                              style: HomeUi.subtitle(isDark).copyWith(height: 1.4),
                              children: [
                                TextSpan(
                                  text: ticker,
                                  style: HomeUi.tableCellEmphasis(isDark).copyWith(
                                    height: 1.4,
                                  ),
                                ),
                                TextSpan(
                                  text: '? This cannot be undone.',
                                  style: HomeUi.subtitle(isDark).copyWith(height: 1.4),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Divider(height: 1, color: HomeUi.borderLight(isDark)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: HomeUi.ghostAction(
                      label: 'Cancel',
                      dark: isDark,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HomeUi.primaryAction(
                      label: 'Delete',
                      onTap: () => Navigator.of(context).pop(true),
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
}

