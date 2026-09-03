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
    return Container(
      decoration: HomeUi.cardDecoration(isDark),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Portfolio Analytics', style: HomeUi.sectionTitle(isDark)),
          const SizedBox(height: 4),
          Text(
            'Performance, risk, exposure & market profile',
            style: HomeUi.subtitle(isDark),
          ),
          if (totalPercent != null && totalPercent! <= 0) ...[
            const SizedBox(height: 6),
            Text(
              'Set allocation % on holdings for weighted analytics. Preview uses equal weight until then.',
              style: HomeUi.subtitle(isDark).copyWith(
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 20),
          PortfolioAnalyticsDashboard(
            isDark: isDark,
            holdings: holdings,
            benchmarkLabel: benchmarkLabel,
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
