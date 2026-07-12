import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'avatar_manager.dart';

class LeaderboardEntry {
  final String uid;
  final String userName;
  final int? avatarIndex;
  final String country;
  final int score; // global/yerel için maxScore, haftalık için weeklyScore
  final int rank; // sıra numarası (listede hesaplanır)

  const LeaderboardEntry({
    required this.uid,
    required this.userName,
    required this.avatarIndex,
    required this.country,
    required this.score,
    required this.rank,
  });

  factory LeaderboardEntry.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    int rank, {
    required bool weekly,
  }) {
    final data = doc.data();
    final rawScore = weekly ? data['weeklyScore'] : data['maxScore'];
    return LeaderboardEntry(
      uid: data['uid'] as String? ?? doc.id,
      userName: data['userName'] as String? ?? 'Player',
      avatarIndex: (data['avatarIndex'] as num?)?.toInt(),
      country: data['country'] as String? ?? '',
      score: (rawScore as num?)?.toInt() ?? 0,
      rank: rank,
    );
  }
}

class LeaderboardManager {
  static const String _collection = 'leaderboard';

  // ── Skor gönder (game over sonrası) ─────────────────────────────────────
  // İnternet yoksa / Firebase kurulu değilse sessizce geçer, hata fırlatmaz.
  static Future<void> submitScore(int score) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final weekId = getCurrentWeekId();
      final doc = FirebaseFirestore.instance.collection(_collection).doc(uid);
      final snapshot = await doc.get();

      int currentMax = 0;
      int currentWeekly = 0;

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          currentMax = (data['maxScore'] as num?)?.toInt() ?? 0;
          final savedWeekId = data['weekId'] as String?;
          // Hafta değiştiyse weeklyScore sıfırlanmış gibi davran
          currentWeekly = savedWeekId == weekId
              ? (data['weeklyScore'] as num?)?.toInt() ?? 0
              : 0;
        }
      }

      final userName = await _resolveUserName();
      final countryCode = await resolveCountryCode();

      await doc.set({
        'uid': uid,
        'userName': userName,
        'avatarIndex': AvatarManager.avatarIndex,
        'avatarUrl': null,
        'country': countryCode,
        'maxScore': score > currentMax ? score : currentMax,
        'weeklyScore': score > currentWeekly ? score : currentWeekly,
        'weekId': weekId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Bağlantı yok / Firebase kurulu değil — sessizce geç.
    }
  }

  // ── Global sıralama (tüm zamanlar, top 100) ─────────────────────────────
  static Future<List<LeaderboardEntry>> fetchGlobal({int limit = 100}) async {
    final query = await FirebaseFirestore.instance
        .collection(_collection)
        .orderBy('maxScore', descending: true)
        .limit(limit)
        .get();
    return _mapDocs(query.docs, weekly: false);
  }

  // ── Yerel sıralama (aynı ülke, top 100) ──────────────────────────────────
  static Future<List<LeaderboardEntry>> fetchLocal(
    String countryCode, {
    int limit = 100,
  }) async {
    final query = await FirebaseFirestore.instance
        .collection(_collection)
        .where('country', isEqualTo: countryCode)
        .orderBy('maxScore', descending: true)
        .limit(limit)
        .get();
    return _mapDocs(query.docs, weekly: false);
  }

  // ── Haftalık sıralama (bu hafta, top 100) ───────────────────────────────
  static Future<List<LeaderboardEntry>> fetchWeekly({int limit = 100}) async {
    final weekId = getCurrentWeekId();
    final query = await FirebaseFirestore.instance
        .collection(_collection)
        .where('weekId', isEqualTo: weekId)
        .orderBy('weeklyScore', descending: true)
        .limit(limit)
        .get();
    return _mapDocs(query.docs, weekly: true);
  }

  static List<LeaderboardEntry> _mapDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required bool weekly,
  }) {
    final list = <LeaderboardEntry>[];
    for (int i = 0; i < docs.length; i++) {
      list.add(LeaderboardEntry.fromDoc(docs[i], i + 1, weekly: weekly));
    }
    return list;
  }

  // ── Hafta ID hesapla (yıl + hafta numarası, örn '2026-W27') ─────────────
  static String getCurrentWeekId() {
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final daysSince = now.difference(firstDayOfYear).inDays;
    final weekNumber =
        ((daysSince + firstDayOfYear.weekday - 1) / 7).floor() + 1;
    return '${now.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  // ── Kullanıcı adı / ülke kodu çözümleme ──────────────────────────────────

  static Future<String> _resolveUserName() async {
    final prefs = await SharedPreferences.getInstance();
    var name = prefs.getString('user_name');
    if (name == null || name.trim().isEmpty) {
      name = 'Guest${100 + Random().nextInt(9000)}';
      await prefs.setString('user_name', name);
    }
    return name;
  }

  static Future<String> resolveCountryCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_country_code') ?? 'TR';
  }
}
