import 'package:flutter/material.dart';

import 'home_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'J2M - Convert JSON to Model Instantly',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const Banner(
        message: 'DEV',
        location: BannerLocation.topEnd,
        child: HomeScreen(),
      ),
    );
  }
}
