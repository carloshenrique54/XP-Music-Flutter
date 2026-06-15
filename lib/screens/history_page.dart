import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../providers/player_provider.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

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
          child: Consumer<HistoryProvider>(
            builder: (_, history, __) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(
                      children: [
                        const Text(
                          'Histórico',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (history.history.isNotEmpty)
                          TextButton(
                            onPressed: () => _confirmClear(context, history),
                            child: const Text(
                              'Limpar',
                              style: TextStyle(color: Colors.white38),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Stat summary
                  if (history.history.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _StatSummary(history: history),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: history.history.isEmpty
                        ? _empty()
                        : ListView.builder(
                            itemCount: history.history.length,
                            itemBuilder: (_, i) =>
                                _HistoryTile(song: history.history[i]),
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
              color: Colors.white.withValues(alpha: .06),
            ),
            child: const Icon(Icons.history_rounded,
                color: Colors.white30, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Nenhuma música ouvida',
              style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 6),
          const Text('Comece a ouvir para ver o histórico',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, HistoryProvider history) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF140826),
        title: const Text('Limpar histórico',
            style: TextStyle(color: Colors.white)),
        content: const Text('Isso removerá todo o histórico de reprodução.',
            style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              history.clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Limpar',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _StatSummary extends StatelessWidget {
  final HistoryProvider history;
  const _StatSummary({required this.history});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFA855F7).withValues(alpha: .15),
              const Color(0xFF7E22CE).withValues(alpha: .08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('${history.history.length}', 'Músicas'),
            _divider(),
            _stat('${history.totalMinutes}min', 'Ouvidos'),
            _divider(),
            _stat('${history.getTopArtists().length}', 'Artistas'),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 30,
        color: Colors.white12,
      );
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> song;
  const _HistoryTile({required this.song});

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();
    final history = context.read<HistoryProvider>();
    final capa = song['capa'] ?? '';
    final titulo = song['titulo'] ?? '';
    final artista = song['artista'] ?? '';
    final tocadoEm = DateTime.tryParse(song['tocado_em'] ?? '');
    final timeAgo = tocadoEm != null ? _timeAgo(tocadoEm) : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: capa.isNotEmpty
              ? Image.network(capa,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _ph())
              : _ph(),
        ),
        title: Text(
          titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          artista,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        trailing: Text(
          timeAgo,
          style: const TextStyle(color: Colors.white30, fontSize: 11),
        ),
        onTap: () {
          player.playSong(song);
          history.addToHistory(song);
        },
      ),
    );
  }

  Widget _ph() => Container(
        width: 50,
        height: 50,
        color: const Color(0xFF2A0B5A),
        child: const Icon(Icons.music_note, color: Colors.white54),
      );

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}
