import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/equalizer_bars.dart';

class PlayerPage extends StatelessWidget {
  final Map<String, dynamic> song;

  const PlayerPage({super.key, required this.song});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final history = context.read<HistoryProvider>();

    final capa = song['album']?['cover_big'] ??
        song['album']?['cover_medium'] ??
        song['capa'] ??
        '';
    final titulo = song['title'] ?? song['titulo'] ?? '';
    final artista = song['artist']?['name'] ?? song['artista'] ?? '';

    final progress = player.duration.inSeconds > 0
        ? player.position.inSeconds / player.duration.inSeconds
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF080014),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white, size: 32),
                    ),
                    const Expanded(
                      child: Column(
                        children: [
                          Text('Tocando agora',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showReview(context, history, titulo),
                      icon: const Icon(Icons.star_outline_rounded,
                          color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Album cover
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple
                          .withValues(alpha: player.isPlaying ? .6 : .3),
                      blurRadius: player.isPlaying ? 60 : 30,
                      spreadRadius: player.isPlaying ? 8 : 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: AnimatedScale(
                    scale: player.isPlaying ? 1.0 : 0.9,
                    duration: const Duration(milliseconds: 300),
                    child: capa.isNotEmpty
                        ? Image.network(capa,
                            height: 300,
                            width: 300,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _coverPlaceholder())
                        : _coverPlaceholder(),
                  ),
                ),
              ),

              const Spacer(),

              // Title + artist + equalizer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  children: [
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            artista,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    EqualizerBars(
                      isPlaying: player.isPlaying,
                      barCount: 4,
                      width: 32,
                      height: 22,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: const Color(0xFFA855F7),
                        inactiveTrackColor: Colors.white12,
                        thumbColor: const Color(0xFFA855F7),
                        overlayColor:
                            const Color(0xFFA855F7).withValues(alpha: .2),
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (v) {
                          final pos = Duration(
                            seconds:
                                (v * player.duration.inSeconds).toInt(),
                          );
                          player.seekTo(pos);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(player.position),
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                          Text(_fmt(player.duration),
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Shuffle
                    _CtrlBtn(
                      icon: Icons.shuffle_rounded,
                      size: 22,
                      color: player.shuffle
                          ? const Color(0xFFA855F7)
                          : Colors.white38,
                      onTap: player.toggleShuffle,
                    ),
                    // Previous
                    _CtrlBtn(
                      icon: Icons.skip_previous_rounded,
                      size: 34,
                      onTap: () {
                        player.playPrevious();
                      },
                    ),
                    // Play/Pause
                    GestureDetector(
                      onTap: () {
                        if (!player.isPlaying &&
                            player.currentSong?['id'] != song['id']) {
                          player.playSong(song);
                          history.addToHistory(song);
                        } else {
                          player.togglePlay();
                        }
                      },
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA855F7), Color(0xFF7E22CE)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withValues(alpha: .6),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Icon(
                          player.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                    // Next
                    _CtrlBtn(
                      icon: Icons.skip_next_rounded,
                      size: 34,
                      onTap: () {
                        player.playNext();
                      },
                    ),
                    // Repeat
                    _CtrlBtn(
                      icon: player.repeat
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      size: 22,
                      color: player.repeat
                          ? const Color(0xFFA855F7)
                          : Colors.white38,
                      onTap: player.toggleRepeat,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Volume
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: player.toggleMute,
                      child: Icon(
                        player.muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_down_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          activeTrackColor: const Color(0xFFA855F7),
                          inactiveTrackColor: Colors.white12,
                          thumbColor: const Color(0xFFA855F7),
                        ),
                        child: Slider(
                          value: player.volume,
                          onChanged: player.setVolume,
                        ),
                      ),
                    ),
                    const Icon(Icons.volume_up_rounded,
                        color: Colors.white38, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() => Container(
        height: 300,
        width: 300,
        color: const Color(0xFF140826),
        child: const Icon(Icons.music_note, color: Colors.white, size: 80),
      );

  void _showReview(BuildContext context, HistoryProvider history, String titulo) {
    final trackId = song['id']?.toString() ?? titulo;
    final existing = history.getReview(trackId);
    int stars = existing?['stars'] ?? 0;
    final commentCtrl =
        TextEditingController(text: existing?['comment'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF140826),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModal) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Avaliar música',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(titulo,
                    style: const TextStyle(color: Colors.white54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setModal(() => stars = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0xFFFFD700),
                          size: 36,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Escreva uma resenha...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      history.addReview(trackId, stars, commentCtrl.text);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF140826),
                          content: Text('Avaliação salva!',
                              style: TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA855F7),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Salvar avaliação',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;

  const _CtrlBtn({
    required this.icon,
    required this.onTap,
    this.size = 26,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: size),
    );
  }
}
