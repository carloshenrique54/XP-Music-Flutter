import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../supabase_client.dart';
import '../services/auth_service.dart';

/// Menu de contexto (3 pontos) para uma música
class SongContextMenu extends StatelessWidget {
  final Map<String, dynamic> song;

  const SongContextMenu({super.key, required this.song});

  String get titulo => song['title'] ?? song['titulo'] ?? 'Sem título';
  String get artista =>
      song['artist']?['name'] ?? song['artista'] ?? 'Artista';
  String get capa =>
      song['album']?['cover_medium'] ?? song['capa'] ?? '';
  String get preview => song['preview'] ?? song['preview_url'] ?? '';

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.more_vert, color: Colors.white54),
      onPressed: () => _showMenu(context),
    );
  }

  void _showMenu(BuildContext context) {
    final playlists = context.read<PlaylistProvider>().playlists;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF140826),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Song info
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: capa.isNotEmpty
                            ? Image.network(
                                capa,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 48,
                                  height: 48,
                                  color: const Color(0xFF2A0B5A),
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                color: const Color(0xFF2A0B5A),
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              artista,
                              style: const TextStyle(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10),

                // Adicionar à fila
                _MenuItem(
                  icon: Icons.queue_music,
                  label: 'Adicionar à fila',
                  onTap: () {
                    Navigator.pop(context);
                    context.read<PlayerProvider>().addToQueue(song);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF140826),
                        content: Text('$titulo adicionada à fila'),
                      ),
                    );
                  },
                ),

                // Favoritar
                _MenuItem(
                  icon: Icons.favorite_border,
                  label: 'Adicionar aos favoritos',
                  onTap: () async {
                    Navigator.pop(context);
                    await _addFavorite(context);
                  },
                ),

                // Adicionar à playlist
                _MenuItem(
                  icon: Icons.playlist_add,
                  label: 'Adicionar à playlist',
                  onTap: () {
                    Navigator.pop(context);
                    _showPlaylistPicker(context, playlists);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addFavorite(BuildContext context) async {
    final userId = AuthService.currentUser?['id'];
    if (userId == null) return;

    try {
      await supabase.from('favoritos').upsert({
        'usuario_id': userId,
        'track_id': song['id'],
        'titulo': titulo,
        'artista': artista,
        'capa': capa,
        'preview_url': preview,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF140826),
            content: Text('Adicionado aos favoritos!'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  void _showPlaylistPicker(
    BuildContext context,
    List<Map<String, dynamic>> playlists,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF140826),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Escolher playlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nenhuma playlist criada ainda',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              else
                ...playlists.map(
                  (pl) => ListTile(
                    leading: const Icon(
                      Icons.playlist_play,
                      color: Color(0xFFA855F7),
                    ),
                    title: Text(
                      pl['nome'] ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context
                          .read<PlaylistProvider>()
                          .addSongToPlaylist(pl['id'], song);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF140826),
                          content: Text(
                            'Adicionada a "${pl['nome']}"',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFA855F7)),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
