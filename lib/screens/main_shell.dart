import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../widgets/mini_player.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'library_page.dart';
import 'history_page.dart';
import 'favorites_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedIndex;

  final List<Widget> _pages = const [
    HomePage(),
    SearchPage(),
    LibraryPage(),
    HistoryPage(),
    FavoritesPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Restaura tab ativa do Provider (já carregado do SharedPreferences)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tab = context.read<PlayerProvider>().activeTab;
      setState(() => _selectedIndex = tab);
    });
    _selectedIndex = 0;
  }

  void _onTabTap(int index) {
    context.read<PlayerProvider>().setActiveTab(index);
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080014),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
      _NavItem(icon: Icons.search_rounded, label: 'Buscar', index: 1),
      _NavItem(icon: Icons.library_music_rounded, label: 'Biblioteca', index: 2),
      _NavItem(icon: Icons.history_rounded, label: 'Histórico', index: 3),
      _NavItem(icon: Icons.favorite_rounded, label: 'Favoritos', index: 4),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0020).withValues(alpha: .95),
        border: const Border(top: BorderSide(color: Colors.white10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) => _buildNavBtn(item)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBtn(_NavItem item) {
    final isActive = _selectedIndex == item.index;

    return GestureDetector(
      onTap: () => _onTabTap(item.index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    const Color(0xFFA855F7).withValues(alpha: .2),
                    const Color(0xFF7E22CE).withValues(alpha: .1),
                  ],
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                item.icon,
                color: isActive ? const Color(0xFFA855F7) : Colors.white38,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? const Color(0xFFA855F7) : Colors.white38,
              ),
              child: Text(item.label),
            ),
            // Indicador ativo
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(top: 3),
              width: isActive ? 16 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFFA855F7),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  const _NavItem({required this.icon, required this.label, required this.index});
}
