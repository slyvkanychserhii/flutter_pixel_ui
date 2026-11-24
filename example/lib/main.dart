import 'package:flutter/material.dart';

import 'demo/home_screen.dart';

void main() {
  runApp(const PixelDemoApp());
}

/// Корень приложения-демонстрации. Здесь только тема и стартовый экран:
/// сами демонстрации лежат в lib/demo, а компонент в lib/pixel.
class PixelDemoApp extends StatelessWidget {
  const PixelDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
