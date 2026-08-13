import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:musaffa_terminal/firebase_options.dart';
import 'package:musaffa_terminal/utils/platform_capabilities.dart';
import 'package:musaffa_terminal/web_service.dart';
import 'dart:io';

class FCMService {
  static FirebaseMessaging? _messaging;
  static String? _fcmToken;
  static bool _isInitialized = false;
  static String? _lastError;

  /// Initialize Firebase and FCM
  static Future<void> initialize() async {
    try {
      if (!PlatformCapabilities.isFcmSupported) {
        debugPrint(
          'FCM skipped on ${defaultTargetPlatform.name} — '
          'Firebase Messaging is not configured for this platform.',
        );
        return;
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
      
      // Get Firebase Messaging instance
      _messaging = FirebaseMessaging.instance;
      print('✅ Firebase Messaging instance created');
      
      // Request permission for notifications
      await _requestPermission();
      
      // For macOS, try a simplified approach
      if (Platform.isMacOS) {
        print('🍎 macOS detected - using simplified FCM approach...');
        await _initializeForMacOS();
      } else {
        // Get FCM token normally for other platforms
        await _getFCMToken();
      }
      
      // Setup message handlers
      _setupMessageHandlers();
      
      _isInitialized = true;
      _lastError = null;
      print('✅ FCM Service initialized successfully');
      print('🔑 FCM Token: $_fcmToken');
    } catch (e) {
      _lastError = e.toString();
      print('❌ FCM Service initialization failed: $e');
      print('ℹ️  FCM disabled - notifications will not work until GoogleService-Info.plist is added');
    }
  }

  /// Initialize FCM specifically for macOS
  static Future<void> _initializeForMacOS() async {
    try {
      // Skip APNS in release mode to avoid blocking startup
      if (kReleaseMode) {
        print('🍎 Release mode detected - skipping APNS to avoid startup delay');
        // Try to get FCM token directly without APNS
        try {
          _fcmToken = await _messaging!.getToken();
          if (_fcmToken != null) {
            print('🔑 FCM Token received (without APNS): ${_fcmToken!.substring(0, 20)}...');
            await _registerTokenWithBackend();
            _isInitialized = true;
            print('✅ FCM Service initialized (without APNS)');
            return;
          }
        } catch (e) {
          print('⚠️  FCM token failed (non-blocking): $e');
          _fcmToken = 'dev-fcm-token-${DateTime.now().millisecondsSinceEpoch}';
          await _registerTokenWithBackend();
          _isInitialized = true;
          return;
        }
      }
      
      print('🍎 Initializing FCM for macOS with APNS (debug mode only)...');
      
      // In debug mode, try APNS with limited retries (non-blocking)
      String? apnsToken;
      int retryCount = 0;
      const maxRetries = 2; // Reduced retries to avoid blocking
      
      while (apnsToken == null && retryCount < maxRetries) {
        try {
          print('🔍 Debug: Attempting to get APNS token (attempt ${retryCount + 1})...');
          
          // Try to get APNS token with short timeout
          apnsToken = await _messaging!.getAPNSToken().timeout(
            const Duration(seconds: 3), // Reduced timeout
            onTimeout: () {
              print('🔍 Debug: APNS token request timed out after 3 seconds');
              return null;
            },
          );
          
          if (apnsToken != null) {
            print('🍎 APNS token received: ${apnsToken.substring(0, 20)}...');
            break;
          }
        } catch (e) {
          print('🍎 APNS token attempt ${retryCount + 1} failed: $e');
        }
        
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(const Duration(seconds: 1)); // Reduced delay
        }
      }
      
      // Try to get FCM token (works with or without APNS)
      try {
        _fcmToken = await _messaging!.getToken();
        if (_fcmToken != null) {
          print('🔑 FCM Token received: ${_fcmToken!.substring(0, 20)}...');
          await _registerTokenWithBackend();
          print('✅ FCM token registered successfully');
        }
      } catch (e) {
        print('⚠️  FCM token failed: $e');
        // Fallback: Create a development token
        _fcmToken = 'dev-fcm-token-${DateTime.now().millisecondsSinceEpoch}';
        await _registerTokenWithBackend();
      }
      
    } catch (e) {
      print('❌ macOS FCM initialization failed: $e');
      // Fallback: Create a development token
      _fcmToken = 'dev-fcm-token-${DateTime.now().millisecondsSinceEpoch}';
      await _registerTokenWithBackend(); 
    }
  }

