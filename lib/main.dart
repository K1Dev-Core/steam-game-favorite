import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'data/game_database.dart';
import 'models/steam_game.dart';
import 'pages/auth_page.dart';
import 'pages/backlog_page.dart';
import 'pages/community_page.dart';
import 'pages/game_editor_page.dart';
import 'pages/recommended_games_page.dart';
import 'repositories/game_repository.dart';
import 'services/firestore_game_repository.dart';
import 'widgets/ios_navigation_bar.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/game_artwork.dart';
import 'widgets/game_review_section.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SteamFavoriteApp());
}

const genres = [
  'ทั้งหมด',
  'Action',
  'Adventure',
  'FPS',
  'RPG',
  'Survival',
  'Strategy',
  'Simulation',
  'อื่น ๆ',
];

const genreIcons = [
  CupertinoIcons.square_grid_2x2_fill,
  CupertinoIcons.bolt_fill,
  CupertinoIcons.map_fill,
  CupertinoIcons.scope,
  CupertinoIcons.shield_fill,
  CupertinoIcons.flag_fill,
  CupertinoIcons.building_2_fill,
  CupertinoIcons.gear_solid,
  CupertinoIcons.game_controller_solid,
];

IconData _genreIcon(String genre) {
  final index = genres.indexOf(genre);
  return genreIcons[index >= 0 ? index : genreIcons.length - 1];
}

const cardColors = [
  Color(0xFFEAF2FF),
  Color(0xFFE8F8F3),
  Color(0xFFFFF4E5),
  Color(0xFFFFEAF1),
  Color(0xFFEAF8E8),
];

const iconColors = [
  Color(0xFF3478F6),
  Color(0xFF159A86),
  Color(0xFFE58A00),
  Color(0xFFE54779),
  Color(0xFF36A269),
];

class SteamFavoriteApp extends StatelessWidget {
  const SteamFavoriteApp({super.key, this.repository, this.auth});
  final GameRepository? repository;
  final FirebaseAuth? auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Steam Game Favorite',
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFF2F2F7),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: kIsWeb ? 820 : 600),
            child: child!,
          ),
        ),
      ),
      theme: ThemeData(
        useMaterial3: true,
        platform: TargetPlatform.iOS,
        fontFamily: '.SF Pro Text',
        cupertinoOverrideTheme: const CupertinoThemeData(
          primaryColor: Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF007AFF),
          secondary: Color(0xFF007AFF),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            minimumSize: const Size(44, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shadowColor: const Color(0x120C1B33),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0x0A15233B)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFFF2F2F7),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: repository != null
          ? MainPage(repository: repository!)
          : AuthGate(auth: auth),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.auth});
  final FirebaseAuth? auth;

  FirebaseAuth get _auth => auth ?? FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: _auth.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.data == null) return AuthPage(auth: _auth);
      return MainPage(
        repository: FirestoreGameRepository(auth: _auth),
        user: snapshot.data,
        onSignOut: _auth.signOut,
      );
    },
  );
}

class MainPage extends StatefulWidget {
  const MainPage({
    super.key,
    required this.repository,
    this.user,
    this.onSignOut,
  });
  final GameRepository repository;
  final User? user;
  final Future<void> Function()? onSignOut;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addGame() async {
    final saved = await Navigator.push<SteamGame>(
      context,
      MaterialPageRoute(
        builder: (_) => GameEditorPage(repository: widget.repository),
      ),
    );
    if (saved != null && mounted) {
      _searchController.clear();
      setState(() {
        _selectedGenre = 'ทั้งหมด';
        _favoritesOnly = false;
      });
    }
  }

  int _selectedTab = 0;
  String _selectedGenre = 'ทั้งหมด';
  bool _favoritesOnly = false;

  List<SteamGame> _filteredGames(List<SteamGame> games) {
    return games.where((game) {
      final genreMatches =
          _selectedGenre == 'ทั้งหมด' || game.genre == _selectedGenre;
      final favoriteMatches = !_favoritesOnly || game.isFavorite;
      final titleMatches = game.title.toLowerCase().contains(
        _searchController.text.trim().toLowerCase(),
      );
      return genreMatches && favoriteMatches && titleMatches;
    }).toList();
  }

