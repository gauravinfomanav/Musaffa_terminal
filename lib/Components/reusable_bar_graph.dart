import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class TerminalBarChart extends StatelessWidget {
  final String title;
  final List<BarData> data;
  final String? unit;
  final Color? barColor;
  final double height;
  final int yAxisSteps;
  final Widget? titleWidget; // Optional widget to replace the title

  const TerminalBarChart({
    Key? key,
    required this.title,
    required this.data,
    this.unit,
    this.barColor,
    this.height = 250,
    this.yAxisSteps = 5,
    this.titleWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(
            fontSize: 12,
            fontFamily: Constants.FONT_DEFAULT_NEW,
            color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      );
    }

    // Calculate max and min values
    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    
    // Determine chart range - if we have negative values, include them; otherwise start from 0
    final chartMinValue = minValue < 0 ? minValue : 0.0;
    final chartMaxValue = maxValue > 0 ? maxValue : 0.0;
    final range = chartMaxValue - chartMinValue;
    final stepSize = range / (yAxisSteps - 1);
    
    // Create Y-axis labels
    final yAxisLabels = List.generate(yAxisSteps, (index) {
      final value = chartMinValue + (stepSize * index);
      return value.toStringAsFixed(1);
    }).reversed.toList();
    
    // Default colors
    final defaultBarColor = barColor ?? (isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6));
    final axisColor = isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
    final textColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title or Title Widget
        titleWidget ?? Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: Constants.FONT_DEFAULT_NEW,
            color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
          
          // Chart Area
          SizedBox(
            height: height - 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y-axis
                SizedBox(
                  width: 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: yAxisLabels.map((label) {
                      return Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                          color: textColor,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(width: 4),
                
                // Chart with grid and bars
                Expanded(
                  child: Stack(
                    children: [
                      // Grid lines
                      ...List.generate(yAxisSteps, (index) {
                        final y = (index / (yAxisSteps - 1)) * (height - 100);
                        return Positioned(
                          top: y,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 1,
                            color: axisColor.withOpacity(0.3),
                          ),
                        );
                      }),
                      
                      // Zero line (when we have negative values)
                      if (chartMinValue < 0 && chartMaxValue > 0)
                        Positioned(
                          top: ((0 - chartMinValue) / range) * (height - 100),
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 1,
                            color: axisColor.withOpacity(0.8),
                          ),
                        ),
                      
                      // Bars
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: data.map((barData) {
                          final normalizedValue = (barData.value - chartMinValue) / range;
                          final barHeight = normalizedValue * (height - 100);
                          
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Value on top of bar
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '${barData.value.toStringAsFixed(1)}${unit ?? ''}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontFamily: Constants.FONT_DEFAULT_NEW,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              
                              // Bar with tooltip
                              Tooltip(
                                message: '${title}\n${barData.year}: ${barData.value.toStringAsFixed(2)}${unit ?? ''}',
                                textStyle: TextStyle(
                                  fontSize: 10,
                                  fontFamily: Constants.FONT_DEFAULT_NEW,
                                  color: Colors.white,
                                ),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? const Color(0xFF1F2937) : const Color(0xFF374151),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isDarkMode ? const Color(0xFF4B5563) : const Color(0xFF6B7280),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                preferBelow: false,
                                child: Container(
                                  width: 20,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    color: defaultBarColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 4),
                              
                              // Year label
                              Text(
                                barData.year,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontFamily: Constants.FONT_DEFAULT_NEW,
                                  color: textColor,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
  }
}

class BarData {
  final String year;
  final double value;

  const BarData({
    required this.year,
    required this.value,
  });
}

// Demo widget to showcase the bar chart
class BarChartDemo extends StatelessWidget {
  const BarChartDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for Revenue per Share
    final revenueData = [
      const BarData(year: '2020', value: 1.15),
      const BarData(year: '2021', value: 1.18),
      const BarData(year: '2022', value: 1.20),
      const BarData(year: '2023', value: 1.22),
      const BarData(year: '2024', value: 1.23),
    ];

    return TerminalBarChart(
      title: 'Revenue per Share',
      data: revenueData,
      unit: '',
      height: 200,
    );
  }
}
