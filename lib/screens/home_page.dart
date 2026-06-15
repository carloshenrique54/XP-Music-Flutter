import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/history_provider.dart';
import '../services/deezer_service.dart';
import '../services/auth_service.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/song_context_menu.dart';
import 'profile_page.dart';
import 'plans_page.dart';
import 'stats_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final deezer = DeezerService();
  final searchController = TextEditingController();

  List songs = [];
  bool loading = false;
  String _selectedGenre = 'lofi hip hop';

  final genres = [
    'lofi hip hop', 'pop', 'hip hop', 'rock', 'jazz',
    'electronic', 'sertanejo', 'funk', 'reggae', 'r&b',
  ];

  @override
  void initState() {
    super.initState();
    _search(_selectedGenre);
  }

  Future<void> _search(String query) async {
    setState(() => loading = true);
    try {
      songs = await deezer.searchSongs(query);
    } catch (e) {
      debugPrint('Erro: $e');
    }
    setState(() => loading = false);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final nome = user?['nome'] ?? 'Usuário';

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
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, ${nome.split(' ').first}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                          const Text(
                            'O que vamos ouvir?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Stats button
                    _HeaderBtn(
                      icon: Icons.bar_chart_rounded,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const StatsPage())),
                    ),
                    const SizedBox(width: 8),
                    // Plans button
                    _HeaderBtn(
                      icon: Icons.star_rounded,
                      color: const Color(0xFFFFD700),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PlansPage())),
                    ),
                    const SizedBox(width: 8),
                    // Avatar
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ProfilePage())),
                      child: _buildAvatar(user),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: _search,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar músicas...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white38),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded,
                            color: Color(0xFFA855F7)),
                        onPressed: () => _search(searchController.text.trim()),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Genre chips
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: genres.length,
                  itemBuilder: (_, i) {
                    final isSelected = genres[i] == _selectedGenre;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedGenre = genres[i]);
                        _search(genres[i]);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFFA855F7), Color(0xFF7E22CE)],
                                )
                              : null,
                          color: isSelected ? null : Colors.white.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.white12,
                          ),
                        ),
                        child: Text(
                          genres[i],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Banner
              _Banner(),
              const SizedBox(height: 12),

              // Song list
              Expanded(
                child: loading
                    ? ListView.builder(
                        itemCount: 6,
                        itemBuilder: (_, __) => const SongSkeletonCard(),
                      )
                    : ListView.builder(
                        itemCount: songs.length,
                        itemBuilder: (_, i) => _SongTile(song: songs[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic>? user) {
    final url = user?['avatar_url'] ?? '';
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
            colors: [Color(0xFFA855F7), Color(0xFF7E22CE)]),
        boxShadow: [
          BoxShadow(color: Colors.purple.withValues(alpha: .4), blurRadius: 12)
        ],
      ),
      child: url.isNotEmpty
          ? ClipOval(
              child: Image.network(url, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person,
                      color: Colors.white, size: 20)))
          : const Icon(Icons.person, color: Colors.white, size: 20),
    );
  }
}

class _Banner extends StatefulWidget {
  const _Banner();

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, String>> _slides = [
    {
      'image': 'assets/vinyl_nights.jpg',
      'title': 'Vinyl Nights',
      'subtitle': 'Sinta a vibe retrô do vinil indie',
    },
    {
      'image': 'assets/midnight_melodies.jpg',
      'title': 'Midnight Melodies',
      'subtitle': 'Sons noturnos para relaxar',
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (page) => setState(() => _currentPage = page),
        itemCount: _slides.length,
        itemBuilder: (context, i) {
          final slide = _slides[i];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(
                image: AssetImage(slide['image']!),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: .3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.all(18),
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slide['title']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    slide['subtitle']!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
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
    final title = song['title'] ?? 'Sem título';
    final artist = song['artist']?['name'] ?? 'Artista';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: cover.isNotEmpty
              ? Image.network(cover, width: 52, height: 52, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
              : _placeholder(),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

  Widget _placeholder() => Container(
        width: 52,
        height: 52,
        color: const Color(0xFF2A0B5A),
        child: const Icon(Icons.music_note, color: Colors.white54, size: 24),
      );
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeaderBtn({
    required this.icon,
    required this.onTap,
    this.color = Colors.white60,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
