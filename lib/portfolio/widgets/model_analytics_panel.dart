import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/portfolio/models/model_portfolio_holding.dart';
import 'package:musaffa_terminal/portfolio/services/portfolio_builder_session.dart';
import 'package:musaffa_terminal/portfolio/widgets/portfolio_analytics_dashboard.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

class ModelAnalyticsPanel extends StatelessWidget {
  const ModelAnalyticsPanel({
    super.key,
    required this.isDark,
    required this.holdings,
    this.totalPercent,
    this.benchmarkLabel = 'S&P 500',
  });

  final bool isDark;
  final List<ModelPortfolioHolding> holdings;
  final double? totalPercent;
  final String benchmarkLabel;

  @override
  Widget build(BuildContext context) {
    final needsAllocationHint = totalPercent != null && totalPercent! <= 0;

    return Container(
      decoration: HomeUi.cardDecoration(isDark),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1C1F2A),
                        HomeUi.cardBg(isDark),
                      ]
                    : [
                        const Color(0xFFFFF8F4),
                        const Color(0xFFFCFCFD),
                        Colors.white,
                      ],
              ),
              border: Border(
                bottom: BorderSide(color: HomeUi.borderLight(isDark)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeUi.tableToolbarHeader(
                  isDark,
                  title: 'Portfolio Analytics',
                  subtitleText:
                      'Performance, risk, exposure & market profile',
                  icon: Icons.insights_rounded,
                  titleFontSize: 17,
                ),
                if (needsAllocationHint) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(HomeUi.radiusMd),
                      border: Border.all(color: HomeUi.borderLight(isDark)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: HomeUi.accent(isDark),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Set allocation % on holdings for weighted analytics. Preview uses equal weight until then.',
                            style: HomeUi.subtitle(isDark).copyWith(
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: PortfolioAnalyticsDashboard(
              isDark: isDark,
              holdings: holdings,
              benchmarkLabel: benchmarkLabel,
            ),
          ),
        ],
      ),
    );
  }
}

/// Analytics panel wired to the active builder session.
class ModelAnalyticsPanelFromSession extends StatelessWidget {
  const ModelAnalyticsPanelFromSession({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final session = PortfolioBuilderSession.ensureRegistered();
    return Obx(
      () => ModelAnalyticsPanel(
        isDark: isDark,
        holdings: session.holdings.toList(),
        totalPercent: session.totalAllocationPercent,
        benchmarkLabel: session.benchmark,
      ),
    );
  }
}
