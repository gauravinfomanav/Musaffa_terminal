import 'package:get/get.dart';
import 'websocket_service.dart';
import '../models/live_price_model.dart';

class LivePriceService extends GetxService {
  final WebSocketService _webSocketService = Get.find<WebSocketService>();
  
  // Track which tickers are currently visible on screen
  final RxSet<String> _visibleTickers = <String>{}.obs;
  
  // Getters
  Set<String> get visibleTickers => _visibleTickers;
  bool get isConnected => _webSocketService.isConnected;
  String get connectionStatus => _webSocketService.connectionStatus;

  @override
  void onInit() {
    super.onInit();
    _setupPriceStream();
  }

  /// Setup price stream listener
  void _setupPriceStream() {
    _webSocketService.priceStream.listen((prices) {
      // Price updates are automatically handled by WebSocketService
      // This method can be used for additional processing if needed
    });
  }

  /// Add tickers to visible list and subscribe to live prices
  void addVisibleTickers(List<String> tickers) {
    if (tickers.isEmpty) return;
    
    _visibleTickers.addAll(tickers);
    _webSocketService.subscribeToTickers(tickers);
    
    print('Added visible tickers: $tickers');
  }

  /// Remove tickers from visible list and unsubscribe
  void removeVisibleTickers(List<String> tickers) {
    _visibleTickers.removeAll(tickers);
    _webSocketService.unsubscribeFromTickers(tickers);
    
    print('Removed visible tickers: $tickers');
  }

  /// Update visible tickers (useful when user navigates between screens)
  void updateVisibleTickers(List<String> newTickers) {
    final currentTickers = _visibleTickers.toSet();
    final newTickersSet = newTickers.toSet();
    
    // Find tickers to add
    final toAdd = newTickersSet.difference(currentTickers);
    
    // Find tickers to remove
    final toRemove = currentTickers.difference(newTickersSet);
    
    // Update subscriptions
    if (toAdd.isNotEmpty) {
      addVisibleTickers(toAdd.toList());
    }
    
    if (toRemove.isNotEmpty) {
      removeVisibleTickers(toRemove.toList());
    }
  }

  /// Clear all visible tickers
  void clearVisibleTickers() {
    final currentTickers = _visibleTickers.toList();
    removeVisibleTickers(currentTickers);
  }

  /// Get live price for a ticker
  double? getLivePrice(String ticker) {
    return _webSocketService.getCurrentPrice(ticker);
  }

  /// Check if we have live price for a ticker
  bool hasLivePrice(String ticker) {
    return _webSocketService.hasLivePrice(ticker);
  }

  /// Get live price data for a ticker
  LivePriceData? getLivePriceData(String ticker) {
    return _webSocketService.getLivePrice(ticker);
  }

  /// Get all live prices
  Map<String, LivePriceData> getAllLivePrices() {
    return _webSocketService.livePrices;
  }

  /// Force reconnect to WebSocket
  void reconnect() {
    _webSocketService.reconnect();
  }

  /// Clear all subscriptions and data
  void clearAll() {
    _webSocketService.clearSubscriptions();
    _visibleTickers.clear();
  }
}
