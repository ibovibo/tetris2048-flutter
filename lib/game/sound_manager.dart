import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class SoundManager {
  static bool enabled = true;
  static double volume = 0.4;
  static bool _initialized = false;
  static AudioPlayer? _seasonPlayer;
  static AudioPlayer? _explosionPlayer;
  static bool _seasonMusicPlaying = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      FlameAudio.bgm.initialize();
      await FlameAudio.audioCache.loadAll([
        'buyukbomba.mp3',
        'oyunmuzik.mp3',
        'menumuzik.mp3',
        'buz.mp3',
        'bombamevsim.mp3',
        'kismevsim.mp3',
        'gizemmevsim.mp3',
        'hizmevsim.mp3',
        'carpanmevsim.mp3',
        'degistokusmevsim.mp3',
        '32k.mp3',
        'gameover.mp3',
        'yokedenjoker.mp3',
        'kucukbomba.mp3',
      ]);
      _initialized = true;
    } catch (_) {}
  }

  static void toggle() => enabled = !enabled;

  static void setVolume(double v) {
    volume = v.clamp(0.0, 1.0);
    try {
      if (!_seasonMusicPlaying) {
        FlameAudio.bgm.audioPlayer.setVolume(volume * 0.25);
      }
    } catch (_) {}
  }

  // ── Menü müziği ───────────────────────────────────────────
  static Future<void> playMenuMusic() async {
    if (!enabled) return;
    await stopSeasonMusic();
    await stopExplosionMusic();
    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play('menumuzik.mp3', volume: volume * 0.6);
    } catch (_) {}
  }

  // ── Oyun müziği ───────────────────────────────────────────
  static Future<void> playGameMusic() async {
    if (!enabled) return;
    if (_seasonMusicPlaying) return;
    try {
      await FlameAudio.bgm.stop(); // her zaman durdur
      await Future.delayed(const Duration(milliseconds: 100));
      await FlameAudio.bgm.play('oyunmuzik.mp3', volume: volume * 0.25);
    } catch (_) {}
  }

  static void stopMusic() {
    try { FlameAudio.bgm.stop(); } catch (_) {}
  }

  static void pauseMusic() {
    try { FlameAudio.bgm.audioPlayer.pause(); } catch (_) {}
  }

  static Future<void> resumeMusic() async {
    if (!enabled) return;
    if (_seasonMusicPlaying) return;
    try {
      await FlameAudio.bgm.audioPlayer.setVolume(volume * 0.25);
      await FlameAudio.bgm.resume();
    } catch (_) {}
  }

  // ── 32k patlama — animasyon boyunca çalar ────────────────
  static Future<void> maxExplosion32k() async {
    if (!enabled) return;
    try { FlameAudio.bgm.audioPlayer.pause(); } catch (_) {} // stop değil pause
    try {
      _explosionPlayer = AudioPlayer();
      await _explosionPlayer!.setVolume(volume * 0.9);
      await _explosionPlayer!.setReleaseMode(ReleaseMode.stop);
      await _explosionPlayer!.play(AssetSource('audio/32k.mp3'));
    } catch (e) {
      debugPrint('32k error: $e');
    }
  }

  static Future<void> stopExplosionMusic() async {
    try {
      await _explosionPlayer?.stop();
      await _explosionPlayer?.dispose();
      _explosionPlayer = null;
    } catch (_) {}
  }

  // ── Mevsim müziği — her mevsimin kendi dosyası ────────────
  static Future<void> playSeasonMusic(String season) async {
    if (!enabled) return;
    _seasonMusicPlaying = true; // önce flag'i set et
    await stopExplosionMusic();
    await stopSeasonMusic();
    try { FlameAudio.bgm.audioPlayer.pause(); } catch (_) {}

    final files = {
      'bomb':       'bombamevsim.mp3',
      'ice':        'kismevsim.mp3',
      'mystery':    'gizemmevsim.mp3',
      'speed':      'hizmevsim.mp3',
      'multiplier': 'carpanmevsim.mp3',
      'shuffle':    'degistokusmevsim.mp3',
    };
    final file = files[season];
    if (file == null) {
      _seasonMusicPlaying = false;
      return;
    }

    debugPrint('playSeasonMusic çağrıldı: $season, file: $file');

    try {
      _seasonPlayer = AudioPlayer();
      await _seasonPlayer!.setVolume(volume * 0.65);
      await _seasonPlayer!.setReleaseMode(ReleaseMode.loop);
      await _seasonPlayer!.play(AssetSource('audio/$file'));
      debugPrint('Mevsim müziği: $season → $file');
    } catch (e) {
      _seasonMusicPlaying = false;
      debugPrint('Season music error: $e');
    }
  }

  static Future<void> stopSeasonMusic() async {
    try {
      await _seasonPlayer?.stop();
      await _seasonPlayer?.dispose();
      _seasonPlayer = null;
    } catch (_) {}
  }

  static void clearSeasonMusicFlag() {
    _seasonMusicPlaying = false;
  }

  // ── Efektler ──────────────────────────────────────────────
  static void megaBomb() {
    if (!enabled) return;
    try { FlameAudio.play('buyukbomba.mp3', volume: volume * 0.9); } catch (_) {}
  }

  static void iceJoker() {
    if (!enabled) return;
    try {
      FlameAudio.play('buz.mp3').then((player) async {
        await player.setPlaybackRate(2.0);
        await player.setVolume((volume * 1.2).clamp(0.0, 1.0));
        final duration = await player.getDuration();
        if (duration != null) {
          await player.seek(Duration(
            milliseconds: (duration.inMilliseconds * 0.10).round()));
        }
      });
    } catch (_) {}
  }

  static void gameOver() {
    if (!enabled) return;
    try { FlameAudio.play('gameover.mp3', volume: volume * 0.9); } catch (_) {}
  }

  static void starJoker() {
    debugPrint('starJoker çağrıldı');
    if (!enabled) return;
    try {
      debugPrint('FlameAudio.play yokedenjoker.mp3');
      FlameAudio.play('yokedenjoker.mp3', volume: volume * 0.9);
    } catch (e) {
      debugPrint('starJoker hata: $e');
    }
  }

  static void bomb() {
    if (!enabled) return;
    try { FlameAudio.play('kucukbomba.mp3', volume: volume * 1.3); } catch (_) {}
  }
  static void merge(int val) {}
  static void combo(int n) {}
  static void level() {}
  static void milestone(int val) {}
  static void drop() {}
}