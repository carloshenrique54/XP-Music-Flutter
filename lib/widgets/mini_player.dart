import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import 'equalizer_bars.dart';
import '../screens/player_page.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        if (player.currentSong == null) return const SizedBox.shrink();

        final song = player.currentSong!;
        final capa = song['album']?['cover_medium'] ?? song['capa'] ?? '';
        final titulo = song['title'] ?? song['titulo'] ?? '';
        final artista = song['artist']?['name'] ?? song['artista'] ?? '';
        final progress = player.duration.inSeconds > 0
            ? player.position.inSeconds / player.duration.inSeconds
            : 0.0;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => PlayerPage(song: song),
                transitionsBuilder: (_, anim, __, child) => SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF2A0B5A), Color(0xFF140826)],
              ),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: .3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: Row(
                    children: [
                      // Capa animada
                      _AlbumCover(capa: capa, isPlaying: player.isPlaying),
                      const SizedBox(width: 10),

                      // Título + artista
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
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    artista,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                EqualizerBars(
                                  isPlaying: player.isPlaying,
                                  barCount: 3,
                                  width: 20,
                                  height: 14,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Controles centro
                      _ControlBtn(
                        icon: Icons.skip_previous_rounded,
                        size: 22,
                        onTap: () => player.playPrevious(),
                      ),
                      const SizedBox(width: 4),
                      _PlayPauseBtn(isPlaying: player.isPlaying, player: player),
                      const SizedBox(width: 4),
                      _ControlBtn(
                        icon: Icons.skip_next_rounded,
                        size: 22,
                        onTap: () => player.playNext(),
                      ),

                      const SizedBox(width: 8),

                      // Volume mudo
                      _ControlBtn(
                        icon: player.muted ? Icons.volume_off : Icons.volume_up,
                        size: 20,
                        color: player.muted ? Colors.white30 : Colors.white60,
                        onTap: () => player.toggleMute(),
                      ),
                    ],
                  ),
                ),

                // Barra de progresso
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Text(
                        _formatDuration(player.position),
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),
                            overlayShape: SliderComponentShape.noOverlay,
                            activeTrackColor: const Color(0xFFA855F7),
                            inactiveTrackColor: Colors.white12,
                            thumbColor: const Color(0xFFA855F7),
                          ),
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            onChanged: (v) {
                              final pos = Duration(
                                seconds: (v * player.duration.inSeconds).toInt(),
                              );
                              player.seekTo(pos);
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(player.duration),
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlbumCover extends StatefulWidget {
  final String capa;
  final bool isPlaying;

  const _AlbumCover({required this.capa, required this.isPlaying});

  @override
  State<_AlbumCover> createState() => _AlbumCoverState();
}

class _AlbumCoverState extends State<_AlbumCover>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(_AlbumCover old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: .4),
              blurRadius: 12,
            ),
          ],
        ),
        child: ClipOval(
          child: widget.capa.isNotEmpty
              ? Image.network(
                  widget.capa,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF2A0B5A),
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                )
              : Container(
                  color: const Color(0xFF2A0B5A),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
        ),
      ),
    );
  }
}

class _PlayPauseBtn extends StatelessWidget {
  final bool isPlaying;
  final PlayerProvider player;

  const _PlayPauseBtn({required this.isPlaying, required this.player});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => player.togglePlay(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFA855F7), Color(0xFF7E22CE)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: .5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    required this.onTap,
    this.size = 22,
    this.color = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: size),
    );
  }
}
