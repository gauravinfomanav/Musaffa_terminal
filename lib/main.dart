import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/auto_size_text.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/dynamic_table.dart';

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

  List<TableColumn> get _columns => [
    TableColumn(key: 'price', title: 'Price'),
    TableColumn(key: 'change', title: 'Change'),
    TableColumn(key: 'changePercent', title: 'Change %'),
    TableColumn(key: 'volume', title: 'Volume'),
    TableColumn(key: 'marketCap', title: 'Market Cap'),
    TableColumn(key: 'pe', title: 'P/E Ratio'),
  ];

  List<TableRowData> get _sampleData => [
    TableRowData(
      id: '1',
      name: 'Apple Inc.',
      symbol: 'AAPL',
      logo: 'https://logo.clearbit.com/apple.com',
      data: {
        'price': 175.43,
        'change': '+2.15',
        'changePercent': '+1.24%',
        'volume': '45.2M',
        'marketCap': '2.75T',
        'pe': 28.5,
      },
    ),
    TableRowData(
      id: '2',
      name: 'Microsoft Corporation',
      symbol: 'MSFT',
      logo: 'https://logo.clearbit.com/microsoft.com',
      data: {
        'price': 378.85,
        'change': '-1.23',
        'changePercent': '-0.32%',
        'volume': '22.8M',
        'marketCap': '2.81T',
        'pe': 35.2,
      },
    ),
    TableRowData(
      id: '3',
      name: 'Alphabet Inc.',
      symbol: 'GOOGL',
      logo: 'https://logo.clearbit.com/google.com',
      data: {
        'price': 142.56,
        'change': '+3.67',
        'changePercent': '+2.64%',
        'volume': '18.9M',
        'marketCap': '1.79T',
        'pe': 24.8,
      },
    ),
    TableRowData(
      id: '4',
      name: 'Amazon.com Inc.',
      symbol: 'AMZN',
      logo: 'https://logo.clearbit.com/amazon.com',
      data: {
        'price': 145.24,
        'change': '+1.89',
        'changePercent': '+1.32%',
        'volume': '32.1M',
        'marketCap': '1.51T',
        'pe': 42.1,
      },
    ),
    TableRowData(
      id: '5',
      name: 'Tesla Inc.',
      symbol: 'TSLA',
      logo: 'https://logo.clearbit.com/tesla.com',
      data: {
        'price': 248.50,
        'change': '-5.67',
        'changePercent': '-2.23%',
        'volume': '89.3M',
        'marketCap': '789.2B',
        'pe': 65.3,
      },
    ),
  ];

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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MusaffaAutoSizeText.headlineMedium(
                    'Stock Market Overview',
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: DynamicTable(
                      columns: _columns,
                      data: _sampleData,
                      onRowSelect: (row) {
                        // Handle row selection here
                        print('Selected: ${row.name} (${row.symbol})');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
