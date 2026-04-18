import 'dart:math' as math;
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class SoundManager {
  static bool enabled = true;
  static double _volume = 0.7;
  static bool _initialized = false;
  static String? _currentMusic;
  static const String _menuMusic = 'menumuzik.mp3';
  static const String _gameMusic = 'oyunmuzik.mp3';
  static const double _gameMusicVolumeFactor = 0.25; // gecici: oyun muzigi tekrar yariya dusuruldu

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[SoundManager] $message');
    }
  }

  static Future<void> init() async {
    if (_initialized) return;
    try {
      FlameAudio.bgm.initialize();
      await FlameAudio.audioCache.loadAll([
        'buyukbomba.mp3',
        'oyunmuzik.mp3',
        'menumuzik.mp3',
        'buz.mp3',
      ]);
      _initialized = true;
      _log('BGM initialized');
    } catch (e) {
      _log('BGM init failed: $e');
    }
  }

  static void toggle() => enabled = !enabled;

  static void setVolume(double v) {
    _volume = v;
    final factor = _currentMusic == _gameMusic ? _gameMusicVolumeFactor : 1.0;
    try { FlameAudio.bgm.audioPlayer.setVolume((v * factor).clamp(0.0, 1.0)); } catch (_) {}
  }

  static Future<void> playMenuMusic() async {
    await _playMusic(_menuMusic);
  }

  static Future<void> playGameMusic() async {
    await _playMusic(_gameMusic, volumeFactor: _gameMusicVolumeFactor);
  }

  static Future<void> _playMusic(String asset, {double volumeFactor = 1.0}) async {
    if (!enabled) {
      _log('Play skipped (disabled): $asset');
      return;
    }
    if (!_initialized) await init();
    if (_currentMusic == asset && FlameAudio.bgm.isPlaying) {
      _log('Already playing: $asset');
      return;
    }
    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play(asset, volume: (_volume * volumeFactor).clamp(0.0, 1.0));
      _currentMusic = asset;
      _log('Playing BGM: $asset');
    } catch (e) {
      _log('Play failed ($asset): $e');
    }
  }

  static Future<void> stopMusic() async {
    try {
      await FlameAudio.bgm.stop();
      _currentMusic = null;
      _log('BGM stopped');
    } catch (e) {
      _log('Stop failed: $e');
    }
  }

  static Future<void> pauseMusic() async {
    try {
      await FlameAudio.bgm.pause();
      _log('BGM paused');
    } catch (e) {
      _log('Pause failed: $e');
    }
  }

  static Future<void> resumeMusic() async {
    if (!enabled) {
      _log('Resume skipped (disabled)');
      return;
    }
    try {
      await FlameAudio.bgm.resume();
      _log('BGM resumed');
    } catch (e) {
      _log('Resume failed: $e');
    }
  }

  // Procedural ses — AudioContext ile ton üret
  static void _tone(double freq, String type, double dur, double vol) {
    if (!enabled) return;
    if (!kIsWeb) return; // şimdilik sadece web
    try {
      // Web Audio API doğrudan çağrı
      _playWebTone(freq, type, dur, vol);
    } catch (_) {}
  }

  static void _playWebTone(double freq, String type, double dur, double vol) {
    // Placeholder — gerçek ses dosyaları eklenince aktif olacak
  }

  // ── Ses fonksiyonları ─────────────────────────────────────
  static void drop() => _tone(100, 'sine', 0.07, 0.09);

  static void merge(int val) {
    final freq = (180 * math.log(val.toDouble()) / math.log(2)).clamp(100.0, 900.0);
    _tone(freq, 'triangle', 0.12, 0.16);
  }

  static void combo(int n) => _tone(340 + n*65, 'square', 0.11, 0.2);

  static void level() {
    const freqs = [440.0, 554.0, 659.0];
    for (int i = 0; i < freqs.length; i++) {
      Future.delayed(Duration(milliseconds: i*75), () => _tone(freqs[i], 'sine', 0.22, 0.22));
    }
  }

  static Future<void> gameOver() async {
    if (!enabled) return;
    await _playSfx('audio/gameover.mp3', volume: (_volume * 1.2).clamp(0.0, 1.0));
  }

  static void maxExplosion32k() {
    if (!enabled) return;
    _playSfx('audio/32k.mp3', volume: (_volume * 2.0).clamp(0.0, 1.0));
  }

  static void iceJoker() {
    if (!enabled) return;
    try {
      FlameAudio.play('buz.mp3').then((player) async {
        await player.setPlaybackRate(2.0);
        await player.setVolume((_volume * 1.2).clamp(0.0, 1.0));
        final duration = await player.getDuration();
        if (duration != null) {
          final startPos = Duration(
            milliseconds: (duration.inMilliseconds * 0.10).round(),
          );
          await player.seek(startPos);
        }
      });
    } catch (_) {}
  }

  static Future<void> _playSfx(String assetPath, {double volume = 1.0}) async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource(assetPath), volume: volume);
      _log('SFX played: $assetPath');
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      _log('SFX failed ($assetPath): $e');
    }
  }

  static Future<void> _playSfxSegment(
    String assetPath, {
    double volume = 1.0,
    double playbackRate = 1.0,
    Duration sourceDuration = const Duration(seconds: 1),
  }) async {
    final player = AudioPlayer();
    try {
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(
        AssetSource(assetPath),
        volume: volume,
        mode: PlayerMode.lowLatency,
      );
      try {
        await player.setPlaybackRate(playbackRate);
      } catch (e) {
        _log('PlaybackRate unsupported for $assetPath: $e');
      }

      // Source audio's first N seconds at playbackRate.
      final realMs = (sourceDuration.inMilliseconds / playbackRate)
          .round()
          .clamp(150, sourceDuration.inMilliseconds);
      final stopDelayMs = (realMs + 400).clamp(realMs, sourceDuration.inMilliseconds * 2);
      await Future<void>.delayed(Duration(milliseconds: stopDelayMs));
      try {
        await player.stop();
      } catch (_) {}
      try {
        await player.release();
      } catch (_) {}
      _log('SFX segment played: $assetPath rate=$playbackRate cut=${sourceDuration.inMilliseconds}ms');
    } catch (e) {
      _log('SFX segment failed ($assetPath): $e');
      try {
        await player.release();
      } catch (_) {}
    }
  }

  static void bomb() => _tone(55, 'sawtooth', 0.4, 0.45);

  static void megaBomb() {
    if (!enabled) return;
    _playMegaBombWithOffset();
  }

  static Future<void> _playMegaBombWithOffset() async {
    final player = AudioPlayer();
    try {
      await player.setVolume(0.8);
      await player.setSource(AssetSource('audio/buyukbomba.mp3'));

      final duration = await player.getDuration();
      final startMs = duration == null
          ? 250
          : (duration.inMilliseconds * 0.10).round().clamp(0, duration.inMilliseconds);

      await player.seek(Duration(milliseconds: startMs));
      await player.resume();
      _log('SFX played: buyukbomba.mp3 (offset ${startMs}ms)');

      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      _log('SFX failed (buyukbomba.mp3 offset): $e');
      try {
        await player.dispose();
      } catch (_) {}
    }
  }

  static void milestone(int val) {
    final freqs = val >= 1024
        ? [392.0, 494.0, 587.0, 784.0, 987.0]
        : [523.0, 659.0, 784.0, 1047.0];
    for (int i = 0; i < freqs.length; i++) {
      Future.delayed(Duration(milliseconds: i*72), () => _tone(freqs[i], 'sine', 0.4, 0.28));
    }
  }
}