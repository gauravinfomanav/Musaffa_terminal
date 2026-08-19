import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/snackbar_utils.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/watchlist/widgets/target_price_dialog.dart';

class TargetPriceCell extends StatefulWidget {
  final String ticker;

  const TargetPriceCell({
    super.key,
    required this.ticker,
  });

  @override
  State<TargetPriceCell> createState() => _TargetPriceCellState();
}

class _TargetPriceCellState extends State<TargetPriceCell> {
  final WatchlistController _controller = Get.find<WatchlistController>();
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final targetPrice = _controller.getTargetPriceForTicker(widget.ticker);
      final isLoading =
          _controller.loadingTargetPricesByTicker[widget.ticker] == true;

      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: SizedBox(
          height: 28,
          child: Align(
            alignment: Alignment.centerRight,
            child: isLoading
                ? _buildLoading(isDark)
                : targetPrice == null
                    ? _buildAddButton(isDark)
                    : _buildPriceRow(targetPrice, isDark),
          ),
        ),
      );
    });
  }

  Widget _buildLoading(bool isDark) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 1.6,
        valueColor: AlwaysStoppedAnimation<Color>(HomeUi.accent(isDark)),
      ),
    );
  }

  Widget _buildAddButton(bool isDark) {
    return GestureDetector(
      onTap: () => _showTargetPriceDialog(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: _isHovered ? HomeUi.iconWellGradient : null,
          color: _isHovered ? null : HomeUi.elevatedBg(isDark),
          borderRadius: BorderRadius.circular(HomeUi.radiusPill),
          border: Border.all(
            color: _isHovered ? HomeUi.iconWellBorder : HomeUi.borderLight(isDark),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HomeUi.brandIcon(icon: Icons.add_rounded, size: 12),
            const SizedBox(width: 4),
            Text(
              'Set',
              style: HomeUi.label(isDark).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(dynamic targetPrice, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _showTargetPriceDialog(targetPrice),
          child: Text(
            '\$${targetPrice.targetPrice.toStringAsFixed(2)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HomeUi.tableCellEmphasis(isDark).copyWith(
              fontSize: 13,
              color: _getTargetPriceColor(targetPrice, isDark),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.centerLeft,
          child: _isHovered
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TargetActionButton(
                        isDark: isDark,
                        icon: Icons.edit_outlined,
                        tooltip: 'Edit target',
                        onTap: () => _showTargetPriceDialog(targetPrice),
                      ),
                      const SizedBox(width: 4),
                      _TargetActionButton(
                        isDark: isDark,
                        icon: Icons.delete_outline_rounded,
                        tooltip: 'Delete target',
                        destructive: true,
                        onTap: () => _confirmDelete(targetPrice.targetId),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Color _getTargetPriceColor(targetPrice, bool isDark) {
    if (targetPrice.currentPrice > 0) {
      if (targetPrice.alertType == 'above') {
        return targetPrice.currentPrice >= targetPrice.targetPrice
            ? HomeUi.positive(isDark)
            : HomeUi.title(isDark);
      }
      return targetPrice.currentPrice <= targetPrice.targetPrice
          ? HomeUi.positive(isDark)
          : HomeUi.title(isDark);
    }
    return HomeUi.title(isDark);
  }

  void _showTargetPriceDialog([targetPrice]) {
    TargetPriceDialog.show(
      context: context,
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
    );
  }

  Future<void> _confirmDelete(String targetId) async {
    final confirmed = await TargetPriceDeleteDialog.show(
      context: context,
      ticker: widget.ticker,
    );
    if (confirmed != true) return;

    try {
      await _controller.deleteTargetPrice(targetId);
      if (!mounted) return;
      _showSuccessSnackBar('Target price deleted for ${widget.ticker}');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to delete target price: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    SnackBarUtils.showSuccess(context, message);
  }

  void _showErrorSnackBar(String message) {
    SnackBarUtils.showError(context, message);
  }
}

class _TargetActionButton extends StatefulWidget {
  final bool isDark;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool destructive;

  const _TargetActionButton({
    required this.isDark,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.destructive = false,
  });

  @override
  State<_TargetActionButton> createState() => _TargetActionButtonState();
}

class _TargetActionButtonState extends State<_TargetActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final destructive = widget.destructive;
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: destructive || !_hover ? null : HomeUi.iconWellGradient,
              color: destructive
                  ? HomeUi.negative(widget.isDark)
                      .withValues(alpha: _hover ? 0.16 : 0.10)
                  : _hover
                      ? null
                      : HomeUi.elevatedBg(widget.isDark),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: destructive
                    ? HomeUi.negative(widget.isDark)
                        .withValues(alpha: _hover ? 0.4 : 0.22)
                    : _hover
                        ? HomeUi.iconWellBorder
                        : HomeUi.borderLight(widget.isDark),
              ),
            ),
            child: destructive
                ? Icon(
                    widget.icon,
                    size: 13,
                    color: HomeUi.negative(widget.isDark),
                  )
                : HomeUi.brandIcon(
                    icon: widget.icon,
                    size: 13,
                  ),
          ),
        ),
      ),
    );
  }
}
