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
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFFFAF0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFC857),
          brightness: Brightness.light,
          primary: const Color(0xFFF5B700),
          secondary: const Color(0xFF17324D),
          error: const Color(0xFFE85D4F),
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: const Color(0xFF162033),
              displayColor: const Color(0xFF162033),
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFAF0),
          foregroundColor: Color(0xFF162033),
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFFFFFAF0),
          indicatorColor: const Color(0xFFFFD84D),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFF162033)
                  : const Color(0xFF697386),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFCF5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF162033),
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF162033),
            minimumSize: const Size(48, 48),
            side: const BorderSide(color: Color(0xFF162033), width: 1.4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
