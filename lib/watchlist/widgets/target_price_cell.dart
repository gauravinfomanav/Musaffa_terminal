import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/watchlist/widgets/target_price_dialog.dart';

class TargetPriceCell extends StatefulWidget {
  final String ticker;

  const TargetPriceCell({
    Key? key,
    required this.ticker,
  }) : super(key: key);

  @override
  State<TargetPriceCell> createState() => _TargetPriceCellState();
}

class _TargetPriceCellState extends State<TargetPriceCell> {
  final WatchlistController _controller = Get.find<WatchlistController>();
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Obx(() {
      final targetPrice = _controller.getTargetPriceForTicker(widget.ticker);
      final isLoading = _controller.loadingTargetPricesByTicker[widget.ticker] == true;

      if (isLoading) {
        return Container(
          width: 60,
          height: 24,
          child: Center(
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF81AACE),
                ),
              ),
            ),
          ),
        );
      }

      if (targetPrice == null) {
        // No target set - show + button
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () => _showTargetPriceDialog(),
            child: Container(
              width: 60,
              height: 24,
              child: Center(
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: _isHovered 
                      ? (isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF81AACE))
                      : (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                ),
              ),
            ),
          ),
        );
      }

      // Target is set - show price with hover actions
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => _showTargetPriceDialog(targetPrice),
          child: Container(
            width: 60,
            height: 24,
            child: _isHovered
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () => _showTargetPriceDialog(targetPrice),
                        child: Icon(
                          Icons.edit,
                          size: 12,
                          color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF81AACE),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _confirmDelete(targetPrice.targetId),
                        child: Icon(
                          Icons.delete,
                          size: 12,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      '\$${targetPrice.targetPrice.toStringAsFixed(2)}',
                      style: DashboardTextStyles.dataCell.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getTargetPriceColor(targetPrice, isDarkMode),
                      ),
                    ),
                  ),
          ),
        ),
      );
    });
  }

  Color _getTargetPriceColor(targetPrice, bool isDarkMode) {
    // Color based on alert type and current price comparison
    if (targetPrice.currentPrice > 0) {
      if (targetPrice.alertType == 'above') {
        return targetPrice.currentPrice >= targetPrice.targetPrice 
            ? Colors.green.shade600 
            : (isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151));
      } else {
        return targetPrice.currentPrice <= targetPrice.targetPrice 
            ? Colors.green.shade600 
            : (isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151));
      }
    }
    return isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151);
  }

  void _showTargetPriceDialog([targetPrice]) {
    showDialog(
      context: context,
      builder: (context) => TargetPriceDialog(
        ticker: widget.ticker,
        existingTarget: targetPrice,
        onSave: (price, alertType) async {
          try {
            if (targetPrice == null) {
              await _controller.createTargetPrice(
                widget.ticker,
                price,
                alertType,
              );
              _showSuccessSnackBar('Target price set for ${widget.ticker}');
            } else {
              await _controller.updateTargetPrice(
                targetPrice.targetId,
                price,
                alertType,
              );
              _showSuccessSnackBar('Target price updated for ${widget.ticker}');
            }
          } catch (e) {
            _showErrorSnackBar('Failed to save target price: $e');
          }
        },
      ),
    );
  }

  void _confirmDelete(String targetId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1A1A1A) 
            : Colors.white,
        title: Text(
          'Delete Target Price',
          style: DashboardTextStyles.columnHeader.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete the target price for ${widget.ticker}?',
          style: DashboardTextStyles.dataCell.copyWith(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: DashboardTextStyles.buttonText.copyWith(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF9CA3AF) 
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _controller.deleteTargetPrice(targetId);
                _showSuccessSnackBar('Target price deleted for ${widget.ticker}');
              } catch (e) {
                _showErrorSnackBar('Failed to delete target price: $e');
              }
            },
            child: Text(
              'Delete',
              style: DashboardTextStyles.buttonText.copyWith(
                color: Colors.red.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    SnackBarUtils.showSuccess(context, message);
  }

  void _showErrorSnackBar(String message) {
    SnackBarUtils.showError(context, message);
  }
}