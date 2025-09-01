import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/market_summary.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F0F0F) 
          : const Color(0xFFFAFAFA),
      body: Column(
        children: [
          // Tabbar at the top
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                IntrinsicWidth(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8.0),
                    child: MarketSummaryDynamicTable(),
                  ),
                ),
                
                SizedBox(width: 12),
                
                Expanded(
                  child: Container(
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
