import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/history_provider.dart';
import '../services/deezer_service.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/song_context_menu.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final deezer = DeezerService();
  final _controller = TextEditingController();

  List _results = [];
  bool _loading = false;
  bool _searched = false;

  final List<Map<String, String>> _categories = [
    {'label': 'Indie Rock', 'query': 'indie rock'},
    {'label': 'Indie Pop', 'query': 'indie pop'},
    {'label': 'Indie Folk', 'query': 'indie folk'},
    {'label': 'Dream Pop', 'query': 'dream pop'},
    {'label': 'Shoegaze', 'query': 'shoegaze'},
    {'label': 'Post-Punk', 'query': 'post punk'},
    {'label': 'Lo-Fi', 'query': 'lo-fi indie'},
    {'label': 'Indie Alternativo', 'query': 'alternative indie'},
  ];

  final List<String> _indieArtists = [
    'Arctic Monkeys',
    'Mac DeMarco',
    'Tame Impala',
    'Beach House',
    'Boy Pablo',
    'Alvvays',
    'MGMT',
    'Phoebe Bridgers',
    'The Smiths',
    'The Strokes',
    'Radiohead',
    'Wallows',
  ];

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _searched = true;
    });
    _results = await deezer.searchSongs(q.trim());
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                      'Buscar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_searched)
                      TextButton(
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _results = [];
                            _searched = false;
                          });
                        },
                        child: const Text(
                          'Limpar',
                          style: TextStyle(color: Color(0xFFA855F7)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    autofocus: false,
                    onSubmitted: _search,
                    decoration: InputDecoration(
                      hintText: 'Artistas, músicas, álbuns...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white38),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded,
                            color: Color(0xFFA855F7)),
                        onPressed: () => _search(_controller.text),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: !_searched
                    ? _buildTrending()
                    : _loading
                        ? ListView.builder(
                            itemCount: 6,
                            itemBuilder: (_, __) => const SongSkeletonCard(),
                          )
                        : _results.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nenhum resultado',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _results.length,
                                itemBuilder: (_, i) =>
                                    _SongTile(song: _results[i]),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrending() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subgêneros Indie
          const Text(
            'Subgêneros Indie',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              return GestureDetector(
                onTap: () {
                  _controller.text = cat['label']!;
                  _search(cat['query']!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFA855F7).withValues(alpha: .2),
                        const Color(0xFF7E22CE).withValues(alpha: .1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.music_note_rounded,
                          color: Color(0xFFA855F7), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        cat['label']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // Artistas em alta
          const Text(
            'Artistas em alta',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _indieArtists.map((artist) {
              return GestureDetector(
                onTap: () {
                  _controller.text = artist;
                  _search(artist);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up,
                          color: Colors.purpleAccent, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        artist,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final dynamic song;
  const _SongTile({required this.song});

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();
    final history = context.read<HistoryProvider>();
    final cover = song['album']?['cover_medium'] ?? '';

    return Container(
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
          child: cover.isNotEmpty
              ? Image.network(cover,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _ph())
              : _ph(),
        ),
        title: Text(
          song['title'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          song['artist']?['name'] ?? '',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: SongContextMenu(song: song),
        onTap: () {
          player.playSong(song);
          history.addToHistory(song);
        },
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
