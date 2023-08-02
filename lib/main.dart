import 'package:flutter/material.dart';
import 'package:sketch_scribble/screens/create_room_screen.dart';
import 'package:sketch_scribble/screens/paint_screen.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primaryColor: Colors.redAccent,
          primarySwatch: Colors.red,
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.red)),
      home: HomeScreen(),
    );
  }
}
