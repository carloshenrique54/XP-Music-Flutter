import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/history_provider.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _selectedDays = 7;
              break;
            case 1:
              _selectedDays = 30;
              break;
            case 2:
              _selectedDays = 365;
              break;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final topSongs = historyProvider.getTopSongs(days: _selectedDays);
    final topArtists = historyProvider.getTopArtists(days: _selectedDays);
    final genres = historyProvider.getGenreDistribution();
    final totalMin = historyProvider.totalMinutes;

    final formattedHours = (totalMin / 60).floor();
    final formattedMin = totalMin % 60;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Seu Report Musical',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFA855F7),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: '7 dias'),
            Tab(text: '30 dias'),
            Tab(text: 'Ano'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A0B5A), Color(0xFF140826), Color(0xFF080014)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Card Grid
                Row(
                  children: [
                    Expanded(
                      child: _StatMetricCard(
                        title: 'Tempo Ouvido',
                        value: formattedHours > 0 ? '${formattedHours}h ${formattedMin}m' : '${formattedMin}m',
                        icon: Icons.timer_rounded,
                        color: const Color(0xFFA855F7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatMetricCard(
                        title: 'Músicas Tocadas',
                        value: '${historyProvider.history.length}',
                        icon: Icons.music_note_rounded,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Genre Distribution
                const Text(
                  'Gêneros Mais Ouvidos',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildGenreChart(genres),
                const SizedBox(height: 28),

                // Top Songs
                const Text(
                  'Músicas Favoritas',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (topSongs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('Nenhuma música registrada neste período.', style: TextStyle(color: Colors.white38)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topSongs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final song = topSongs[index];
                      return _TopSongRow(index: index, song: song);
                    },
                  ),
                const SizedBox(height: 28),

                // Top Artists
                const Text(
                  'Artistas Mais Tocados',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (topArtists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('Nenhum artista registrado neste período.', style: TextStyle(color: Colors.white38)),
                    ),
                  )
                else
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: topArtists.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final artist = topArtists[index];
                        return _TopArtistItem(artist: artist);
                      },
                    ),
                  ),

                const SizedBox(height: 28),
                // User Reviews list
                const Text(
                  'Suas Avaliações',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildReviewsSection(context, historyProvider),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenreChart(Map<String, double> genres) {
    if (genres.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Sem dados suficientes para gerar gráfico',
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    final colors = [
      const Color(0xFFA855F7), // Primária
      const Color(0xFF7E22CE), // Secundária
      const Color(0xFF3B82F6), // Azul
      const Color(0xFF10B981), // Verde
      const Color(0xFFF59E0B), // Âmbar
      const Color(0xFFEC4899), // Rosa
    ];

    int colorIdx = 0;
    final entries = genres.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: entries.map((entry) {
                  final color = colors[colorIdx % colors.length];
                  colorIdx++;
                  return PieChartSectionData(
                    color: color,
                    value: entry.value,
                    title: '${entry.value.toStringAsFixed(0)}%',
                    radius: 35,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(entries.length, (i) {
                final entry = entries[i];
                final color = colors[i % colors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context, HistoryProvider historyProvider) {
    final reviews = historyProvider.reviews;
    if (reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const Text(
              'Você ainda não avaliou nenhuma música.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                _showAddReviewSheet(context, historyProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA855F7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Avaliar música do Histórico'),
            )
          ],
        ),
      );
    }

    final entries = reviews.entries.toList();
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length > 3 ? 3 : entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final review = entries[index].value;
            final trackId = entries[index].key;

            final song = historyProvider.history.firstWhere(
              (h) => h['id'].toString() == trackId,
              orElse: () => <String, dynamic>{},
            );

            final name = song['titulo'] ?? 'Música desconhecida';
            final artist = song['artista'] ?? 'Artista';
            final cover = song['capa'] ?? '';

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: cover.isNotEmpty
                        ? Image.network(cover, width: 44, height: 44, fit: BoxFit.cover)
                        : Container(width: 44, height: 44, color: Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          artist,
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(5, (starIdx) {
                            final filled = starIdx < (review['stars'] ?? 0);
                            return Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: filled ? Colors.amber : Colors.white10,
                            );
                          }),
                        ),
                        if (review['comment'] != null && (review['comment'] as String).isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '"${review['comment']}"',
                            style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 13),
                          ),
                        ]
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => _showAddReviewSheet(context, historyProvider),
            icon: const Icon(Icons.add, color: Color(0xFFA855F7)),
            label: const Text(
              'Avaliar Nova Música',
              style: TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold),
            ),
          ),
        )
      ],
    );
  }

  void _showAddReviewSheet(BuildContext context, HistoryProvider historyProvider) {
    final hist = historyProvider.history;
    if (hist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF140826),
          content: Text('Ouça uma música primeiro antes de avaliá-la!', style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    final seen = <String>{};
    final uniqueSongs = hist.where((s) => seen.add(s['id'].toString())).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF140826),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _AddReviewBottomSheet(
          songs: uniqueSongs,
          onSave: (songId, stars, comment) {
            historyProvider.addReview(songId, stars, comment);
            Navigator.pop(ctx);
          },
        );
      },
    );
  }
}

