import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Screens/main_screen.dart';
import 'services/websocket_service.dart';
import 'services/live_price_service.dart';

void main() {
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
      home: MainScreen(),
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
