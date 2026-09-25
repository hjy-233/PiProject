import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mybot_console/l10n/app_localizations.dart';
import 'package:mybot_console/src/home_page.dart';

void main() {
  runApp(const MyBotApp());
}

class MyBotApp extends StatelessWidget {
  const MyBotApp({super.key, this.home = const HomePage()});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyBot',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF88A9FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101116),
        cardTheme: const CardThemeData(
          color: Color(0xFF1A1C23),
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF20222A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: home,
    );
  }
}
