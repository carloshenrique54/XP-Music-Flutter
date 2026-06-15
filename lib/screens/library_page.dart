import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../providers/history_provider.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
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
          child: Consumer<PlaylistProvider>(
            builder: (_, provider, __) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(
                      children: [
                        const Text(
                          'Sua Biblioteca',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showCreateSheet(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFA855F7),
                                  Color(0xFF7E22CE),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (provider.loading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFA855F7)),
                      ),
                    )
                  else if (provider.playlists.isEmpty)
                    Expanded(child: _emptyState(context))
                  else
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFFA855F7),
                        backgroundColor: const Color(0xFF140826),
                        onRefresh: provider.refresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: provider.playlists.length,
                          itemBuilder: (_, i) =>
                              _PlaylistCard(playlist: provider.playlists[i]),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .06),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.library_music_rounded,
                color: Colors.white30, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma playlist ainda',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crie sua primeira playlist!',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateSheet(context),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Criar Playlist',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA855F7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF140826),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CreatePlaylistSheet(),
    );
  }
}

class _CreatePlaylistSheet extends StatefulWidget {
  const _CreatePlaylistSheet();

  @override
  State<_CreatePlaylistSheet> createState() => _CreatePlaylistSheetState();
}

class _CreatePlaylistSheetState extends State<_CreatePlaylistSheet> {
  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nome.text.trim().isEmpty) return;
    setState(() => _loading = true);

    await context.read<PlaylistProvider>().createPlaylist(
          nome: _nome.text.trim(),
          descricao: _descricao.text.trim(),
        );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Nova Playlist',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _field(_nome, 'Nome da playlist', Icons.playlist_play),
          const SizedBox(height: 12),
          _field(_descricao, 'Descrição (opcional)', Icons.description_outlined,
              maxLines: 2),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _create,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA855F7),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                  : const Text('Criar',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: const Color(0xFFA855F7), size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Map<String, dynamic> playlist;

  const _PlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final musicas = (playlist['playlist_musicas'] as List?) ?? [];
    final nome = playlist['nome'] ?? 'Sem nome';
    final capaUrl = playlist['capa_url'] ?? '';

    return GestureDetector(
      onTap: () => _openPlaylist(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFFA855F7), Color(0xFF7E22CE)],
                ),
              ),
              child: capaUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(capaUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.queue_music,
                                  color: Colors.white, size: 30)))
                  : const Icon(Icons.queue_music,
                      color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${musicas.length} música${musicas.length != 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: const Color(0xFF140826),
              icon: const Icon(Icons.more_vert, color: Colors.white38),
              onSelected: (v) {
                if (v == 'delete') {
                  context
                      .read<PlaylistProvider>()
                      .deletePlaylist(playlist['id']);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('Excluir',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openPlaylist(BuildContext context) {
    final musicas = (playlist['playlist_musicas'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0020),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (_, ctrl) => _PlaylistDetail(
            playlist: playlist,
            musicas: musicas,
            scrollController: ctrl,
          ),
        );
      },
    );
  }
}

class _PlaylistDetail extends StatelessWidget {
  final Map<String, dynamic> playlist;
  final List<Map<String, dynamic>> musicas;
  final ScrollController scrollController;

  const _PlaylistDetail({
    required this.playlist,
    required this.musicas,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();
    final history = context.read<HistoryProvider>();
    final nome = playlist['nome'] ?? '';

    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(nome,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ),
              if (musicas.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    player.playSong(musicas.first, queue: musicas);
                    history.addToHistory(musicas.first);
                  },
                  icon: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 18),
                  label:
                      const Text('Tocar', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA855F7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: musicas.isEmpty
              ? const Center(
                  child: Text('Nenhuma música nesta playlist',
                      style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: musicas.length,
                  itemBuilder: (_, i) {
                    final m = musicas[i];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: m['capa'] != null && m['capa'].isNotEmpty
                            ? Image.network(m['capa'],
                                width: 46, height: 46, fit: BoxFit.cover)
                            : Container(
                                width: 46,
                                height: 46,
                                color: const Color(0xFF2A0B5A),
                                child: const Icon(Icons.music_note,
                                    color: Colors.white)),
                      ),
                      title: Text(m['titulo'] ?? '',
                          style: const TextStyle(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text(m['artista'] ?? '',
                          style: const TextStyle(color: Colors.white54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.redAccent, size: 20),
                        onPressed: () {
                          context
                              .read<PlaylistProvider>()
                              .removeSongFromPlaylist(playlist['id'], i);
                          Navigator.pop(context);
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        player.playSong(m, queue: musicas);
                        history.addToHistory(m);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
