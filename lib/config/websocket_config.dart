import 'package:musaffa_terminal/config/api_config.dart';

class WebSocketConfig {
  static const String baseUrl = ApiConfig.priceWebSocketUrl;
  
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
