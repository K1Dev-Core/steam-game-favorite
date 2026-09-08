import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const SteamFavoriteApp());
}

const moods = ['ทั้งหมด', 'มีความสุข', 'เศร้า', 'โกรธ', 'ผ่อนคลาย'];

class SteamGame {
  final String appId;
  final String title;
  final String description;
  final String date;
  final String mood;
  final String imageUrl;
  final double rating;

  const SteamGame({
    required this.appId,
    required this.title,
    required this.description,
    required this.date,
    required this.mood,
    required this.imageUrl,
    required this.rating,
  });

  SteamGame copyWith({
    String? appId,
    String? title,
    String? description,
    String? date,
    String? mood,
    String? imageUrl,
    double? rating,
  }) {
    return SteamGame(
      appId: appId ?? this.appId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
    );
  }
}

const List<SteamGame> seedGames = [
  SteamGame(
    appId: '271590',
    title: 'Grand Theft Auto V',
    description:
        'เกมแอ็กชันโอเพนเวิลด์ สำรวจเมือง Los Santos และทำภารกิจต่าง ๆ',
    date: '8 ก.ย. 2569',
    mood: 'มีความสุข',
    imageUrl:
        'https://cdn.cloudflare.steamstatic.com/steam/apps/271590/header.jpg',
    rating: 4.8,
  ),
  SteamGame(
    appId: '1174180',
    title: 'Red Dead Redemption 2',
    description: 'ผจญภัยในดินแดนตะวันตกกับเรื่องราวเข้มข้นและโลกที่มีชีวิตชีวา',
    date: '7 ก.ย. 2569',
    mood: 'เศร้า',
    imageUrl:
        'https://cdn.cloudflare.steamstatic.com/steam/apps/1174180/header.jpg',
    rating: 4.9,
  ),
  SteamGame(
    appId: '594650',
    title: 'HUNT: Showdown 1896',
    description: 'เกมล่าค่าหัวแบบ PvPvE ต่อสู้กับนักล่าและสัตว์ประหลาดในโลกมืด',
    date: '6 ก.ย. 2569',
    mood: 'โกรธ',
    imageUrl:
        'https://cdn.cloudflare.steamstatic.com/steam/apps/594650/header.jpg',
    rating: 4.5,
  ),
  SteamGame(
    appId: '513710',
    title: 'SCUM',
    description: 'เกมเอาชีวิตรอดในเกาะอันตราย เก็บทรัพยากร สร้างฐาน และต่อสู้',
    date: '5 ก.ย. 2569',
    mood: 'โกรธ',
    imageUrl:
        'https://cdn.cloudflare.steamstatic.com/steam/apps/513710/header.jpg',
    rating: 4.2,
  ),
  SteamGame(
    appId: '304930',
    title: 'Unturned',
    description: 'เกมเอาชีวิตรอดจากซอมบี้ สำรวจเมือง เก็บของ และเล่นกับเพื่อน',
    date: '4 ก.ย. 2569',
    mood: 'ผ่อนคลาย',
    imageUrl:
        'https://cdn.cloudflare.steamstatic.com/steam/apps/304930/header.jpg',
    rating: 4.4,
  ),
  SteamGame(
    appId: '1623730',
    title: 'Palworld',
    description: 'เกมผจญภัยเอาชีวิตรอด จับ Pals สร้างฐาน และออกสำรวจโลกกว้าง',
    date: '3 ก.ย. 2569',
    mood: 'มีความสุข',
    imageUrl:
        'https://cdn.cloudflare.steamstatic.com/steam/apps/1623730/header.jpg',
    rating: 4.7,
  ),
  SteamGame(
    appId: '633230',
    title: 'NARUTO TO BORUTO: SHINOBI STRIKER',
    description: 'เกมต่อสู้ทีมออนไลน์ ใช้นินจาจาก Naruto และสร้างทีมของตัวเอง',
    date: '2 ก.ย. 2569',
    mood: 'มีความสุข',
    imageUrl:
        'https://cdn.cloudflare.steamstatic.com/steam/apps/633230/header.jpg',
    rating: 4.6,
  ),
];

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
  const SteamFavoriteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Steam Game Favorite',
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
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<SteamGame> _games = List.of(seedGames);
  int _selectedTab = 0;
  String _selectedMood = 'ทั้งหมด';

  List<SteamGame> get _filteredGames {
    return _games.where((game) {
      final moodMatches =
          _selectedMood == 'ทั้งหมด' || game.mood == _selectedMood;
      return moodMatches;
    }).toList();
  }

  void _showAddUnavailable() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยังใช้ฟีเจอร์นี้ไม่ได้'),
        content: const Text('ฟีเจอร์เพิ่มเกมใหม่ยังไม่เปิดใช้งาน'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _openDetail(SteamGame game) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameDetailPage(game: game)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: [
          GameListPage(
            games: _filteredGames,
            selectedMood: _selectedMood,
            onMoodChanged: (value) => setState(() => _selectedMood = value),
            onGameTap: _openDetail,
            onAdd: _showAddUnavailable,
          ),
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
  final String selectedMood;
  final ValueChanged<String> onMoodChanged;
  final ValueChanged<SteamGame> onGameTap;
  final VoidCallback onAdd;

  const GameListPage({
    super.key,
    required this.games,
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
        title: const Text('Steam Game Favorite'),
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
            return const Padding(
              padding: EdgeInsets.only(top: 70),
              child: Center(child: Text('ไม่พบเกมในหมวดนี้')),
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
        final icon = index < rating ? Icons.star : Icons.star_border;
        return Icon(icon, color: Colors.amber.shade700, size: iconSize);
      }),
    );
  }
}

