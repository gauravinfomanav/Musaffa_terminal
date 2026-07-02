import 'package:flutter/material.dart';
import 'package:musaffa_terminal/charts/models/quarterly_bar_chart_model.dart';
import 'package:musaffa_terminal/charts/widgets/quarterly_bar_chart.dart';
import 'package:musaffa_terminal/utils/constants.dart';

/// Visual preview for [QuarterlyBarChart] using screenshot mock data.
///
/// Navigate here during development:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => const QuarterlyBarChartPreviewScreen()),
/// );
/// ```
class QuarterlyBarChartPreviewScreen extends StatelessWidget {
  const QuarterlyBarChartPreviewScreen({super.key});

  static const List<QuarterDataPoint> revenueData = <QuarterDataPoint>[
    QuarterDataPoint(label: "Jun '24", value: 368.4),
    QuarterDataPoint(label: "Sep '24", value: 598.9),
    QuarterDataPoint(label: "Dec '24", value: 650.1),
    QuarterDataPoint(label: "Mar '25", value: 687.8),
    QuarterDataPoint(label: "Jun '25", value: 672.9),
    QuarterDataPoint(label: "Sep '25", value: 940.7),
    QuarterDataPoint(label: "Dec '25", value: 995.7),
    QuarterDataPoint(label: "Mar '26", value: 1213.8),
  ];

  static const List<QuarterDataPoint> operatingProfitData = <QuarterDataPoint>[
    QuarterDataPoint(label: "Jun '24", value: -128.4),
    QuarterDataPoint(label: "Sep '24", value: -139.4),
    QuarterDataPoint(label: "Dec '24", value: -140.7),
    QuarterDataPoint(label: "Mar '25", value: -172.4),
    QuarterDataPoint(label: "Jun '25", value: -134.3),
    QuarterDataPoint(label: "Sep '25", value: -132.5),
    QuarterDataPoint(label: "Dec '25", value: -72),
    QuarterDataPoint(label: "Mar '26", value: -69.6),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background =
        isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          'Quarterly Bar Chart Preview',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF0A0A0A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(
            'Variant A — Total Revenue Qtr',
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          QuarterlyBarChart(
            title: 'Total Revenue Qtr',
            displayValue: '1,213.8',
            unit: 'Cr',
            data: revenueData,
            theme: QuarterlyBarChartTheme(
              yAxisMinimum: 0,
              yAxisMaximum: 1500,
              yAxisInterval: 500,
              cardBackgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              cardBorderColor:
                  isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Variant B — Operating Profit Qtr',
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          QuarterlyBarChart(
            title: 'Operating Profit Qtr',
            displayValue: '-69.6',
            unit: 'Cr',
            data: operatingProfitData,
            theme: QuarterlyBarChartTheme(
              yAxisMinimum: -300,
              yAxisMaximum: 0,
              yAxisInterval: 100,
              cardBackgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              cardBorderColor:
                  isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            ),
          ),
        ],
      ),
    );
  }
}
