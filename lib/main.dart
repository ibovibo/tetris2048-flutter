import 'package:flutter/material.dart';
import 'l10n.dart';
import 'menu_screen.dart';
import 'avatar_manager.dart';
import 'profile_manager.dart';
import 'stats_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await L10n.load();
  await ProfileManager.load();
  await StatsManager.load();
  await AvatarManager.load();
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
