import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryProvider extends ChangeNotifier {
  static const _keyHistory = 'xp_history';
  static const _keyReviews = 'xp_reviews';
  static const _keyListeningTime = 'xp_listening_min';

  List<Map<String, dynamic>> _history = [];
  Map<String, Map<String, dynamic>> _reviews = {};
  int _totalMinutes = 0;

  List<Map<String, dynamic>> get history => _history;
  Map<String, Map<String, dynamic>> get reviews => _reviews;
  int get totalMinutes => _totalMinutes;

  HistoryProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final histJson = prefs.getString(_keyHistory);
    if (histJson != null) {
      _history = List<Map<String, dynamic>>.from(jsonDecode(histJson));
    }

    final revJson = prefs.getString(_keyReviews);
    if (revJson != null) {
      final raw = jsonDecode(revJson) as Map<String, dynamic>;
      _reviews = raw.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
    }

    _totalMinutes = prefs.getInt(_keyListeningTime) ?? 0;
    notifyListeners();
  }

  Future<void> addToHistory(Map<String, dynamic> song) async {
    final entry = {
      'id': song['id'],
      'titulo': song['title'] ?? song['titulo'] ?? '',
      'artista': song['artist']?['name'] ?? song['artista'] ?? '',
      'capa': song['album']?['cover_medium'] ?? song['capa'] ?? '',
      'preview_url': song['preview'] ?? song['preview_url'] ?? '',
      'genero': song['genero'] ?? 'Pop',
      'tocado_em': DateTime.now().toIso8601String(),
    };

    // Remove duplicata recente (evita spam)
    _history.removeWhere((h) =>
        h['id'] == entry['id'] &&
        DateTime.now().difference(DateTime.parse(h['tocado_em']!)).inMinutes < 1);

    _history.insert(0, entry);
    if (_history.length > 200) _history = _history.sublist(0, 200);

    // Incrementa tempo de audição (preview ~30s = 0.5 min)
    _totalMinutes += 1;

    await _saveHistory();
    notifyListeners();
  }

  Future<void> addReview(String trackId, int stars, String comment) async {
    _reviews[trackId] = {
      'stars': stars,
      'comment': comment,
      'date': DateTime.now().toIso8601String(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReviews, jsonEncode(_reviews));
    notifyListeners();
  }

  Map<String, dynamic>? getReview(String trackId) => _reviews[trackId];

  List<Map<String, dynamic>> getTopSongs({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final filtered = _history.where((h) {
      final date = DateTime.tryParse(h['tocado_em'] ?? '');
      return date != null && date.isAfter(cutoff);
    }).toList();

    // Conta plays por música
    final counts = <String, Map<String, dynamic>>{};
    for (final h in filtered) {
      final id = h['id'].toString();
      if (counts.containsKey(id)) {
        counts[id]!['plays'] = (counts[id]!['plays'] as int) + 1;
      } else {
        counts[id] = {...h, 'plays': 1};
      }
    }

    final sorted = counts.values.toList()
      ..sort((a, b) => (b['plays'] as int).compareTo(a['plays'] as int));
    return sorted.take(10).toList();
  }

  List<Map<String, dynamic>> getTopArtists({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final filtered = _history.where((h) {
      final date = DateTime.tryParse(h['tocado_em'] ?? '');
      return date != null && date.isAfter(cutoff);
    }).toList();

    final counts = <String, Map<String, dynamic>>{};
    for (final h in filtered) {
      final artista = h['artista']?.toString() ?? '';
      if (counts.containsKey(artista)) {
        counts[artista]!['plays'] = (counts[artista]!['plays'] as int) + 1;
      } else {
        counts[artista] = {'artista': artista, 'capa': h['capa'], 'plays': 1};
      }
    }

    final sorted = counts.values.toList()
      ..sort((a, b) => (b['plays'] as int).compareTo(a['plays'] as int));
    return sorted.take(8).toList();
  }

  Map<String, double> getGenreDistribution() {
    if (_history.isEmpty) {
      return {'Pop': 35, 'Hip-Hop': 25, 'Electronic': 20, 'Rock': 15, 'Jazz': 5};
    }
    final counts = <String, int>{};
    for (final h in _history) {
      final g = h['genero']?.toString() ?? 'Pop';
      counts[g] = (counts[g] ?? 0) + 1;
    }
    final total = counts.values.fold(0, (a, b) => a + b).toDouble();
    return counts.map((k, v) => MapEntry(k, (v / total) * 100));
  }

  void clearHistory() async {
    _history = [];
    await _saveHistory();
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHistory, jsonEncode(_history));
    await prefs.setInt(_keyListeningTime, _totalMinutes);
  }
}
