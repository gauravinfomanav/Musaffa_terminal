import 'package:flutter/material.dart';
import 'package:musaffa_terminal/financials/financials_tab/Terminal_Screens/terminal_statements_screen.dart';
import 'package:musaffa_terminal/financials/financials_tab/Terminal_Screens/terminal_ratios_screen.dart';
import 'package:musaffa_terminal/financials/financials_tab/Terminal_Screens/terminal_per_share_screen.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class TerminalFinancialsScreen extends StatefulWidget {
  final String symbol;
  final String currency;

  const TerminalFinancialsScreen({
    Key? key,
    required this.symbol,
    required this.currency,
  }) : super(key: key);

  @override
  State<TerminalFinancialsScreen> createState() => _TerminalFinancialsScreenState();
}

class _TerminalFinancialsScreenState extends State<TerminalFinancialsScreen> {
  int selectedIndex = 0;
  final List<String> buttonNames = ["Statements", "Ratios", "Per Share Data"];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Terminal-style header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFD1D5DB),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  'FINANCIAL DATA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF374151),
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.symbol,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                    color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Terminal-style tab buttons
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Row(
              children: List.generate(
                buttonNames.length,
                (index) => Expanded(
                  child: _buildTerminalTabButton(
                    buttonNames[index],
                    selectedIndex == index,
                    () => setState(() => selectedIndex = index),
                    isDarkMode,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Content area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: _buildContent(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalTabButton(String title, bool isSelected, VoidCallback onPressed, bool isDarkMode) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: Constants.FONT_DEFAULT_NEW,
            color: isSelected 
                ? Colors.white
                : (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDarkMode) {
    switch (selectedIndex) {
      case 0:
        return TerminalStatementsScreen(
          symbol: widget.symbol,
          currency: widget.currency,
        );
      case 1:
        return TerminalRatiosScreen(
          symbol: widget.symbol,
          currency: widget.currency,
        );
      case 2:
        return TerminalPerShareScreen(
          symbol: widget.symbol,
          currency: widget.currency,
        );
      default:
        return Container();
    }
  }
}
