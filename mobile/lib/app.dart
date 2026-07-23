import 'package:flutter/material.dart';

import 'src/screens/home_screen.dart';
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
      home: const HomeScreen(),
    );
  }
}
