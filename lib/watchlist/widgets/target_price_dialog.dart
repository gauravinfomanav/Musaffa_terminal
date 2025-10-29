import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/web_service.dart';
import 'package:musaffa_terminal/watchlist/models/target_price_model.dart';
import 'dart:convert';

class TargetPriceDialog extends StatefulWidget {
  final String ticker;
  final TargetPriceModel? existingTarget;
  final Function(double price, String alertType) onSave;

  const TargetPriceDialog({
    Key? key,
    required this.ticker,
    this.existingTarget,
    required this.onSave,
  }) : super(key: key);

  @override
  State<TargetPriceDialog> createState() => _TargetPriceDialogState();
}

class _TargetPriceDialogState extends State<TargetPriceDialog> {
  final TextEditingController _priceController = TextEditingController();
  String _selectedAlertType = 'above';
  double? _currentPrice;
  bool _isLoadingPrice = true;

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
        "q": "*",
        "filter_by": "id:=[`${widget.ticker}`]",
        "per_page": "1"
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['hits'] != null && data['hits'].isNotEmpty) {
          final stockData = data['hits'][0]['document'];
          final price = stockData['currentPrice'] ?? stockData['price'] ?? 0.0;
          setState(() {
            _currentPrice = (price as num).toDouble();
            _isLoadingPrice = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching current price: $e');
      setState(() {
        _isLoadingPrice = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'SET TARGET PRICE',
                  style: DashboardTextStyles.columnHeader.copyWith(
                    color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      '×',
                      style: DashboardTextStyles.columnHeader.copyWith(
                        color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Stock Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.ticker,
                    style: DashboardTextStyles.stockName.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                    ),
                  ),
                  const Spacer(),
                  if (_isLoadingPrice)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF81AACE),
                        ),
                      ),
                    )
                  else if (_currentPrice != null)
                    Text(
                      '\$${_currentPrice!.toStringAsFixed(2)}',
                      style: DashboardTextStyles.dataCell.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                      ),
                    )
                  else
                    Text(
                      '--',
                      style: DashboardTextStyles.dataCell.copyWith(
                        fontSize: 14,
                        color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Target Price Input
            Text(
              'Target Price',
              style: DashboardTextStyles.columnHeader.copyWith(
                color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: DashboardTextStyles.dataCell.copyWith(
                fontSize: 14,
                color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
              ),
              decoration: InputDecoration(
                hintText: 'Enter target price',
                hintStyle: DashboardTextStyles.tickerSymbol.copyWith(
                  color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                prefixText: '\$ ',
                prefixStyle: DashboardTextStyles.dataCell.copyWith(
                  fontSize: 14,
                  color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF81AACE),
                    width: 1,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: Colors.red.shade400,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: Colors.red.shade400,
                    width: 1,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Alert Type Selection
            Text(
              'Alert When Price Goes',
              style: DashboardTextStyles.columnHeader.copyWith(
                color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildAlertTypeButton(
                    'above',
                    'Above Target',
                    isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAlertTypeButton(
                    'below',
                    'Below Target',
                    isDarkMode,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: DashboardTextStyles.buttonText.copyWith(
                        color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveTargetPrice,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF81AACE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.existingTarget != null ? 'Update' : 'Set Target',
                      style: DashboardTextStyles.buttonText.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTypeButton(String value, String label, bool isDarkMode) {
    final isSelected = _selectedAlertType == value;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedAlertType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF81AACE).withOpacity(0.1)
              : (isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF81AACE)
                : (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: DashboardTextStyles.buttonText.copyWith(
              color: isSelected 
                  ? const Color(0xFF81AACE)
                  : (isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151)),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  void _saveTargetPrice() {
    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      _showErrorSnackBar('Please enter a target price');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      _showErrorSnackBar('Please enter a valid target price');
      return;
    }

    // Temporarily allow same price as current price
    // TODO: Re-enable validation later
    // if (_currentPrice != null) {
    //   if (_selectedAlertType == 'above' && price <= _currentPrice!) {
    //     _showErrorSnackBar('Target price must be higher than current price (\$${_currentPrice!.toStringAsFixed(2)}) for "Above Target" alerts');
    //     return;
    //   }
    //   if (_selectedAlertType == 'below' && price >= _currentPrice!) {
    //     _showErrorSnackBar('Target price must be lower than current price (\$${_currentPrice!.toStringAsFixed(2)}) for "Below Target" alerts');
    //     return;
    //   }
    // }

    Navigator.of(context).pop();
    widget.onSave(price, _selectedAlertType);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: DashboardTextStyles.tickerSymbol.copyWith(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}