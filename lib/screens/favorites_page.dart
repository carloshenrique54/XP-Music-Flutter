import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/history_provider.dart';
import '../supabase_client.dart';
import '../services/auth_service.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List _favorites = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = AuthService.currentUser?['id'];
    if (userId == null) return;
    setState(() => _loading = true);

    try {
      final res = await supabase
          .from('favoritos')
          .select()
          .eq('usuario_id', userId)
          .order('created_at', ascending: false);
      setState(() => _favorites = res);
    } catch (e) {
      debugPrint('Erro favoritos: $e');
    }

    setState(() => _loading = false);
  }

  Future<void> _removeFavorite(int id) async {
    await supabase.from('favoritos').delete().eq('id', id);
    setState(() => _favorites.removeWhere((f) => f['id'] == id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A0B5A), Color(0xFF140826), Color(0xFF080014)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    const Text(
                      '♥ Favoritos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_favorites.length} músicas',
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFA855F7)))
                    : _favorites.isEmpty
                        ? _empty()
                        : RefreshIndicator(
                            color: const Color(0xFFA855F7),
                            backgroundColor: const Color(0xFF140826),
                            onRefresh: _load,
                            child: ListView.builder(
                              itemCount: _favorites.length,
                              itemBuilder: (_, i) =>
                                  _FavTile(
                                    song: _favorites[i],
                                    onRemove: () =>
                                        _removeFavorite(_favorites[i]['id']),
                                  ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.pink.withValues(alpha: .1),
            ),
            child: const Icon(Icons.favorite_border,
                color: Colors.pink, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Nenhuma música favoritada',
              style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 6),
          const Text('Toque no ♥ para salvar músicas',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}

class _FavTile extends StatelessWidget {
  final Map<String, dynamic> song;
  final VoidCallback onRemove;

  const _FavTile({required this.song, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();
    final history = context.read<HistoryProvider>();
    final capa = song['capa'] ?? '';

    // Converte o formato do favorito para o formato do player
    final songForPlayer = {
      'id': song['track_id'],
      'title': song['titulo'],
      'artista': song['artista'],
      'capa': capa,
      'preview': song['preview_url'],
      'preview_url': song['preview_url'],
      'album': {'cover_medium': capa},
      'artist': {'name': song['artista']},
    };

    return Dismissible(
      key: Key(song['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: .2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) => onRemove(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: capa.isNotEmpty
                ? Image.network(capa,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ph())
                : _ph(),
          ),
          title: Text(
            song['titulo'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            song['artista'] ?? '',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.favorite, color: Colors.pink, size: 20),
            onPressed: onRemove,
          ),
          onTap: () {
            player.playSong(songForPlayer);
            history.addToHistory(songForPlayer);
          },
        ),
      ),
    );
  }

  Widget _ph() => Container(
        width: 52,
        height: 52,
        color: const Color(0xFF2A0B5A),
        child: const Icon(Icons.music_note, color: Colors.white54),
      );
}
