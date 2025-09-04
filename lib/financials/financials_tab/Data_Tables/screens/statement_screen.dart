import 'package:flutter/material.dart';
import 'statements_annual.dart';
import 'statements_quarterly_screen.dart';
import '../components.dart/buttons.dart';

class StatementsTable extends StatefulWidget {
  final String symbol;
  const StatementsTable({super.key, required this.symbol});

  @override
  State<StatementsTable> createState() => _StatementsTableState();
}

class _StatementsTableState extends State<StatementsTable> {
  static const List<String> buttonNames = ["Income Statement", "Balance Sheet", "Cash Flow"];
  static const List<String> periodNames = ["Annual", "Quarterly"];
  int selectedIndex = 0;  // Tracks Income Statement, Balance Sheet, Cash Flow
  int selectedPeriodIndex = 0; // Tracks Annual vs. Quarterly (default to 0 for Annual)

  // final controller = Get.put(StatementsQuarterlyIncome());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),

        // First Toggle Row (Income Statement, Balance Sheet, Cash Flow)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              buttonNames.length,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: finButton(
                  context: context,
                  title: buttonNames[index],
                  isSelected: selectedIndex == index,
                  onPressed: () => setState(() {
                    selectedIndex = index;
                  }),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Second Toggle Row (Annual, Quarterly)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(
              periodNames.length,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: finButton(
                  context: context,
                  title: periodNames[index],
                  isSelected: selectedPeriodIndex == index,
                  onPressed: () => setState(() {
                    selectedPeriodIndex = index;
                  }),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Display Selected Section (Annual or Quarterly)
        if (selectedPeriodIndex == 0) // Show Annual by default
          FinancialStatementsTable(
            reportType: selectedIndex == 0 ? 'ic' : selectedIndex == 1 ? 'bs' : 'cf',
            symbol: widget.symbol,
            title: buttonNames[selectedIndex],
          )
        else // Show Quarterly when selected
          FinancialStatementsQuarterlyTable(
            reportType: selectedIndex == 0 ? 'ic' : selectedIndex == 1 ? 'bs' : 'cf',
            symbol: widget.symbol,
            title: buttonNames[selectedIndex],
          ),
      ],
    );
  }
}