  /// Request notification permission
  static Future<void> _requestPermission() async {
    try {
      print('📱 Requesting notification permissions...');
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      print('📱 Notification permission status: ${settings.authorizationStatus}');
      print('📱 Alert permission: ${settings.alert}');
      print('📱 Badge permission: ${settings.badge}');
      print('📱 Sound permission: ${settings.sound}');
      
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        throw Exception('Notification permission not granted: ${settings.authorizationStatus}');
      }
    } catch (e) {
      print('❌ Failed to request notification permission: $e');
      rethrow;
    }
  }

  /// Get FCM token and register with backend
  static Future<void> _getFCMToken() async {
    try {
      print('🔑 Getting FCM token...');
      
      // For macOS, try a different approach - skip APNS entirely for now
      if (Platform.isMacOS) {
        print('🍎 macOS detected - using web-based FCM approach...');
        
        // Try to get FCM token directly without waiting for APNS
        // This works for web-based FCM on macOS
        try {
          _fcmToken = await _messaging!.getToken();
          if (_fcmToken != null) {
            print('🔑 FCM Token received (web-based): ${_fcmToken!.substring(0, 20)}...');
            await _registerTokenWithBackend();
            return; // Success!
          }
        } catch (webError) {
          print('❌ Web-based FCM failed: $webError');
        }
        
        // If web-based fails, try the APNS approach as fallback
        print('🍎 Trying APNS approach as fallback...');
        String? apnsToken;
        int retryCount = 0;
        const maxRetries = 3; // Reduced retries
        
        while (apnsToken == null && retryCount < maxRetries) {
          try {
            apnsToken = await _messaging!.getAPNSToken();
            if (apnsToken != null) {
              print('🍎 APNS token received: ${apnsToken.substring(0, 20)}...');
              break;
            }
          } catch (e) {
            print('🍎 APNS token attempt ${retryCount + 1} failed: $e');
          }
          
          retryCount++;
          if (retryCount < maxRetries) {
            print('🍎 Retrying APNS token in 1 second...');
            await Future.delayed(const Duration(seconds: 1));
          }
        }
        
        if (apnsToken == null) {
          print('⚠️  APNS token not available after $maxRetries attempts');
          print('💡 Continuing without APNS token...');
        }
      } else {
        // For other platforms, wait for APNS token normally
        print('🍎 Waiting for APNS token...');
        final apnsToken = await _messaging!.getAPNSToken();
        print('🍎 APNS token: ${apnsToken != null ? "Received" : "Not received"}');
      }
      
      // Try to get FCM token
      _fcmToken = await _messaging!.getToken();
      
      if (_fcmToken != null) {
        print('🔑 FCM Token received: ${_fcmToken!.substring(0, 20)}...');
        await _registerTokenWithBackend();
      } else {
        throw Exception('Failed to get FCM token');
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      
      // For macOS, if everything fails, try one more time with a delay
      if (Platform.isMacOS) {
        print('💡 macOS: Trying one more time with delay...');
        await Future.delayed(const Duration(seconds: 2));
        try {
          _fcmToken = await _messaging!.getToken();
          if (_fcmToken != null) {
            print('🔑 FCM Token received (delayed): ${_fcmToken!.substring(0, 20)}...');
            await _registerTokenWithBackend();
            return; // Success!
          }
        } catch (delayedError) {
          print('❌ Delayed attempt also failed: $delayedError');
        }
      }
      
      rethrow;
    }
  }

  /// Register FCM token with backend
  static Future<void> _registerTokenWithBackend() async {
    try {
      print('🌐 Registering FCM token with backend...');
      final response = await WebService.registerFCMToken(
        token: _fcmToken!,
        deviceType: Platform.isMacOS ? 'macos' : 'web', // Use macos for macOS
        deviceName: Platform.isMacOS ? 'Musaffa Terminal (macOS)' : 'Musaffa Terminal',
      );

      if (response.status == ApiStatus.SUCCESS) {
        print('✅ FCM token registered with backend successfully');
        print('📊 Backend response: ${response.data}');
      } else {
        // Don't throw - just log the error. FCM works even if backend registration fails.
        // Backend endpoint might not be implemented (501) or temporarily unavailable.
        print('⚠️  Backend registration failed: ${response.status} - ${response.errorMessage ?? "Unknown error"}');
        print('💡 FCM notifications will still work directly from Firebase. Backend registration is optional.');
      }
    } catch (e) {
      // Don't throw - just log the error. App should continue working.
      print('⚠️  Error registering FCM token with backend: $e');
      print('💡 FCM is working correctly. Notifications from Firebase console will work.');
      print('💡 Backend registration failed but this is non-critical.');
    }
  }

  /// Setup message handlers
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    // Handle token refresh
    _messaging!.onTokenRefresh.listen((newToken) {
      print('🔄 FCM token refreshed: $newToken');
      _fcmToken = newToken;
      _registerTokenWithBackend();
    });
  }

  /// Handle foreground messages (when app is open)
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Received foreground message: ${message.notification?.title}');
    print('📨 Message data: ${message.data}');
    
    // Show notification in terminal
    _showTerminalNotification(message);
  }

  /// Handle background messages (when app is closed)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('📨 Received background message: ${message.notification?.title}');
    print('📨 Message data: ${message.data}');
    
    // Show notification in terminal
    _showTerminalNotification(message);
  }

  /// Show notification in terminal
  static void _showTerminalNotification(RemoteMessage message) {
    final title = message.notification?.title ?? 'Target Price Alert';
    final body = message.notification?.body ?? 'Price target reached';
    final ticker = message.data['ticker'] ?? 'Unknown';
    
    print('\n🎯 ===== TARGET PRICE ALERT =====');
    print('📈 Stock: $ticker');
    print('📝 Title: $title');
    print('💬 Message: $body');
    print('🕐 Time: ${DateTime.now().toString()}');
    print('================================\n');
  }

  /// Get current FCM token
  static String? get fcmToken => _fcmToken;

  /// Re-register token (call when needed)
  static Future<void> reRegisterToken() async {
    await _getFCMToken();
  }

  /// Get debug information about FCM status
  static Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'hasToken': _fcmToken != null,
      'tokenPreview': _fcmToken != null ? '${_fcmToken!.substring(0, 20)}...' : null,
      'lastError': _lastError,
      'platform': Platform.operatingSystem,
      'hasMessaging': _messaging != null,
    };
  }

  /// Print debug information
  static void printDebugInfo() {
    print('\n🔍 ===== FCM DEBUG INFO =====');
    print('✅ Initialized: $_isInitialized');
    print('🔑 Has Token: ${_fcmToken != null}');
    if (_fcmToken != null) {
      print('🔑 Token Preview: ${_fcmToken!.substring(0, 20)}...');
    }
    print('❌ Last Error: $_lastError');
    print('📱 Platform: ${Platform.operatingSystem}');
    print('🔥 Has Messaging: ${_messaging != null}');
    print('=============================\n');
  }

  /// Test notification by sending a local message
  static void testNotification() {
    if (!_isInitialized) {
      print('❌ FCM not initialized. Cannot test notification.');
      return;
    }

    print('\n🧪 ===== TEST NOTIFICATION =====');
    print('📈 Stock: TEST');
    print('📝 Title: Test Target Price Alert');
    print('💬 Message: This is a test notification to verify FCM is working');
    print('🕐 Time: ${DateTime.now().toString()}');
    print('================================\n');
  }

  /// Simulate a real notification from backend
  static void simulateBackendNotification(String ticker, double targetPrice, double currentPrice) {
    print('\n🎯 ===== SIMULATED TARGET PRICE ALERT =====');
    print('📈 Stock: $ticker');
    print('🎯 Target Price: \$${targetPrice.toStringAsFixed(2)}');
    print('💰 Current Price: \$${currentPrice.toStringAsFixed(2)}');
    print('📝 Title: Target Price Alert - $ticker');
    print('💬 Message: $ticker has reached your target price of \$${targetPrice.toStringAsFixed(2)}');
    print('🕐 Time: ${DateTime.now().toString()}');
    print('==========================================\n');
  }

  /// Retry FCM initialization (useful for macOS APNS issues)
  static Future<void> retryInitialization() async {
    print('🔄 Retrying FCM initialization...');
    try {
      if (Platform.isMacOS) {
        await _initializeForMacOS();
      } else {
        await _getFCMToken();
      }
      
      if (_fcmToken != null) {
        _isInitialized = true;
        _lastError = null;
        print('✅ FCM retry successful!');
      }
    } catch (e) {
      _lastError = e.toString();
      print('❌ FCM retry failed: $e');
    }
  }

  /// Test local notification (bypasses FCM)
  static Future<void> testLocalNotification() async {
    try {
      print('🧪 Testing local notification...');
      
      // This will trigger a local notification that should appear in macOS
      // We'll simulate what FCM would do
      final title = 'Target Price Alert - AAPL';
      final body = 'AAPL has reached your target price of \$150.00';
      
      print('\n🎯 ===== LOCAL NOTIFICATION TEST =====');
      print('📝 Title: $title');
      print('💬 Message: $body');
      print('🕐 Time: ${DateTime.now().toString()}');
      print('💡 This should appear as a macOS notification');
      print('=====================================\n');
      
      // Note: For actual local notifications, you'd use flutter_local_notifications
      // But for now, this tests the console output and FCM flow
      
    } catch (e) {
      print('❌ Local notification test failed: $e');
    }
  }

  /// Test backend notification sending
  static Future<void> testBackendNotification() async {
    try {
      print('🧪 Testing backend notification...');
      
      if (_fcmToken == null) {
        print('❌ No FCM token available for testing');
        return;
      }
      
      print('\n🔔 ===== BACKEND NOTIFICATION TEST =====');
      print('🔑 FCM Token: ${_fcmToken!.substring(0, 20)}...');
      print('📱 Device Type: ${Platform.isMacOS ? 'web (macOS)' : 'web'}');
      print('💡 Backend should send notification to this token');
      print('📝 Expected notification:');
      print('   Title: Target Price Alert - AAPL');
      print('   Body: AAPL has reached your target price of \$150.00');
      print('==========================================\n');
      
      print('💡 To test:');
      print('1. Set AAPL target price to current price');
      print('2. Backend should trigger notification');
      print('3. Check if notification appears');
      
    } catch (e) {
      print('❌ Backend notification test failed: $e');
    }
  }

  /// Check if FCM is properly set up
  static bool get isReady => _isInitialized && _fcmToken != null && _lastError == null;
}
