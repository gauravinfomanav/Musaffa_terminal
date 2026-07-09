import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/ticker_eps_surprise_chart.dart';
import 'package:musaffa_terminal/Components/ticker_finnhub_section_card.dart';
import 'package:musaffa_terminal/Controllers/ticker_earnings_controller.dart';
import 'package:musaffa_terminal/models/earnings_calendar_entry.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_display_formatters.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class TickerUpcomingEarningsCard extends StatelessWidget {
  const TickerUpcomingEarningsCard({
    super.key,
    required this.controller,
    required this.isDarkMode,
  });

  static const double _cardPadding = 24;
  static const double _tableHeaderHeight = 30;
  static const double _tableRowHeight = 26;

  final TickerEarningsController controller;
  final bool isDarkMode;

  static double containerHeightForRows(int rowCount) {
    return _cardPadding + _tableHeaderHeight + rowCount * _tableRowHeight;
  }

  int _maxTableRows(
    EarningsCalendarEntry? upcoming,
    EarningsCalendarEntry? previous,
  ) {
    final int nextRows = upcoming != null ? _nextEarningsRows(upcoming).length : 0;
    final int previousRows =
        previous != null ? _previousEarningsRows(previous).length : 0;
    return math.max(nextRows, previousRows);
  }

  Widget _sizedCard({
    required double height,
    required Widget child,
  }) {
    return SizedBox(
      height: height,
      child: TickerFinnhubSectionCard(
        isDarkMode: isDarkMode,
        child: Align(
          alignment: Alignment.topCenter,
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
        final int tableRows = _maxTableRows(upcoming, previous);
        final double? sharedHeight = tableRows > 0
            ? containerHeightForRows(tableRows)
            : null;

        if (isLoadingCalendar) {
          final double loadingHeight =
              sharedHeight ?? containerHeightForRows(6);
          rowChildren.addAll(<Widget>[
            Expanded(
              child: _sizedCard(
                height: loadingHeight,
                child: TickerFinnhubLoadingState(
                  isDarkMode: isDarkMode,
                  height: loadingHeight - _cardPadding,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _sizedCard(
                height: loadingHeight,
                child: TickerFinnhubLoadingState(
                  isDarkMode: isDarkMode,
                  height: loadingHeight - _cardPadding,
                ),
              ),
            ),
          ]);
        } else {
          if (upcoming != null) {
            rowChildren.add(
              Expanded(
                child: _sizedCard(
                  height: sharedHeight!,
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
                child: _sizedCard(
                  height: sharedHeight!,
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
              child: TickerEpsSurpriseChart(
                surprises: controller.chartSurprises,
                isDarkMode: isDarkMode,
                isLoading: isLoadingSurprises,
                containerHeight: sharedHeight,
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
            ),
          ),
        ),
        ...data.map(
          (List<String> row) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: (isDarkMode
                          ? const Color(0xFF404040)
                          : const Color(0xFFE5E7EB))
                      .withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  row[0],
                  style: DashboardTextStyles.tickerSymbol.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  row[1],
                  style: DashboardTextStyles.dataCell.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