class GameDetailPage extends StatelessWidget {
  final SteamGame game;

  const GameDetailPage({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดเกม')),
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

class GameEditorPage extends StatefulWidget {
  final SteamGame? game;

  const GameEditorPage({super.key, this.game});

  @override
  State<GameEditorPage> createState() => _GameEditorPageState();
}

class _GameEditorPageState extends State<GameEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _appIdController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dateController;
  late final TextEditingController _imageController;
  late String _mood;
  late DateTime _selectedDate;

  bool get _isEditing => widget.game != null;

  @override
  void initState() {
    super.initState();
    final game = widget.game;
    _selectedDate = DateTime.now();
    _appIdController = TextEditingController(text: game?.appId ?? '');
    _titleController = TextEditingController(text: game?.title ?? '');
    _descriptionController = TextEditingController(
      text: game?.description ?? '',
    );
    _dateController = TextEditingController(
      text: game?.date ?? _formatDate(_selectedDate),
    );
    _imageController = TextEditingController(text: game?.imageUrl ?? '');
    _mood = moods.contains(game?.mood) ? game!.mood : 'มีความสุข';
  }

  @override
  void dispose() {
    _appIdController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year + 543}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final game = SteamGame(
      appId: _appIdController.text.trim().isEmpty
          ? 'custom-${DateTime.now().millisecondsSinceEpoch}'
          : _appIdController.text.trim(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _dateController.text,
      mood: _mood,
      imageUrl: _imageController.text.trim(),
      rating: widget.game?.rating ?? 5.0,
    );
    Navigator.pop(context, game);
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'แก้ไขเกม' : 'เพิ่มเกมโปรด'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(CupertinoIcons.chevron_left),
        ),
        actions: [TextButton(onPressed: _save, child: const Text('บันทึก'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            const Text(
              'ข้อมูลเกม',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Steam App ID (ไม่บังคับ)'),
            const SizedBox(height: 7),
            TextFormField(
              controller: _appIdController,
              keyboardType: TextInputType.number,
              decoration: _decoration('เช่น 730'),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('หัวข้อบันทึก *'),
            const SizedBox(height: 7),
            TextFormField(
              controller: _titleController,
              decoration: _decoration('ชื่อเกม'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'กรุณากรอกชื่อเกม'
                  : null,
            ),
            const SizedBox(height: 14),
            const _FieldLabel('รายละเอียด *'),
            const SizedBox(height: 7),
            TextFormField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 6,
              decoration: _decoration('เขียนรายละเอียดเกมที่ชอบ'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'กรุณากรอกรายละเอียด'
                  : null,
            ),
            const SizedBox(height: 14),
            const _FieldLabel('วันที่'),
            const SizedBox(height: 7),
            Card(
              margin: EdgeInsets.zero,
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(CupertinoIcons.calendar),
                title: Text(_dateController.text),
                trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('อารมณ์หรือความรู้สึก'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: moods.skip(1).map((mood) {
                final selected = mood == _mood;
                return ChoiceChip(
                  label: Text(mood),
                  selected: selected,
                  onSelected: (_) => setState(() => _mood = mood),
                  selectedColor: const Color(0xFF007AFF),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                  ),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('รูปภาพเกม (ไม่บังคับ)'),
            const SizedBox(height: 7),
            TextFormField(
              controller: _imageController,
              keyboardType: TextInputType.url,
              decoration: _decoration(
                'วาง URL รูปภาพ หรือเว้นว่างเพื่อใช้ไอคอน',
              ),
            ),
            const SizedBox(height: 14),
            if (_imageController.text.isEmpty)
              const Center(
                child: Icon(
                  CupertinoIcons.game_controller_solid,
                  size: 54,
                  color: Color(0xFF007AFF),
                ),
              )
            else
              _DetailImage(url: _imageController.text),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black54,
        fontSize: 14,
        fontWeight: FontWeight.w600,
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
                'เวอร์ชัน 1.0',
                style: TextStyle(color: Colors.black45, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
