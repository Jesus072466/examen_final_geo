import 'package:examen_final/screens/locationScreen.dart';
import 'package:examen_final/theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapita App',
      theme: lightTheme(context),
      home: const SearchLocationScreen(),
    );
  }
}