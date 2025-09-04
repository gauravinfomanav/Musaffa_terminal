
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/components.dart/buttons.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/per_share_data_controller.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/controllers/ratios_quarterly_controller.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/screens/per_share_data_chart.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/screens/ratio_screen.dart';
import 'package:musaffa_terminal/financials/financials_tab/Data_Tables/screens/statement_screen.dart';
import 'package:musaffa_terminal/models/company_profile.dart';


class FinancialTab extends StatefulWidget {
  final CompanyProfile companyProfile;
  final String symbol;
  final String currency;

  const FinancialTab({super.key, required this.companyProfile, required this.symbol, required this.currency});

  @override
  State<FinancialTab> createState() => _FinancialTabState();
}

class _FinancialTabState extends State<FinancialTab> {
  int selectedIndex = 0;
  final controller = Get.put(FinancialFundamentalsController());

  List<String> buttonNames = ["Per Share Data", "Ratios", "Statements"];

  //quarterly ratios getting too much time to load so we are initializing it here so data get loaded fastly in ui.
  final QuarterlyRatiosController controller2 = Get.put(QuarterlyRatiosController());
  @override
  void initState() {
    super.initState();
   
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller2.fetchQuarterlyRatios(widget.symbol);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Fixed or independently scrollable buttons (using SingleChildScrollView for horizontal scrolling if needed)
        SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(buttonNames.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: finButton(
                  context: context,
                  title: buttonNames[index],
                  isSelected: selectedIndex == index,
                  onPressed: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                ),
              );
            }),
          ),
        ),
        SizedBox(height: 10),

        // Scrollable content (table) below the buttons
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (selectedIndex == 0) FinancialTable(symbol: widget.symbol),
                if (selectedIndex == 1) RatiosTable(symbol: widget.symbol),
                if (selectedIndex == 2) StatementsTable(symbol: widget.symbol),
              ],
            ),
          ),
        ),
      ],
    );
  }
}