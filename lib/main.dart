import 'package:flutter/material.dart';
import 'menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '2048 × TETRİS',
      debugShowCheckedModeBanner: false,
      home: MenuScreen(),
    );
  }
}