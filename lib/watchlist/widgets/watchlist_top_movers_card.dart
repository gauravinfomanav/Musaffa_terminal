import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:musaffa_terminal/utils/utils.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_shimmer.dart';

/// Top absolute 1D movers from the current watchlist table data.
class WatchlistTopMoversCard extends StatelessWidget {
  const WatchlistTopMoversCard({
    super.key,
    required this.tableData,
    required this.isDarkMode,
    this.limit = 3,
    this.isLoading = false,
  });

  final List<SimpleRowModel> tableData;
  final bool isDarkMode;
  final int limit;
  final bool isLoading;

  double? _dayChange(SimpleRowModel row) {
    final dynamic fromField = row.fields['change1DPercent'];
    if (fromField is num) return fromField.toDouble();
    if (fromField is String) {
      return double.tryParse(fromField.replaceAll('%', '').trim());
    }
    return row.changePercent?.toDouble();
  }

  List<SimpleRowModel> _topMovers() {
    final List<SimpleRowModel> withChange = tableData
        .where((SimpleRowModel r) => _dayChange(r) != null)
        .toList();
    withChange.sort((SimpleRowModel a, SimpleRowModel b) {
      final double da = (_dayChange(a) ?? 0).abs();
      final double db = (_dayChange(b) ?? 0).abs();
      return db.compareTo(da);
    });
    if (withChange.length <= limit) return withChange;
    return withChange.sublist(0, limit);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = isDarkMode;
    final List<SimpleRowModel> movers = _topMovers();
    final bool showShimmer = isLoading || tableData.isEmpty || movers.isEmpty;

    if (showShimmer && (isLoading || tableData.isEmpty)) {
      return WatchlistShimmer.topMoversCard(isDarkMode: isDark);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: HomeUi.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Top Movers in Watchlist',
                  style: HomeUi.sectionTitle(isDark).copyWith(fontSize: 13.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: HomeUi.elevatedBg(isDark),
                  borderRadius: BorderRadius.circular(HomeUi.radiusSm),
                  border: Border.all(color: HomeUi.borderLight(isDark)),
                ),
                child: Text(
                  '1D',
                  style: HomeUi.subtitle(isDark).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: movers.isEmpty
                ? Center(
                    child: Text(
                      'No movers yet',
                      style: HomeUi.subtitle(isDark),
                    ),
                  )
                : Column(
                    children: [
                      for (int i = 0; i < movers.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        Expanded(
                          child: _MoverRow(
                            row: movers[i],
                            changePercent: _dayChange(movers[i]) ?? 0,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MoverRow extends StatelessWidget {
  const _MoverRow({
    required this.row,
    required this.changePercent,
    required this.isDark,
  });

  final SimpleRowModel row;
  final double changePercent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bool positive = changePercent >= 0;
    final Color tone =
        positive ? HomeUi.positive(isDark) : HomeUi.negative(isDark);
    final String name =
        row.name.trim().isEmpty ? row.symbol : row.name.trim();

    return Row(
      children: [
        showLogo(
          row.symbol,
          row.logo ?? '',
          sideWidth: 26,
          name: name,
          borderColor: HomeUi.borderLight(isDark),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HomeUi.sectionTitle(isDark).copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${positive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: tone,
          ),
        ),
      ],
    );
  }
}