  Future<void> _openDetail(SteamGame game) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GameDetailPage(game: game, repository: widget.repository),
      ),
    );
  }

  Future<void> _openBacklog() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BacklogPage(
          database: createGameDatabase(),
          ownerId: widget.user?.uid ?? 'local-preview',
        ),
      ),
    );
  }

  Widget _cloudGameList() => StreamBuilder<List<SteamGame>>(
    stream: widget.repository.watchGames(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting &&
          !snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 56, color: Colors.blueGrey),
                const SizedBox(height: 12),
                const Text('โหลดข้อมูลจาก Cloud ไม่สำเร็จ'),
                const SizedBox(height: 6),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        );
      }
      final games = snapshot.data ?? const <SteamGame>[];
      return GameListPage(
        games: _filteredGames(games),
        totalCount: games.length,
        searchController: _searchController,
        onSearchChanged: (_) => setState(() {}),
        onClearFilters: () => setState(() {
          _searchController.clear();
          _selectedGenre = 'ทั้งหมด';
          _favoritesOnly = false;
        }),
        selectedGenre: _selectedGenre,
        favoritesOnly: _favoritesOnly,
        onFavoritesChanged: (value) => setState(() => _favoritesOnly = value),
        onGenreChanged: (value) => setState(() => _selectedGenre = value),
        onGameTap: _openDetail,
        onAdd: _addGame,
        onBacklog: _openBacklog,
      );
    },
  );

  Widget _cloudStatistics() => StreamBuilder<List<SteamGame>>(
    stream: widget.repository.watchGames(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting &&
          !snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return const Center(child: Text('โหลดสถิติไม่สำเร็จ กรุณาลองใหม่'));
      }
      return GameStatisticsPage(games: snapshot.data ?? const <SteamGame>[]);
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _cloudGameList(),
          RecommendedGamesPage(
            repository: widget.repository,
            onSaved: () {
              _searchController.clear();
              setState(() {
                _selectedGenre = 'ทั้งหมด';
                _favoritesOnly = false;
                _selectedTab = 0;
              });
            },
          ),
          const CommunityPage(),
          _cloudStatistics(),
          AboutPage(user: widget.user, onSignOut: widget.onSignOut),
        ],
      ),
      bottomNavigationBar: CupertinoTabBar(
        backgroundColor: const Color(0xFAFFFFFF),
        activeColor: const Color(0xFF007AFF),
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.game_controller),
            activeIcon: Icon(CupertinoIcons.game_controller_solid),
            label: 'เกมโปรด',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.compass),
            activeIcon: Icon(CupertinoIcons.compass_fill),
            label: 'ค้นพบเกม',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble_2),
            activeIcon: Icon(CupertinoIcons.chat_bubble_2_fill),
            label: 'ชุมชน',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar),
            activeIcon: Icon(CupertinoIcons.chart_bar_fill),
            label: 'สถิติ',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_crop_circle),
            activeIcon: Icon(CupertinoIcons.person_crop_circle_fill),
            label: 'เกี่ยวกับ',
          ),
        ],
      ),
    );
  }
}

class GameListPage extends StatefulWidget {
  final List<SteamGame> games;
  final int totalCount;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearFilters;
  final String selectedGenre;
  final bool favoritesOnly;
  final ValueChanged<bool> onFavoritesChanged;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<SteamGame> onGameTap;
  final VoidCallback onAdd;
  final VoidCallback onBacklog;

  const GameListPage({
    super.key,
    required this.games,
    required this.totalCount,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearFilters,
    required this.selectedGenre,
    required this.favoritesOnly,
    required this.onFavoritesChanged,
    required this.onGenreChanged,
    required this.onGameTap,
    required this.onAdd,
    required this.onBacklog,
  });

  @override
  State<GameListPage> createState() => _GameListPageState();
}

