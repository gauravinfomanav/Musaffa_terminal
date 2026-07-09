import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class TickerFinnhubSectionCard extends StatelessWidget {
  const TickerFinnhubSectionCard({
    super.key,
    required this.isDarkMode,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final bool isDarkMode;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class TickerFinnhubSectionTitle extends StatelessWidget {
  const TickerFinnhubSectionTitle({
    super.key,
    required this.title,
    this.fontSize = 16,
  });

  final String title;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: DashboardTextStyles.stockName.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class TickerFinnhubLoadingState extends StatelessWidget {
  const TickerFinnhubLoadingState({
    super.key,
    required this.isDarkMode,
    this.height = 120,
  });

  final bool isDarkMode;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class TickerFinnhubEmptyState extends StatelessWidget {
  const TickerFinnhubEmptyState({
    super.key,
    required this.isDarkMode,
    required this.message,
  });

  final bool isDarkMode;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: DashboardTextStyles.tickerSymbol.copyWith(
        fontSize: 12,
        color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
      ),
    );
  }
}
