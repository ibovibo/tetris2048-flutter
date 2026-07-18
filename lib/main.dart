import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'achievement_manager.dart';
import 'avatar_manager.dart';
import 'game/sound_manager.dart';
import 'l10n.dart';
import 'menu_screen.dart';
import 'profile_manager.dart';
import 'stats_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await L10n.load();
  await ProfileManager.load();
  await StatsManager.load();
  await AvatarManager.load();
  await AchievementManager.load();
  await SoundManager.init();
  await _initFirebase();
  runApp(const MyApp());
}

// Firebase henüz kurulmamışsa (google-services.json / GoogleService-Info.plist
// eksikse) initializeApp hata fırlatır — leaderboard dışındaki tüm oyun
// bundan etkilenmemeli, bu yüzden sessizce yakalanır.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    // Anonim auth — kullanıcı giriş yapmadan skor gönderebilsin.
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Firebase init atlandı (kurulum eksik olabilir): $e');
  }
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
