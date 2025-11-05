import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Screens/main_screen.dart';
import 'services/websocket_service.dart';
import 'services/live_price_service.dart';
import 'services/fcm_service.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FCMService.initialize();
  if (Platform.isMacOS) {
    Future.delayed(const Duration(seconds: 5), () async {
      await FCMService.retryInitialization();
    });
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Musaffa Terminal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.light, // Set default to light mode
      home: const MainScreen(),
      initialBinding: AppBinding(),
    );
  }
}

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize WebSocket service
    Get.put<WebSocketService>(WebSocketService(), permanent: true);
    Get.put<LivePriceService>(LivePriceService(), permanent: true);
  }
}