class _GameListPageState extends State<GameListPage> {
  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4D9BFF), Color(0xFF0066E8)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF007AFF,
                              ).withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.game_controller_solid,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'เกมโปรด',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.totalCount} เกมที่บันทึกบน Cloud',
                    style: const TextStyle(
                      color: CupertinoColors.secondaryLabel,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'เกมที่อยากเล่น — บันทึกในเครื่อง',
              onPressed: widget.onBacklog,
              icon: const Icon(CupertinoIcons.bookmark),
            ),
            IconButton.filled(
              tooltip: 'เพิ่มเกมใหม่',
              onPressed: widget.onAdd,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(CupertinoIcons.add, size: 23),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          key: const Key('gameSearch'),
          controller: widget.searchController,
          onChanged: widget.onSearchChanged,
          decoration: InputDecoration(
            hintText: 'ค้นหาจากชื่อเกม',
            prefixIcon: const Icon(
              CupertinoIcons.search,
              color: Color(0xFF007AFF),
            ),
            suffixIcon: widget.searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'ล้างคำค้น',
                    onPressed: () {
                      widget.searchController.clear();
                      widget.onSearchChanged('');
                    },
                    icon: const Icon(CupertinoIcons.xmark_circle_fill),
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ChoiceChip(
          showCheckmark: false,
          avatar: Icon(
            CupertinoIcons.heart_fill,
            size: 15,
            color: widget.favoritesOnly
                ? Colors.white
                : const Color(0xFF007AFF),
          ),
          label: const Text('รายการโปรดเท่านั้น'),
          selected: widget.favoritesOnly,
          onSelected: widget.onFavoritesChanged,
          selectedColor: const Color(0xFF007AFF),
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: widget.favoritesOnly ? Colors.white : Colors.black87,
            fontSize: 13,
          ),
          side: BorderSide.none,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: genres.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final genre = genres[index];
              final selected = genre == widget.selectedGenre;
              return ChoiceChip(
                showCheckmark: false,
                avatar: Icon(
                  genreIcons[index],
                  size: 15,
                  color: selected ? Colors.white : const Color(0xFF007AFF),
                ),
                label: Text(genre),
                selected: selected,
                onSelected: (_) => widget.onGenreChanged(genre),
                selectedColor: const Color(0xFF007AFF),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontSize: 13,
                ),
                side: BorderSide.none,
              );
            },
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.games.isEmpty ? 2 : widget.games.length + 1;
    return Scaffold(
      appBar: IosNavigationBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF).withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.game_controller_solid,
                size: 14,
                color: Color(0xFF007AFF),
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.totalCount} เกม',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0067D8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) return _header(context);
          if (widget.games.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  const Icon(
                    CupertinoIcons.game_controller,
                    size: 72,
                    color: Color(0xFF007AFF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.totalCount == 0
                        ? 'ยังไม่มีเกมในรายการนี้'
                        : 'ไม่พบเกมที่ตรงกับตัวกรอง',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.totalCount == 0
                        ? 'กดปุ่ม + เพื่อเพิ่มเกมแรกของคุณ'
                        : 'ลองค้นหาคำอื่น หรือเลือกอารมณ์ทั้งหมด',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: widget.totalCount == 0
                        ? widget.onAdd
                        : widget.onClearFilters,
                    icon: Icon(
                      widget.totalCount == 0 ? Icons.add : Icons.filter_alt_off,
                    ),
                    label: Text(
                      widget.totalCount == 0 ? 'เพิ่มเกมแรก' : 'ล้างตัวกรอง',
                    ),
                  ),
                ],
              ),
            );
          }

          final gameIndex = index - 1;
          final game = widget.games[gameIndex];
          final cardColor = cardColors[gameIndex % cardColors.length];
          final iconColor = iconColors[gameIndex % iconColors.length];
          return TweenAnimationBuilder<double>(
            key: ValueKey(game.id ?? game.title),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(
              milliseconds: 240 + (gameIndex.clamp(0, 4) * 35),
            ),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: child,
              ),
            ),
            child: Card(
              color: Colors.white,
              elevation: 1,
              shadowColor: iconColor.withValues(alpha: 0.1),
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: iconColor.withValues(alpha: 0.12)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: Hero(
                  tag: 'game-art-${game.id ?? game.appId}',
                  child: _GameThumbnail(
                    url: game.imageUrl,
                    iconColor: iconColor,
                  ),
                ),
                title: Text(
                  game.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              game.genre,
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StarRating(rating: game.rating, iconSize: 14),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (game.isFavorite) ...[
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEF3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.heart_fill,
                          color: Color(0xFFE54779),
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 9),
                    ],
                    const Icon(
                      CupertinoIcons.chevron_right,
                      size: 17,
                      color: Color(0xFF9AA3B2),
                    ),
                  ],
                ),
                onTap: () => widget.onGameTap(game),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GameThumbnail extends StatelessWidget {
  final String url;
  final Color iconColor;

  const _GameThumbnail({required this.url, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 96,
        height: 64,
        child: url.isEmpty
            ? _fallback()
            : GameArtwork(source: url, placeholder: _fallback(loading: true)),
      ),
    );
  }

  Widget _fallback({bool loading = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            iconColor.withValues(alpha: 0.1),
            iconColor.withValues(alpha: 0.22),
          ],
        ),
      ),
      child: loading
          ? Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              ),
            )
          : Icon(
              CupertinoIcons.game_controller_solid,
              color: iconColor,
              size: 28,
            ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Text(
              value,
              key: ValueKey(value),
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    ),
  );
}

