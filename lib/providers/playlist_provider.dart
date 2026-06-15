import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../supabase_client.dart';
import '../services/auth_service.dart';

class PlaylistProvider extends ChangeNotifier {
  static const _keyPlaylists = 'xp_playlists_local';

  List<Map<String, dynamic>> _playlists = [];
  bool _loading = false;

  List<Map<String, dynamic>> get playlists => _playlists;
  bool get loading => _loading;

  PlaylistProvider() {
    _load();
  }

  Future<void> _load() async {
    await _loadFromSupabase();
  }

  Future<void> _loadFromSupabase() async {
    if (AuthService.currentUser == null) return;
    _loading = true;
    notifyListeners();

    try {
      final userId = AuthService.currentUser!['id'];

      final playlistsRes = await supabase
          .from('playlists')
          .select('*, playlist_musicas(*)')
          .eq('usuario_id', userId)
          .order('created_at', ascending: false);

      _playlists = List<Map<String, dynamic>>.from(playlistsRes);
    } catch (e) {
      // Fallback para local
      await _loadLocal();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyPlaylists);
    if (json != null) {
      _playlists = List<Map<String, dynamic>>.from(jsonDecode(json));
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlaylists, jsonEncode(_playlists));
  }

  Future<void> createPlaylist({
    required String nome,
    String descricao = '',
    String capaUrl = '',
  }) async {
    final userId = AuthService.currentUser?['id'];
    if (userId == null) return;

    try {
      final res = await supabase
          .from('playlists')
          .insert({
            'usuario_id': userId,
            'nome': nome,
            'descricao': descricao,
            'capa_url': capaUrl,
          })
          .select()
          .single();

      _playlists.insert(0, {...res, 'playlist_musicas': []});
      await _saveLocal();
      notifyListeners();
    } catch (e) {
      // Salvar local se falhar
      final local = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'usuario_id': userId,
        'nome': nome,
        'descricao': descricao,
        'capa_url': capaUrl,
        'playlist_musicas': [],
        'created_at': DateTime.now().toIso8601String(),
      };
      _playlists.insert(0, local);
      await _saveLocal();
      notifyListeners();
    }
  }

  Future<void> deletePlaylist(dynamic playlistId) async {
    try {
      await supabase.from('playlists').delete().eq('id', playlistId);
    } catch (_) {}

    _playlists.removeWhere((p) => p['id'] == playlistId);
    await _saveLocal();
    notifyListeners();
  }

  Future<void> addSongToPlaylist(dynamic playlistId, Map<String, dynamic> song) async {
    try {
      await supabase.from('playlist_musicas').insert({
        'playlist_id': playlistId,
        'track_id': song['id'],
        'titulo': song['title'] ?? song['titulo'] ?? '',
        'artista': song['artist']?['name'] ?? song['artista'] ?? '',
        'capa': song['album']?['cover_medium'] ?? song['capa'] ?? '',
        'preview_url': song['preview'] ?? song['preview_url'] ?? '',
      });
    } catch (_) {}

    final idx = _playlists.indexWhere((p) => p['id'] == playlistId);
    if (idx >= 0) {
      final musicas = List<Map<String, dynamic>>.from(
        _playlists[idx]['playlist_musicas'] ?? [],
      );
      musicas.add({
        'track_id': song['id'],
        'titulo': song['title'] ?? song['titulo'] ?? '',
        'artista': song['artist']?['name'] ?? song['artista'] ?? '',
        'capa': song['album']?['cover_medium'] ?? song['capa'] ?? '',
        'preview_url': song['preview'] ?? song['preview_url'] ?? '',
      });
      _playlists[idx] = {..._playlists[idx], 'playlist_musicas': musicas};
      await _saveLocal();
      notifyListeners();
    }
  }

  Future<void> removeSongFromPlaylist(dynamic playlistId, int trackIndex) async {
    final idx = _playlists.indexWhere((p) => p['id'] == playlistId);
    if (idx < 0) return;

    final musicas = List<Map<String, dynamic>>.from(
      _playlists[idx]['playlist_musicas'] ?? [],
    );
    if (trackIndex < musicas.length) {
      musicas.removeAt(trackIndex);
      _playlists[idx] = {..._playlists[idx], 'playlist_musicas': musicas};
      await _saveLocal();
      notifyListeners();
    }
  }

  Future<void> refresh() => _loadFromSupabase();
}
