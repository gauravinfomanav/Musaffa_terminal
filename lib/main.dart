import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/auto_size_text.dart';
import 'package:musaffa_terminal/utils/constants.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: Constants.FONT_DEFAULT_NEW,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MusaffaAutoSizeText.titleLarge(
          'Musaffa Terminal',
          group: MusaffaAutoSizeText.groups.titleLargeGroup,
        ),
      ),
      body: Center(
        child: MusaffaAutoSizeText.bodyLarge(
          'Welcome to Musaffa Terminal',
          group: MusaffaAutoSizeText.groups.bodyLargeGroup,
        ),
      ),
    );
  }
}
