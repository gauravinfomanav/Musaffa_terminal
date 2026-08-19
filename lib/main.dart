import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/auth_controller.dart';
import 'package:musaffa_terminal/Controllers/floating_action_buttons_controller.dart';
import 'package:musaffa_terminal/Controllers/notes_controller.dart';
import 'package:musaffa_terminal/Screens/auth_gate.dart';
import 'package:musaffa_terminal/services/global_watchlist_service.dart';
import 'package:musaffa_terminal/services/global_sidebar_service.dart';
import 'package:musaffa_terminal/services/global_search_service.dart';
import 'package:musaffa_terminal/services/feature_access_service.dart';
import 'package:musaffa_terminal/services/table_column_preferences_service.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/global_keyboard_shortcuts.dart';
import 'services/websocket_service.dart';
import 'services/live_price_service.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;

  // Initialize FCM in background - don't block app startup
  FCMService.initialize().catchError((e) {
    print('⚠️  FCM initialization failed (non-blocking): $e');
  });
  
  // Start app immediately - don't wait for FCM
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlobalKeyboardShortcutsWrapper(
      child: GetMaterialApp(
        title: 'Infomanav Terminal',
        theme: _terminalTheme(Brightness.light),
        darkTheme: _terminalTheme(Brightness.dark),
        themeMode: ThemeMode.light, // Set default to light mode
        home: const AuthGate(),
        initialBinding: AppBinding(),
      ),
    );
  }
}

ThemeData _terminalTheme(Brightness brightness) {
  return ThemeData(
    fontFamily: Constants.FONT_DEFAULT_NEW,
    fontFamilyFallback: Constants.FONT_FALLBACK,
    primarySwatch: Colors.blue,
    brightness: brightness,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    hoverColor: Colors.transparent,
    focusColor: Colors.transparent,
    visualDensity: VisualDensity.compact,
  );
}

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<FeatureAccessService>(FeatureAccessService(), permanent: true);
    // Initialize WebSocket service
    Get.put<WebSocketService>(WebSocketService(), permanent: true);
    Get.put<LivePriceService>(LivePriceService(), permanent: true);
    // Initialize FAB controller
    Get.put<FloatingActionButtonsController>(FloatingActionButtonsController(), permanent: true);
    // Initialize global watchlist service
    Get.put<GlobalWatchlistService>(GlobalWatchlistService(), permanent: true);
    // Initialize global navigation sidebar service
    Get.put<GlobalSidebarService>(GlobalSidebarService(), permanent: true);
    // Initialize global search service
    Get.put<GlobalSearchService>(GlobalSearchService(), permanent: true);
    // Initialize table column preferences service
    Get.put<TableColumnPreferencesService>(TableColumnPreferencesService(), permanent: true);
    // Initialize notes controller
    Get.put<NotesController>(NotesController(), permanent: true);
  }
}
