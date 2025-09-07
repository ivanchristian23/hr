import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_project/data/constants.dart';
import 'package:test_project/data/notifiers.dart';
import 'package:test_project/views/pages/welcome_page.dart';

void main() {
  runApp(const MyApp());
}

//statefull can refresh
//setstate to refresh
//stateless cant refresh
//material
//scaffold
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    initThemeMode();
    super.initState();
  }

  void initThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? repeat = prefs.getBool(KConstants.themeModeKey);
    isDarkModeNotifier.value = repeat ?? false; // Default to false if null
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.red,
              brightness: isDarkMode ? Brightness.light : Brightness.dark,
            ),
          ),
          home: WelcomePage(),
          // home: WidgetTree(),
        );
      },
    );
  }
}
