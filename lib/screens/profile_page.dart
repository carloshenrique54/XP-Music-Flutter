import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../supabase_client.dart';
import '../providers/history_provider.dart';
import 'plans_page.dart';
import 'stats_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? _imageBytes;
  bool _uploading = false;
  bool _editingName = false;
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = AuthService.currentUser?['nome'] ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;

    try {
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _uploading = true;
      });

      final userId = AuthService.currentUser!['id'];
      final fileName = 'user_$userId.jpg';

      await supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = supabase.storage.from('avatars').getPublicUrl(fileName);
      await AuthService.updateProfile(
        avatarUrl: '$url?t=${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() => _uploading = false);
      _snack('Foto atualizada!');
    } catch (e) {
      setState(() => _uploading = false);
      _snack('Erro ao fazer upload: $e');
    }
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await AuthService.updateProfile(nome: name);
    setState(() => _editingName = false);
    _snack('Nome atualizado!');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF140826),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final nome = user?['nome'] ?? 'Usuário';
    final email = user?['email'] ?? '';
    final avatarUrl = user?['avatar_url'] ?? '';
    final history = context.watch<HistoryProvider>();
    final topArtists = history.getTopArtists(days: 30).take(4).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF080014),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF080014),
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                onPressed: _logout,
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Banner & Avatar Stack
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF4A0080),
                            Color(0xFF2A0B5A),
                            Color(0xFF1A0535),
                          ],
                        ),
                      ),
                      child: Opacity(
                        opacity: 0.15,
                        child: Container(
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                'https://images.unsplash.com/photo-1614680376573-df3480f0c6ff?w=400',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -45,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _AvatarWidget(
                          imageBytes: _imageBytes,
                          avatarUrl: avatarUrl,
                          uploading: _uploading,
                          onTap: _pickAndUpload,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 55),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Nome
                      if (_editingName)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameCtrl,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: .08,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _saveName,
                              icon: const Icon(
                                Icons.check_circle,
                                color: Color(0xFFA855F7),
                              ),
                            ),
                          ],
                        )
                      else
                        GestureDetector(
                          onTap: () => setState(() => _editingName = true),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                nome,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.edit_outlined,
                                color: Colors.white38,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Stats row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFA855F7).withValues(alpha: .12),
                              const Color(0xFF7E22CE).withValues(alpha: .08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem(
                              '${history.history.length}',
                              'Músicas\nouvidas',
                            ),
                            _vDiv(),
                            _statItem(
                              '${history.totalMinutes}',
                              'Minutos\nde música',
                            ),
                            _vDiv(),
                            _statItem(
                              '${history.getTopArtists().length}',
                              'Artistas\ncurtidos',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Artistas mais ouvidos
                      if (topArtists.isNotEmpty) ...[
                        const _SectionTitle('Mais ouvidos este mês'),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: topArtists.length,
                            itemBuilder: (_, i) {
                              final a = topArtists[i];
                              return _ArtistChip(artista: a);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Action buttons
                      _ActionBtn(
                        icon: Icons.bar_chart_rounded,
                        label: 'Estatísticas e Analytics',
                        color: const Color(0xFFA855F7),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StatsPage()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionBtn(
                        icon: Icons.star_rounded,
                        label: 'Planos e Assinaturas',
                        color: const Color(0xFFFFD700),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PlansPage()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionBtn(
                        icon: Icons.logout_rounded,
                        label: 'Sair da conta',
                        color: Colors.redAccent,
                        onTap: _logout,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String val, String label) => Column(
    children: [
      Text(
        val,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white54, fontSize: 11),
      ),
    ],
  );

  Widget _vDiv() => Container(width: 1, height: 36, color: Colors.white12);
}

class _AvatarWidget extends StatelessWidget {
  final Uint8List? imageBytes;
  final String avatarUrl;
  final bool uploading;
  final VoidCallback onTap;

  const _AvatarWidget({
    required this.imageBytes,
    required this.avatarUrl,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA855F7), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: .5),
                  blurRadius: 20,
                ),
              ],
            ),
            child: ClipOval(
              child: uploading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFA855F7),
                        strokeWidth: 2,
                      ),
                    )
                  : imageBytes != null
                  ? Image.memory(imageBytes!, fit: BoxFit.cover)
                  : avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFA855F7),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF2A0B5A),
    child: const Icon(Icons.person, color: Colors.white54, size: 44),
  );
}

class _ArtistChip extends StatelessWidget {
  final Map<String, dynamic> artista;
  const _ArtistChip({required this.artista});

  @override
  Widget build(BuildContext context) {
    final capa = artista['capa'] ?? '';
    final nome = artista['artista'] ?? '';

    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFA855F7), Color(0xFF7E22CE)],
              ),
            ),
            child: ClipOval(
              child: capa.isNotEmpty
                  ? Image.network(
                      capa,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, color: Colors.white),
                    )
                  : const Icon(Icons.person, color: Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              nome,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white30),
          ],
        ),
      ),
    );
  }
}