class _StatMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TopSongRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> song;
  const _TopSongRow({required this.index, required this.song});

  @override
  Widget build(BuildContext context) {
    final cover = song['capa'] ?? '';
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: index < 3 ? const Color(0xFFA855F7) : Colors.white38,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: cover.isNotEmpty
                ? Image.network(cover, width: 44, height: 44, fit: BoxFit.cover)
                : Container(width: 44, height: 44, color: Colors.purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song['titulo'] ?? '',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song['artista'] ?? '',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFA855F7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${song['plays']} plays',
              style: const TextStyle(color: Color(0xFFA855F7), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}

class _TopArtistItem extends StatelessWidget {
  final Map<String, dynamic> artist;
  const _TopArtistItem({required this.artist});

  @override
  Widget build(BuildContext context) {
    final cover = artist['capa'] ?? '';
    return SizedBox(
      width: 76,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA855F7), width: 1.5),
            ),
            child: ClipOval(
              child: cover.isNotEmpty
                  ? Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph())
                  : _ph(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            artist['artista'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            '${artist['plays']} plays',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _ph() => Container(
        color: const Color(0xFF2A0B5A),
        child: const Icon(Icons.person, color: Colors.white54, size: 24),
      );
}

class _AddReviewBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> songs;
  final Function(String songId, int stars, String comment) onSave;

  const _AddReviewBottomSheet({required this.songs, required this.onSave});

  @override
  State<_AddReviewBottomSheet> createState() => _AddReviewBottomSheetState();
}

class _AddReviewBottomSheetState extends State<_AddReviewBottomSheet> {
  late String _selectedSongId;
  int _stars = 5;
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSongId = widget.songs.first['id'].toString();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedSong = widget.songs.firstWhere((s) => s['id'].toString() == _selectedSongId);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escrever Avaliação',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Qual música deseja avaliar?', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSongId,
                dropdownColor: const Color(0xFF140826),
                isExpanded: true,
                items: widget.songs.map((s) {
                  return DropdownMenuItem<String>(
                    value: s['id'].toString(),
                    child: Text(
                      '${s['titulo']} - ${s['artista']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSongId = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Exibir capa e dados da música selecionada para avaliação
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (selectedSong['capa'] as String).isNotEmpty
                      ? Image.network(selectedSong['capa'], width: 48, height: 48, fit: BoxFit.cover)
                      : Container(
                          width: 48,
                          height: 48,
                          color: const Color(0xFF2A0B5A),
                          child: const Icon(Icons.music_note, color: Colors.white54),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedSong['titulo'] ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        selectedSong['artista'] ?? '',
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNum = index + 1;
              final isFilled = starNum <= _stars;
              return IconButton(
                icon: Icon(
                  Icons.star_rounded,
                  size: 38,
                  color: isFilled ? Colors.amber : Colors.white10,
                ),
                onPressed: () => setState(() => _stars = starNum),
              );
            }),
          ),
          const SizedBox(height: 16),
          const Text('Seu comentário (opcional)', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _commentCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'O que achou dessa música?',
              hintStyle: const TextStyle(color: Colors.white30),
              fillColor: Colors.white.withValues(alpha: 0.06),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => widget.onSave(_selectedSongId, _stars, _commentCtrl.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA855F7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Salvar Avaliação', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          )
        ],
      ),
    );
  }
}
