import 'package:flutter/material.dart';
import 'package:musaffa_terminal/charts/custom/widgets/premium_finance_chart_showcase.dart';
import 'package:musaffa_terminal/charts/custom/widgets/premium_market_loader.dart';

/// Custom Charts tab — premium loader → charts showcase.
class TickerCustomChartsTabContent extends StatefulWidget {
  const TickerCustomChartsTabContent({super.key});

  @override
  State<TickerCustomChartsTabContent> createState() =>
      _TickerCustomChartsTabContentState();
}

class _TickerCustomChartsTabContentState
    extends State<TickerCustomChartsTabContent> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 3600), () {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _loaded
          ? Scrollbar(
              key: const ValueKey<String>('charts'),
              thumbVisibility: true,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: const PremiumFinanceChartShowcase(),
              ),
            )
          : PremiumMarketLoader(
              key: const ValueKey<String>('loader'),
              onFinished: () {
                if (mounted) setState(() => _loaded = true);
              },
            ),
    );
  }
}
