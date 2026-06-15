import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerProvider extends ChangeNotifier {
  static const _keySong = 'xp_current_song';
  static const _keyQueue = 'xp_queue';
  static const _keyVolume = 'xp_volume';
  static const _keyPosition = 'xp_position_sec';
  static const _keyTab = 'xp_active_tab';

  final AudioPlayer _player = AudioPlayer();

  Map<String, dynamic>? _currentSong;
  List<Map<String, dynamic>> _queue = [];
  double _volume = 1.0;
  bool _isPlaying = false;
  bool _shuffle = false;
  bool _repeat = false;
  bool _muted = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _activeTab = 0;
  int _queueIndex = 0;

  // Getters
  Map<String, dynamic>? get currentSong => _currentSong;
  List<Map<String, dynamic>> get queue => _queue;
  double get volume => _muted ? 0.0 : _volume;
  bool get isPlaying => _isPlaying;
  bool get shuffle => _shuffle;
  bool get repeat => _repeat;
  bool get muted => _muted;
  Duration get position => _position;
  Duration get duration => _duration;
  int get activeTab => _activeTab;
  int get queueIndex => _queueIndex;

  PlayerProvider() {
    _initListeners();
    _loadState();
  }

  void _initListeners() {
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _player.onPositionChanged.listen((pos) {
      _position = pos;
      notifyListeners();
      _savePositionDebounced(pos.inSeconds);
    });

    _player.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _player.onPlayerComplete.listen((_) {
      if (_repeat) {
        playSong(_currentSong!);
      } else {
        playNext();
      }
    });
  }

  int _lastSavedSec = -1;
  void _savePositionDebounced(int sec) {
    if (sec != _lastSavedSec) {
      _lastSavedSec = sec;
      _saveInt(_keyPosition, sec);
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _volume = prefs.getDouble(_keyVolume) ?? 1.0;
    _activeTab = prefs.getInt(_keyTab) ?? 0;

    final songJson = prefs.getString(_keySong);
    if (songJson != null) {
      _currentSong = jsonDecode(songJson);
    }

    final queueJson = prefs.getString(_keyQueue);
    if (queueJson != null) {
      final list = jsonDecode(queueJson) as List;
      _queue = list.cast<Map<String, dynamic>>();
    }

    await _player.setVolume(_volume);
    notifyListeners();
  }

  Future<void> playSong(Map<String, dynamic> song, {List<Map<String, dynamic>>? queue}) async {
    _currentSong = song;
    if (queue != null) {
      _queue = queue;
      _queueIndex = queue.indexWhere((s) => s['id'] == song['id']);
      if (_queueIndex < 0) _queueIndex = 0;
    }

    final preview = song['preview'] ?? song['preview_url'] ?? '';
    if (preview.isEmpty) return;

    await _player.stop();
    await _player.setVolume(_volume);
    await _player.play(UrlSource(preview));
    _isPlaying = true;
    _position = Duration.zero;

    await _saveString(_keySong, jsonEncode(song));
    if (queue != null) {
      await _saveString(_keyQueue, jsonEncode(_queue));
    }
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_currentSong != null) {
        await _player.resume();
      }
    }
    notifyListeners();
  }

  Future<void> playNext() async {
    if (_queue.isEmpty) return;
    if (_shuffle) {
      _queueIndex = (DateTime.now().millisecondsSinceEpoch % _queue.length);
    } else {
      _queueIndex = (_queueIndex + 1) % _queue.length;
    }
    await playSong(_queue[_queueIndex]);
  }

  Future<void> playPrevious() async {
    if (_queue.isEmpty) return;
    _queueIndex = (_queueIndex - 1 + _queue.length) % _queue.length;
    await playSong(_queue[_queueIndex]);
  }

  Future<void> seekTo(Duration pos) async {
    await _player.seek(pos);
    _position = pos;
    notifyListeners();
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    _muted = false;
    await _player.setVolume(_volume);
    await _saveDouble(_keyVolume, _volume);
    notifyListeners();
  }

  void toggleMute() {
    _muted = !_muted;
    _player.setVolume(_muted ? 0.0 : _volume);
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _repeat = !_repeat;
    notifyListeners();
  }

  void setActiveTab(int index) {
    _activeTab = index;
    _saveInt(_keyTab, index);
    notifyListeners();
  }

  void addToQueue(Map<String, dynamic> song) {
    if (!_queue.any((s) => s['id'] == song['id'])) {
      _queue.add(song);
      _saveString(_keyQueue, jsonEncode(_queue));
      notifyListeners();
    }
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
