import 'package:flutter/material.dart';

import 'screens/splash_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auth',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5B4BFF),
      ),
      home: const SplashPage(),
    );
  }
}
