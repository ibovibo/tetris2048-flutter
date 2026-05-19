import 'package:flutter/material.dart';
import 'l10n.dart';
import 'menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await L10n.load();
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
