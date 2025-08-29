import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
        title: const Text('Musaffa Terminal'),
      ),
      body: const Center(
        child: Text('Welcome to Musaffa Terminal'),
      ),
    );
  }
}
