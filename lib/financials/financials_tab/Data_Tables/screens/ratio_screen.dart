import 'package:flutter/material.dart';
import '../components.dart/buttons.dart';
import 'annual_ratios_chart.dart';
import 'quarterly_ratios.dart';


class RatiosTable extends StatefulWidget {
 
  final String symbol;
  
  const RatiosTable({
    super.key, 
   
    required this.symbol,
  });

  @override
  State<RatiosTable> createState() => _RatiosTableState();
}

class _RatiosTableState extends State<RatiosTable> {
  static const List<String> buttonNames = ["Annual", "Quarterly"];
  int selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Toggle buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              buttonNames.length,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: finButton(
                  context: context,
                  title: buttonNames[index],
                  isSelected: selectedIndex == index,
                  onPressed: () => setState(() => selectedIndex = index),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          
          // Content based on selected tab
          if (selectedIndex == 0)
            AnnualRatios(symbol: widget.symbol)
          else
             QuarterlyRatiosTable(symbol: widget.symbol, title: 'Financial',),
        ],
      ),
    );
  }
}