import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const AkcePayApp());
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class AkcePayApp extends StatefulWidget {
  const AkcePayApp({super.key});

  static _AkcePayAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_AkcePayAppState>();

  @override
  State<AkcePayApp> createState() => _AkcePayAppState();
}

class _AkcePayAppState extends State<AkcePayApp> {
  Locale _locale = const Locale('tr');
  ThemeMode _themeMode = ThemeMode.light;
  double _textScaleFactor = 1.0;

  void setLocale(Locale locale) => setState(() => _locale = locale);
  void setThemeMode(ThemeMode mode) => setState(() => _themeMode = mode);
  void setTextScaleFactor(double scale) =>
      setState(() => _textScaleFactor = scale);
  bool get isDark => _themeMode == ThemeMode.dark;
  double get textScaleFactor => _textScaleFactor;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akçe Pay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      locale: _locale,
      scrollBehavior: AppScrollBehavior(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(_textScaleFactor),
          ),
          child: child!,
        );
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
      ],
      home: const LoginScreen(),
    );
  }
}