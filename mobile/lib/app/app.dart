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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7BC7C0),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0E13),
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0E141B),
          indicatorColor: const Color(0xFF7BC7C0).withValues(alpha: 0.16),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFF7BC7C0)
                  : const Color(0xFF8C98A8),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF111720),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
