import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/screens/home_screen.dart';
import 'src/screens/onboarding_screen.dart';
import 'src/theme.dart';

class ColmenaMobileApp extends StatelessWidget {
  const ColmenaMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Colmena',
      theme: ColmenaTheme.light,
      darkTheme: ColmenaTheme.dark,
      themeMode: ThemeMode.light,
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_complete') ?? false;
    setState(() => _showOnboarding = !seen);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    // Loading mientras revisa preferencias
    if (_showOnboarding == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showOnboarding!) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    return const HomeScreen();
  }
}
