import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'models/steam_game.dart';
import 'data/database_helper.dart';
import 'pages/community_page.dart';
import 'pages/game_editor_page.dart';
import 'pages/recommended_games_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SteamFavoriteApp());
}

const moods = ['ทั้งหมด', 'มีความสุข', 'เศร้า', 'โกรธ', 'ผ่อนคลาย'];

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
  const SteamFavoriteApp({super.key, this.database});
  final DatabaseHelper? database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Steam Game Favorite',
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFE5EAF2),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: child!,
          ),
        ),
      ),
      theme: ThemeData(
        useMaterial3: true,
        platform: TargetPlatform.iOS,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFFF2F2F7),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: MainPage(database: database),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, this.database});
  final DatabaseHelper? database;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  DatabaseHelper get _database => widget.database ?? DatabaseHelper.instance;
  final _searchController = TextEditingController();
  List<SteamGame> _games = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final games = await _database.readGames();
      if (mounted) {
        setState(() {
          _games = games;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'โหลดข้อมูลไม่ได้ กรุณาลองใหม่';
          _loading = false;
        });
      }
    }
  }

  Future<void> _addGame() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => GameEditorPage(database: _database)),
    );
    if (saved == true && mounted) {
      _searchController.clear();
      setState(() => _selectedMood = 'ทั้งหมด');
      await _reload();
    }
  }

  int _selectedTab = 0;
  String _selectedMood = 'ทั้งหมด';

  List<SteamGame> get _filteredGames {
    return _games.where((game) {
      final moodMatches =
          _selectedMood == 'ทั้งหมด' || game.mood == _selectedMood;
      final titleMatches = game.title.toLowerCase().contains(
        _searchController.text.trim().toLowerCase(),
      );
      return moodMatches && titleMatches;
    }).toList();
  }

  Future<void> _openDetail(SteamGame game) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameDetailPage(game: game, database: _database),
      ),
    );
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                )
              : GameListPage(
                  games: _filteredGames,
                  totalCount: _games.length,
                  searchController: _searchController,
                  onSearchChanged: (_) => setState(() {}),
                  onClearFilters: () => setState(() {
                    _searchController.clear();
                    _selectedMood = 'ทั้งหมด';
                  }),
                  selectedMood: _selectedMood,
                  onMoodChanged: (value) =>
                      setState(() => _selectedMood = value),
                  onGameTap: _openDetail,
                  onAdd: _addGame,
                ),
          RecommendedGamesPage(
            database: _database,
            onSaved: () {
              _searchController.clear();
              setState(() {
                _selectedMood = 'ทั้งหมด';
                _selectedTab = 0;
              });
              _reload();
            },
          ),
          const CommunityPage(),
          const AboutPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedTab = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.game_controller_solid),
            label: 'เกมโปรด',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.compass),
            label: 'ค้นพบเกม',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble_2),
            label: 'ชุมชน',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.info),
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
  final String selectedMood;
  final ValueChanged<String> onMoodChanged;
  final ValueChanged<SteamGame> onGameTap;
  final VoidCallback onAdd;

  const GameListPage({
    super.key,
    required this.games,
    required this.totalCount,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearFilters,
    required this.selectedMood,
    required this.onMoodChanged,
    required this.onGameTap,
    required this.onAdd,
  });

  @override
  State<GameListPage> createState() => _GameListPageState();
}

class _GameListPageState extends State<GameListPage> {
  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เกมโปรดของฉัน',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        const Text(
          'บันทึกเกมที่ชอบจาก Steam ไว้ในที่เดียว',
          style: TextStyle(color: Colors.black54, fontSize: 15),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('gameSearch'),
          controller: widget.searchController,
          onChanged: widget.onSearchChanged,
          decoration: InputDecoration(
            hintText: 'ค้นหาจากชื่อเกม',
            prefixIcon: const Icon(CupertinoIcons.search),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: moods.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final mood = moods[index];
              final selected = mood == widget.selectedMood;
              return ChoiceChip(
                label: Text(mood),
                selected: selected,
                onSelected: (_) => widget.onMoodChanged(mood),
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
      appBar: AppBar(
        title: Text('เกมโปรดของฉัน (${widget.totalCount})'),
        actions: [
          IconButton(
            tooltip: 'เพิ่มเกมใหม่',
            onPressed: widget.onAdd,
            icon: const Icon(CupertinoIcons.add),
          ),
        ],
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
          return Card(
            color: cardColor,
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: _GameThumbnail(url: game.imageUrl, iconColor: iconColor),
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
                      '${game.mood}  •  ${game.date}\n${game.description}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _StarRating(rating: game.rating, iconSize: 15),
                  ],
                ),
              ),
              trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
              onTap: () => widget.onGameTap(game),
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
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 88,
        height: 58,
        child: url.isEmpty
            ? _fallback()
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _fallback(loading: true),
                errorBuilder: (context, error, stackTrace) => _fallback(),
              ),
      ),
    );
  }

  Widget _fallback({bool loading = false}) {
    return Container(
      color: iconColor.withValues(alpha: 0.15),
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
  final DatabaseHelper? database;

  const GameDetailPage({super.key, required this.game, this.database});
  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  DatabaseHelper get _database => widget.database ?? DatabaseHelper.instance;
  late SteamGame game = widget.game;
  bool _deleting = false;

  Future<void> _edit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GameEditorPage(game: game, database: _database),
      ),
    );
    if (saved != true || !mounted) return;
    try {
      final games = await _database.readGames();
      if (mounted) {
        setState(() => game = games.firstWhere((item) => item.id == game.id));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('โหลดข้อมูลหลังแก้ไขไม่สำเร็จ')),
        );
      }
    }
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
      await _database.deleteGame(game.id!);
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
      appBar: AppBar(
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
          _DetailImage(url: game.imageUrl),
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
              _MoodBadge(mood: game.mood),
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
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const _DetailPlaceholder(loading: true),
                errorBuilder: (context, error, stackTrace) =>
                    const _DetailPlaceholder(),
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
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เกี่ยวกับแอป')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.game_controller_solid,
                  size: 44,
                  color: Color(0xFF007AFF),
                ),
              ),
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
                'เวอร์ชัน 3.0 • SQLite + 2 API',
                style: TextStyle(color: Colors.black45, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
