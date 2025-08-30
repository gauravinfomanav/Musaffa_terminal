import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/auto_size_text.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';

void main() {
  runApp(const MusaffaTerminalApp());
}

class MusaffaTerminalApp extends StatelessWidget {
  const MusaffaTerminalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Musaffa Terminal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: Constants.FONT_DEFAULT_NEW,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: Constants.FONT_DEFAULT_NEW,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F0F0F) 
          : const Color(0xFFFAFAFA),
      body: Column(
        children: [
          HomeTabBar(
            onThemeToggle: () {
              final currentTheme = Theme.of(context).brightness;
              Get.changeThemeMode(
                currentTheme == Brightness.dark 
                    ? ThemeMode.light 
                    : ThemeMode.dark,
              );
            },
          ),
          Expanded(
            child: Center(
              child: MusaffaAutoSizeText.bodyLarge(
                'Welcome to Musaffa Terminal',
                group: MusaffaAutoSizeText.groups.bodyLargeGroup,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
