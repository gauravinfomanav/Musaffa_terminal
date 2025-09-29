class WebSocketConfig {
  static const String baseUrl = 'ws://risepython.infomanav.in:6003/ws/price';
  
  // Connection settings
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration reconnectInterval = Duration(seconds: 5);
  static const int maxReconnectAttempts = 5;
  
  // Message types
  static const String messageTypeTrade = 'trade';
  static const String messageTypeError = 'error';
  
  // Status types
  static const String statusSuccess = 'success';
  static const String statusError = 'error';
}
