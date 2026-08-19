import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/ticker_eps_surprise_chart.dart';
import 'package:musaffa_terminal/Components/ticker_earnings_compact_chart.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Controllers/ticker_earnings_controller.dart';
import 'package:musaffa_terminal/models/earnings_calendar_entry.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

class TickerUpcomingEarningsCard extends StatelessWidget {
  const TickerUpcomingEarningsCard({
    super.key,
    required this.controller,
    required this.isDarkMode,
  });

  final TickerEarningsController controller;
  final bool isDarkMode;

  Widget _card({required Widget child}) {
    return SizedBox(
      height: TickerEarningsCompactChart.cardHeight,
      child: TickerFinnhubSectionCard(
        isDarkMode: isDarkMode,
        child: Align(
          alignment: Alignment.topLeft,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        final bool isLoadingCalendar = controller.isLoadingCalendar;
        final bool isLoadingSurprises = controller.isLoadingSurprises;
        final EarningsCalendarEntry? upcoming = controller.upcomingEarnings;
        final EarningsCalendarEntry? previous = controller.previousEarnings;
        final bool hasChartData = controller.chartSurprises
            .any((item) => item.surprisePercent != null);

        if (!isLoadingCalendar &&
            !isLoadingSurprises &&
            upcoming == null &&
            previous == null &&
            !hasChartData) {
          return const SizedBox.shrink();
        }

        final List<Widget> rowChildren = <Widget>[];

        if (isLoadingCalendar) {
          rowChildren.addAll(<Widget>[
            Expanded(
              flex: 8,
              child: _card(
                child: TickerFinnhubLoadingState(
                  isDarkMode: isDarkMode,
                  height: TickerEarningsCompactChart.cardHeight - 32,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 8,
              child: _card(
                child: TickerFinnhubLoadingState(
                  isDarkMode: isDarkMode,
                  height: TickerEarningsCompactChart.cardHeight - 32,
                ),
              ),
            ),
          ]);
        } else {
          if (upcoming != null) {
            rowChildren.add(
              Expanded(
                flex: 8,
                child: _card(
                  child: _buildCompactTable(
                    'Next Earnings',
                    _nextEarningsRows(upcoming),
                    isDarkMode,
                  ),
                ),
              ),
            );
          }

          if (previous != null) {
            if (rowChildren.isNotEmpty) {
              rowChildren.add(const SizedBox(width: 16));
            }
            rowChildren.add(
              Expanded(
                flex: 8,
                child: _card(
                  child: _buildCompactTable(
                    'Previous Earnings',
                    _previousEarningsRows(previous),
                    isDarkMode,
                  ),
                ),
              ),
            );
          }
        }

        if (isLoadingSurprises || hasChartData) {
          if (rowChildren.isNotEmpty) {
            rowChildren.add(const SizedBox(width: 16));
          }
          rowChildren.add(
            Expanded(
              flex: 12,
              child: TickerEpsSurpriseChart(
                surprises: controller.chartSurprises,
                isDarkMode: isDarkMode,
                isLoading: isLoadingSurprises,
              ),
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren,
        );
      },
    );
  }

  List<List<String>> _nextEarningsRows(EarningsCalendarEntry upcoming) {
    return <List<String>>[
      <String>['Date', FinnhubDisplayFormatters.formatDate(upcoming.date)],
      <String>['Quarter', upcoming.quarterLabel],
      <String>[
        'Announcement Time',
        FinnhubDisplayFormatters.formatAnnouncementHour(upcoming.hour),
      ],
      <String>[
        'EPS Estimate',
        FinnhubDisplayFormatters.formatEps(upcoming.epsEstimate),
      ],
      <String>[
        'Revenue Estimate',
        FinnhubDisplayFormatters.formatRevenue(upcoming.revenueEstimate),
      ],
      <String>[
        'Days Remaining',
        FinnhubDisplayFormatters.formatDaysRemaining(upcoming),
      ],
    ];
  }

  List<List<String>> _previousEarningsRows(EarningsCalendarEntry previous) {
    return <List<String>>[
      <String>['Date', FinnhubDisplayFormatters.formatDate(previous.date)],
      <String>['Quarter', previous.quarterLabel],
      <String>[
        'Announcement Time',
        FinnhubDisplayFormatters.formatAnnouncementHour(previous.hour),
      ],
      <String>[
        'EPS Estimate',
        FinnhubDisplayFormatters.formatEps(previous.epsEstimate),
      ],
      <String>[
        'EPS Actual',
        FinnhubDisplayFormatters.formatEps(previous.epsActual),
      ],
      <String>[
        'Revenue Estimate',
        FinnhubDisplayFormatters.formatRevenue(previous.revenueEstimate),
      ],
    ];
  }

  Widget _buildCompactTable(
    String title,
    List<List<String>> data,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        HomeUi.tableToolbarHeader(
          isDarkMode,
          icon: Icons.event_outlined,
          title: title,
        ),
        const SizedBox(height: 14),
        ...List<Widget>.generate(data.length, (int index) {
          final List<String> row = data[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    row[0],
                    style: HomeUi.tableCellSecondary(isDarkMode),
                  ),
                ),
                Text(
                  row[1],
                  style: HomeUi.tableCellEmphasis(isDarkMode),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