class GameStatisticsPage extends StatefulWidget {
  const GameStatisticsPage({super.key, required this.games});

  final List<SteamGame> games;

  @override
  State<GameStatisticsPage> createState() => _GameStatisticsPageState();
}

class _GameStatisticsPageState extends State<GameStatisticsPage> {
  String _selectedGenre = 'ทั้งหมด';

  @override
  Widget build(BuildContext context) {
    final games = widget.games;
    final totals = <String, int>{};
    for (final game in games) {
      totals.update(game.genre, (count) => count + 1, ifAbsent: () => 1);
    }
    final categories = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final availableGenres = [
      'ทั้งหมด',
      ...categories.map((entry) => entry.key),
    ];
    if (!availableGenres.contains(_selectedGenre)) _selectedGenre = 'ทั้งหมด';
    final selectedGames = _selectedGenre == 'ทั้งหมด'
        ? games
        : games.where((game) => game.genre == _selectedGenre).toList();
    final displayCategories = _selectedGenre == 'ทั้งหมด'
        ? categories
        : categories.where((entry) => entry.key == _selectedGenre).toList();
    final maxCount = displayCategories.isEmpty
        ? 1
        : displayCategories.first.value;
    final chartSegments = _selectedGenre == 'ทั้งหมด'
        ? categories
              .asMap()
              .entries
              .map(
                (entry) => _ChartSegment(
                  label: entry.value.key,
                  value: entry.value.value,
                  color: iconColors[entry.key % iconColors.length],
                ),
              )
              .toList()
        : [
            _ChartSegment(
              label: 'เกมโปรด',
              value: selectedGames.where((game) => game.isFavorite).length,
              color: const Color(0xFFE54779),
            ),
            _ChartSegment(
              label: 'เกมอื่นในหมวดนี้',
              value: selectedGames.where((game) => !game.isFavorite).length,
              color: const Color(0xFFB8C1CC),
            ),
          ].where((segment) => segment.value > 0).toList();
    final favoriteCount = games.where((game) => game.isFavorite).length;
    final favoriteRatio = games.isEmpty ? 0.0 : favoriteCount / games.length;

    return Scaffold(
      appBar: IosNavigationBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.chart_bar_fill,
              size: 17,
              color: Color(0xFF007AFF),
            ),
            const SizedBox(width: 7),
            Text(
              'สถิติ',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: child,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF56A3FF), Color(0xFF0068E8)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF007AFF,
                            ).withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.chart_bar_fill,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 13),
                    const Expanded(
                      child: Text(
                        'สถิติเกมโปรด',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'ภาพรวมเกมและหมวดหมู่ในคลังของคุณ',
                  style: TextStyle(color: CupertinoColors.secondaryLabel),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _StatPill(
                      icon: CupertinoIcons.square_grid_2x2_fill,
                      label: 'เกมทั้งหมด',
                      value: '${games.length}',
                      color: const Color(0xFF007AFF),
                    ),
                    const SizedBox(width: 12),
                    _StatPill(
                      icon: CupertinoIcons.heart_fill,
                      label: 'รายการโปรด',
                      value: '$favoriteCount',
                      color: const Color(0xFFE54779),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 17, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'สัดส่วนเกมตามหมวด',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF007AFF,
                                ).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${selectedGames.length} เกม',
                                style: const TextStyle(
                                  color: Color(0xFF007AFF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'เลือกหมวดหมู่เพื่อดูกราฟเฉพาะหมวดนั้น',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (
                                var i = 0;
                                i < availableGenres.length;
                                i++
                              ) ...[
                                if (i > 0) const SizedBox(width: 8),
                                ChoiceChip(
                                  key: ValueKey(
                                    'stats-filter-${availableGenres[i]}',
                                  ),
                                  label: Text(availableGenres[i]),
                                  selected:
                                      availableGenres[i] == _selectedGenre,
                                  onSelected: (_) => setState(
                                    () => _selectedGenre = availableGenres[i],
                                  ),
                                  selectedColor: const Color(
                                    0xFF007AFF,
                                  ).withValues(alpha: 0.13),
                                  side: BorderSide.none,
                                  showCheckmark: false,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 190,
                          child: chartSegments.isEmpty
                              ? const Center(
                                  child: Text('ยังไม่มีข้อมูลให้แสดง'),
                                )
                              : Row(
                                  children: [
                                    SizedBox(
                                      width: 180,
                                      height: 180,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CustomPaint(
                                            size: const Size(180, 180),
                                            painter: _DonutChartPainter(
                                              chartSegments,
                                            ),
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${selectedGames.length}',
                                                style: const TextStyle(
                                                  fontSize: 27,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                _selectedGenre == 'ทั้งหมด'
                                                    ? 'เกมทั้งหมด'
                                                    : _selectedGenre,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          for (final segment in chartSegments)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 5,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 9,
                                                    height: 9,
                                                    decoration: BoxDecoration(
                                                      color: segment.color,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 7),
                                                  Expanded(
                                                    child: Text(
                                                      segment.label,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${segment.value}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        const Text(
                          'จำนวนเกม',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (displayCategories.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 22),
                            child: Center(
                              child: Text(
                                'ยังไม่มีข้อมูลให้แสดง',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          )
                        else
                          for (
                            var i = 0;
                            i < displayCategories.length;
                            i++
                          ) ...[
                            if (i > 0) const SizedBox(height: 17),
                            _AnimatedCategoryRow(
                              key: ValueKey(
                                'stats-${displayCategories[i].key}',
                              ),
                              icon: _genreIcon(displayCategories[i].key),
                              label: displayCategories[i].key,
                              count: displayCategories[i].value,
                              fraction: displayCategories[i].value / maxCount,
                              color: iconColors[i % iconColors.length],
                              delay: Duration(milliseconds: i * 75),
                            ),
                          ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.heart_fill,
                              size: 17,
                              color: Color(0xFFE54779),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'สัดส่วนเกมโปรด',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text('${(favoriteRatio * 100).round()}%'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: favoriteRatio),
                          duration: const Duration(milliseconds: 850),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 9,
                              color: const Color(0xFFE54779),
                              backgroundColor: const Color(0xFFF2F2F7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartSegment {
  const _ChartSegment({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter(this.segments);
  final List<_ChartSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<int>(0, (sum, segment) => sum + segment.value);
    if (total == 0) return;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.butt;
    var start = -1.57079632679;
    for (final segment in segments) {
      final sweep = segment.value / total * 6.28318530718;
      paint.color = segment.color;
      canvas.drawArc(rect.deflate(14), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}

class _AnimatedCategoryRow extends StatefulWidget {
  const _AnimatedCategoryRow({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.fraction,
    required this.color,
    required this.delay,
  });

  final IconData icon;
  final String label;
  final int count;
  final double fraction;
  final Color color;
  final Duration delay;

  @override
  State<_AnimatedCategoryRow> createState() => _AnimatedCategoryRowState();
}

class _AnimatedCategoryRowState extends State<_AnimatedCategoryRow> {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) setState(() => _animate = true);
    });
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 132,
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(widget.icon, size: 14, color: widget.color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            height: 10,
            child: ColoredBox(
              color: const Color(0xFFF2F2F7),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _animate ? widget.fraction : 0),
                duration: const Duration(milliseconds: 720),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value.clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        gradient: LinearGradient(
                          colors: [
                            widget.color.withValues(alpha: 0.6),
                            widget.color,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      SizedBox(
        width: 34,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: Text(
            '${widget.count}',
            key: ValueKey(widget.count),
            textAlign: TextAlign.end,
            style: TextStyle(color: widget.color, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ],
  );
}

class _StarRating extends StatelessWidget {
  final double rating;
  final double iconSize;

  const _StarRating({required this.rating, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final icon = rating >= index + 1
            ? Icons.star
            : rating > index
            ? Icons.star_half
            : Icons.star_border;
        return Icon(icon, color: Colors.amber.shade700, size: iconSize);
      }),
    );
  }
}

class GameDetailPage extends StatefulWidget {
  final SteamGame game;
  final GameRepository repository;

  const GameDetailPage({
    super.key,
    required this.game,
    required this.repository,
  });
  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  late SteamGame game = widget.game;
  bool _deleting = false;

  Future<void> _edit() async {
    final saved = await Navigator.push<SteamGame>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GameEditorPage(game: game, repository: widget.repository),
      ),
    );
    if (saved != null && mounted) setState(() => game = saved);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบเกมนี้?'),
        content: Text('ลบ "${game.title}" จากรายการโปรด'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยันลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.repository.deleteGame(game.id!);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบไม่สำเร็จ กรุณาลองใหม่')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IosNavigationBar(
        title: const Text('รายละเอียดเกม'),
        actions: [
          IconButton(
            tooltip: 'แก้ไขเกม',
            onPressed: _deleting ? null : _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'ลบเกม',
            onPressed: _deleting ? null : _delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Hero(
            tag: 'game-art-${game.id ?? game.appId}',
            child: _DetailImage(url: game.imageUrl),
          ),
          const SizedBox(height: 22),
          Text(
            game.title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MoodBadge(mood: game.genre),
              const SizedBox(width: 10),
              const Icon(Icons.calendar_today_outlined, size: 16),
              const SizedBox(width: 5),
              Text(game.date),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StarRating(rating: game.rating, iconSize: 22),
              const SizedBox(width: 8),
              Text(
                '${game.rating.toStringAsFixed(1)} / 5',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                game.isFavorite
                    ? CupertinoIcons.heart_fill
                    : CupertinoIcons.heart,
                color: const Color(0xFF007AFF),
              ),
              const SizedBox(width: 8),
              Text(
                game.isFavorite
                    ? 'อยู่ในรายการโปรด'
                    : 'ยังไม่ได้เก็บเป็นรายการโปรด',
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Text(
            'รายละเอียด',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 9),
          Text(
            game.description,
            style: const TextStyle(fontSize: 17, height: 1.6),
          ),
          const SizedBox(height: 18),
          Text(
            'Steam App ID: ${game.appId}',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          GameReviewSection(game: game),
        ],
      ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  final String url;

  const _DetailImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: double.infinity,
        height: 205,
        child: url.isEmpty
            ? const _DetailPlaceholder()
            : GameArtwork(
                source: url,
                placeholder: const _DetailPlaceholder(loading: true),
              ),
      ),
    );
  }
}

class _DetailPlaceholder extends StatelessWidget {
  final bool loading;

  const _DetailPlaceholder({this.loading = false});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE5E5EA),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF007AFF),
                ),
              )
            : const Icon(
                CupertinoIcons.game_controller_solid,
                size: 60,
                color: Color(0xFF007AFF),
              ),
      ),
    );
  }
}

class _MoodBadge extends StatelessWidget {
  final String mood;

  const _MoodBadge({required this.mood});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        mood,
        style: const TextStyle(
          color: Color(0xFF007AFF),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, this.user, this.onSignOut});
  final User? user;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IosNavigationBar(title: Text('เกี่ยวกับแอป')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 36),
            Column(
              children: [
                ProfileAvatar(
                  identity: user?.uid ?? 'steam-favorite',
                  size: 96,
                  loadRemote: user != null,
                ),
                if (user != null) ...[
                  const SizedBox(height: 22),
                  Text(
                    user!.email ?? 'บัญชี Firebase',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    'UID: ${user!.uid}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 22),
                const Text(
                  'Steam Game Favorite',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'แอปบันทึกเกมโปรดจาก Steam',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 22),
                const Text('สร้างโดย วชิรวิทย์ วงค์แสง'),
                const SizedBox(height: 5),
                const Text('รหัสนักศึกษา 67011212055'),
                const SizedBox(height: 18),
                const Text(
                  'เวอร์ชัน 7.0 • SQLite + Firestore + REST API',
                  style: TextStyle(color: Colors.black45, fontSize: 13),
                ),
                if (onSignOut != null) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    key: const Key('signOutButton'),
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('ออกจากระบบ'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
