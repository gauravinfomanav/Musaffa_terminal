import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/charts/controllers/ticker_custom_charts_controller.dart';
import 'package:musaffa_terminal/charts/custom/widgets/premium_finance_chart_showcase.dart';
import 'package:musaffa_terminal/charts/custom/widgets/premium_live_chart.dart';
import 'package:musaffa_terminal/charts/custom/widgets/premium_market_loader.dart';
import 'package:musaffa_terminal/models/live_price_model.dart';
import 'package:musaffa_terminal/services/live_price_service.dart';
import 'package:musaffa_terminal/services/websocket_service.dart';

/// Custom Charts tab — premium loader → live chart + charts showcase.
class TickerCustomChartsTabContent extends StatefulWidget {
  const TickerCustomChartsTabContent({
    super.key,
    required this.symbol,
    this.companyName = '',
    this.fallbackPrice,
    this.dayChangePercent,
  });

  final String symbol;
  final String companyName;
  final double? fallbackPrice;
  final double? dayChangePercent;

  @override
  State<TickerCustomChartsTabContent> createState() =>
      _TickerCustomChartsTabContentState();
}

class _TickerCustomChartsTabContentState
    extends State<TickerCustomChartsTabContent> {
  bool _loaded = false;
  late final TickerCustomChartsController _chartsController;
  late final LivePriceService _livePriceService;
  late final WebSocketService _webSocketService;
  late final String _controllerTag;
  StreamSubscription<Map<String, LivePriceData>>? _priceSub;
  bool _isLiveConnected = false;

  String get _symbol => widget.symbol.trim().toUpperCase();

  @override
  void initState() {
    super.initState();
    _controllerTag = 'custom_charts_$_symbol';
    _chartsController = Get.put(
      TickerCustomChartsController(),
      tag: _controllerTag,
    );
    _livePriceService = Get.find<LivePriceService>();
    _webSocketService = Get.find<WebSocketService>();
    _isLiveConnected = _livePriceService.isConnected;

    if (widget.fallbackPrice != null) {
      _chartsController.livePrice.value = widget.fallbackPrice;
    }

    Future<void>.delayed(const Duration(milliseconds: 3600), () {
      if (mounted) setState(() => _loaded = true);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _symbol.isEmpty) return;
      _chartsController.loadPriceHistory(_symbol);
      _listenLivePrices();
    });
  }

  void _listenLivePrices() {
    if (_symbol.isEmpty) return;

    // Parent ticker screen owns subscribe/unsubscribe lifecycle.
    _isLiveConnected = _livePriceService.isConnected;

    _priceSub?.cancel();
    _priceSub = _webSocketService.priceStream.listen(
      (Map<String, LivePriceData> prices) {
        if (!mounted) return;
        final LivePriceData? tick = prices[_symbol];
        final bool connected = _livePriceService.isConnected;
        if (tick != null) {
          _chartsController.applyLivePrice(tick.price);
        }
        if (connected != _isLiveConnected) {
          setState(() => _isLiveConnected = connected);
        }
      },
      onError: (_) {},
    );
  }

  @override
  void didUpdateWidget(covariant TickerCustomChartsTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol.trim().toUpperCase() != _symbol) {
      _priceSub?.cancel();
      _chartsController.loadPriceHistory(_symbol);
      _listenLivePrices();
    } else if (widget.fallbackPrice != null &&
        widget.fallbackPrice != oldWidget.fallbackPrice &&
        _chartsController.livePrice.value == null) {
      _chartsController.livePrice.value = widget.fallbackPrice;
    }

    if (widget.fallbackPrice != null &&
        widget.fallbackPrice != oldWidget.fallbackPrice) {
      // Keep header in sync when parent pushes newer live ticks via rebuild.
      _chartsController.applyLivePrice(widget.fallbackPrice!);
    }
  }

  @override
  void dispose() {
    _priceSub?.cancel();
    if (Get.isRegistered<TickerCustomChartsController>(tag: _controllerTag)) {
      Get.delete<TickerCustomChartsController>(tag: _controllerTag);
    }
    super.dispose();
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    PremiumLiveChart(
                      symbol: _symbol,
                      companyName: widget.companyName,
                      controller: _chartsController,
                      fallbackPrice: widget.fallbackPrice,
                      dayChangePercent: widget.dayChangePercent,
                      isLiveConnected: _isLiveConnected,
                    ),
                    const SizedBox(height: 14),
                    const PremiumFinanceChartShowcase(includeHero: false),
                  ],
                ),
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
