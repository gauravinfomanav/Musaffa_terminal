import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../models/live_price_model.dart';
import '../config/websocket_config.dart';

class WebSocketService extends GetxService {
  WebSocketChannel? _channel;
  final RxMap<String, LivePriceData> _livePrices = <String, LivePriceData>{}.obs;
  final RxSet<String> _subscribedTickers = <String>{}.obs;
  final RxBool _isConnected = false.obs;
  final RxString _connectionStatus = 'disconnected'.obs;
  
  // Store Typesense prices for comparison
  final RxMap<String, double> _typesensePrices = <String, double>{}.obs;
  
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  StreamSubscription? _messageSubscription;

  // Getters
  Map<String, LivePriceData> get livePrices => _livePrices;
  Set<String> get subscribedTickers => _subscribedTickers;
  bool get isConnected => _isConnected.value;
  String get connectionStatus => _connectionStatus.value;
  
  // Stream for price updates
  Stream<Map<String, LivePriceData>> get priceStream => _livePrices.stream;

  @override
  void onInit() {
    super.onInit();
    _connect();
  }

  @override
  void onClose() {
    _disconnect();
    super.onClose();
  }

  /// Connect to WebSocket server
  void _connect() {
    try {
      _connectionStatus.value = 'connecting';
      _channel = WebSocketChannel.connect(Uri.parse(WebSocketConfig.baseUrl));
      
      _messageSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );
      
      _isConnected.value = true;
      _connectionStatus.value = 'connected';
      _reconnectAttempts = 0;
      
      print('WebSocket connected successfully');
      
      // Resubscribe to previously subscribed tickers
      if (_subscribedTickers.isNotEmpty) {
        subscribeToTickers(_subscribedTickers.toList());
      }
      
    } catch (e) {
      print('WebSocket connection error: $e');
      _handleError(e);
    }
  }

  /// Disconnect from WebSocket server
  void _disconnect() {
    _messageSubscription?.cancel();
    _channel?.sink.close(status.goingAway);
    _isConnected.value = false;
    _connectionStatus.value = 'disconnected';
    _reconnectTimer?.cancel();
  }

  /// Handle incoming messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final response = LivePriceResponse.fromJson(data);
      
      if (response.status == WebSocketConfig.statusSuccess) {
        _updateLivePrices(response.data);
      }
    } catch (e) {
      // Silently handle errors to avoid widget lifecycle issues
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    print('WebSocket error: $error');
    _isConnected.value = false;
    _connectionStatus.value = 'error';
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnection() {
    print('WebSocket disconnected');
    _isConnected.value = false;
    _connectionStatus.value = 'disconnected';
    _scheduleReconnect();
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts < WebSocketConfig.maxReconnectAttempts) {
      _reconnectAttempts++;
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(WebSocketConfig.reconnectInterval, () {
        print('Attempting to reconnect... (${_reconnectAttempts}/${WebSocketConfig.maxReconnectAttempts})');
        _connect();
      });
    } else {
      print('Max reconnection attempts reached');
      _connectionStatus.value = 'failed';
    }
  }

  /// Subscribe to live prices for specific tickers
  void subscribeToTickers(List<String> tickers) {
    if (tickers.isEmpty) return;
    
    // Add to subscribed list
    _subscribedTickers.addAll(tickers);
    
    if (_isConnected.value) {
      _sendSubscriptionMessage(tickers);
    } else {
      print('WebSocket not connected, will subscribe when connected');
    }
  }

  /// Unsubscribe from specific tickers
  void unsubscribeFromTickers(List<String> tickers) {
    _subscribedTickers.removeAll(tickers);
    
    // Remove from live prices
    for (final ticker in tickers) {
      _livePrices.remove(ticker);
    }
  }

  /// Send subscription message to server
  void _sendSubscriptionMessage(List<String> tickers) {
    if (_channel != null && _isConnected.value) {
      try {
        final message = jsonEncode(tickers);
        _channel!.sink.add(message);
        print('Subscribed to tickers: $tickers');
      } catch (e) {
        print('Error sending subscription message: $e');
      }
    }
  }

  /// Update live prices from server response
  void _updateLivePrices(Map<String, LivePriceData> newPrices) {
    for (final entry in newPrices.entries) {
      final ticker = entry.key;
      final priceData = entry.value;
      
      // Get Typesense price for comparison
      final typesensePrice = _typesensePrices[ticker];
      
      // Create new LivePriceData with Typesense price for comparison
      final livePriceWithComparison = LivePriceData(
        symbol: priceData.symbol,
        price: priceData.price,
        volume: priceData.volume,
        timestamp: priceData.timestamp,
        dateTimeUtc: priceData.dateTimeUtc,
        typesensePrice: typesensePrice,
      );
      
      _livePrices[ticker] = livePriceWithComparison;
    }
  }

  /// Get live price for a specific ticker
  LivePriceData? getLivePrice(String ticker) {
    return _livePrices[ticker];
  }

  /// Get current price for a ticker (returns null if not available)
  double? getCurrentPrice(String ticker) {
    return _livePrices[ticker]?.price;
  }

  /// Check if we have live price for a ticker
  bool hasLivePrice(String ticker) {
    return _livePrices.containsKey(ticker);
  }

  /// Clear all live prices
  void clearLivePrices() {
    _livePrices.clear();
  }

  /// Clear all subscriptions
  void clearSubscriptions() {
    _subscribedTickers.clear();
    _livePrices.clear();
  }

  /// Store Typesense price for comparison
  void setTypesensePrice(String ticker, double price) {
    _typesensePrices[ticker] = price;
  }

  /// Get Typesense price for a ticker
  double? getTypesensePrice(String ticker) {
    return _typesensePrices[ticker];
  }

  /// Store multiple Typesense prices
  void setTypesensePrices(Map<String, double> prices) {
    _typesensePrices.addAll(prices);
  }

  /// Clear Typesense prices
  void clearTypesensePrices() {
    _typesensePrices.clear();
  }

  /// Force reconnect
  void reconnect() {
    _disconnect();
    _reconnectAttempts = 0;
    _connect();
  }
}
