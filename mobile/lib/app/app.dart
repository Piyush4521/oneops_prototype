import 'package:flutter/material.dart';
import '../features/incidents/home_screen.dart';

class OneOpsApp extends StatelessWidget {
  const OneOpsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OneOps',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E13),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4DA3FF), brightness: Brightness.dark),
        cardTheme: CardThemeData(
          color: const Color(0xFF111720),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
