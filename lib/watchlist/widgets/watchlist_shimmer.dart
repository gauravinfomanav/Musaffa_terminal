import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

class WatchlistShimmer {
  static Color _base(bool dark) =>
      dark ? const Color(0xFF2A2E34) : const Color(0xFFE8EAED);
  static Color _highlight(bool dark) =>
      dark ? const Color(0xFF1A1D22) : const Color(0xFFF5F6F8);

  static Widget _box(
    bool dark, {
    required double width,
    required double height,
    double radius = 4,
  }) {
    return ShimmerWidgets.box(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(radius),
      baseColor: _base(dark),
      highlightColor: _highlight(dark),
    );
  }

  /// Shimmer for the dropdown loading state
  static Widget dropdown({required bool isDarkMode}) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _box(isDarkMode, width: double.infinity, height: 16),
          ),
          const SizedBox(width: 8),
          _box(isDarkMode, width: 60, height: 24),
        ],
      ),
    );
  }

  /// Shimmer for the error retry button
  static Widget retryButton({required bool isDarkMode}) {
    return _box(isDarkMode, width: 60, height: 28);
  }

  /// Shimmer for create watchlist dialog button
  static Widget createButton({required bool isDarkMode}) {
    return _box(isDarkMode, width: 80, height: 32, radius: 6);
  }

  /// Shimmer for watchlist items
  static Widget listItem({required bool isDarkMode}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _box(isDarkMode, width: 24, height: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(isDarkMode, width: double.infinity, height: 14),
                const SizedBox(height: 6),
                _box(isDarkMode, width: 120, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _box(isDarkMode, width: 60, height: 14),
              const SizedBox(height: 4),
              _box(isDarkMode, width: 40, height: 12),
            ],
          ),
        ],
      ),
    );
  }

  /// Shimmer for loading state in main dropdown area
  static Widget loadingState({required bool isDarkMode}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _box(isDarkMode, width: 16, height: 16, radius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: _box(isDarkMode, width: double.infinity, height: 14),
          ),
        ],
      ),
    );
  }

  /// Full-card shimmer for Watchlist Performance.
  static Widget performanceCard({required bool isDarkMode}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: HomeUi.cardDecoration(isDarkMode),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(isDarkMode, width: 140, height: 13),
                const SizedBox(height: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _box(isDarkMode, width: 44, height: 10),
                                  const SizedBox(height: 5),
                                  _box(isDarkMode, width: 56, height: 13),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _box(isDarkMode, width: 44, height: 10),
                                  const SizedBox(height: 5),
                                  _box(isDarkMode, width: 56, height: 13),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _box(isDarkMode, width: 44, height: 10),
                                  const SizedBox(height: 5),
                                  _box(isDarkMode, width: 56, height: 13),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _box(isDarkMode, width: 44, height: 10),
                                  const SizedBox(height: 5),
                                  _box(isDarkMode, width: 56, height: 13),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return _box(
                  isDarkMode,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  radius: 8,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Compact value placeholder (period %, price).
  static Widget metricValue({
    required bool isDarkMode,
    bool compact = false,
  }) {
    return _box(
      isDarkMode,
      width: compact ? 52 : 64,
      height: compact ? 14 : 16,
    );
  }

  /// Mini sparkline / chart placeholder.
  static Widget sparkline({
    required bool isDarkMode,
    double width = 88,
    double height = 28,
  }) {
    return _box(isDarkMode, width: width, height: height, radius: 6);
  }

  /// Shimmer placeholder for the stock detail panel chart area.
  static Widget detailChart({required bool isDarkMode}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double chartHeight = constraints.maxHeight - 18;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: chartHeight > 0 ? chartHeight : constraints.maxHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _box(
                      isDarkMode,
                      width: double.infinity,
                      height: chartHeight > 0 ? chartHeight : 160,
                      radius: 8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _box(isDarkMode, width: 28, height: 9),
                      _box(isDarkMode, width: 28, height: 9),
                      _box(isDarkMode, width: 28, height: 9),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _box(isDarkMode, width: 32, height: 9),
                _box(isDarkMode, width: 32, height: 9),
                _box(isDarkMode, width: 32, height: 9),
                _box(isDarkMode, width: 32, height: 9),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Full-card shimmer for Market Summary.
  static Widget marketSummaryCard({required bool isDarkMode}) {
    Widget pane() {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _box(isDarkMode, width: 56, height: 10),
            const SizedBox(height: 8),
            _box(isDarkMode, width: 72, height: 14),
            const SizedBox(height: 6),
            _box(isDarkMode, width: 48, height: 12),
            const Spacer(),
            _box(isDarkMode, width: double.infinity, height: 28, radius: 6),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: HomeUi.cardDecoration(isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(isDarkMode, width: 110, height: 14),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                pane(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 1,
                    color: HomeUi.borderLight(isDarkMode),
                  ),
                ),
                pane(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Full-card shimmer for Top Movers.
  static Widget topMoversCard({required bool isDarkMode}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: HomeUi.cardDecoration(isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _box(isDarkMode, width: 140, height: 14)),
              _box(isDarkMode, width: 28, height: 18, radius: 4),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        _box(isDarkMode, width: 26, height: 26, radius: 13),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _box(
                            isDarkMode,
                            width: double.infinity,
                            height: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _box(isDarkMode, width: 52, height: 12),
                      ],
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
