import 'dart:math';
import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/recommended_game.dart';
import '../services/api_service.dart';
import 'game_editor_page.dart';

class RecommendedGamesPage extends StatefulWidget {
  const RecommendedGamesPage({
    super.key,
    required this.database,
    required this.onSaved,
    this.api,
  });
  final DatabaseHelper database;
  final VoidCallback onSaved;
  final ApiService? api;
  @override
  State<RecommendedGamesPage> createState() => _RecommendedGamesPageState();
}

class _RecommendedGamesPageState extends State<RecommendedGamesPage> {
  late final ApiService _api = widget.api ?? ApiService();
  late Future<List<RecommendedGame>> _future = _api.fetchGames();
  int _seed = 0; // ponytail: seed เดียวคุมลำดับสุ่มทั้งหน้า เสถียรข้าม rebuild
  @override
  void dispose() {
    if (widget.api == null) _api.close();
    super.dispose();
  }

  void _reload() => setState(() {
    _seed = Random().nextInt(1 << 30);
    _future = _api.fetchGames();
  });

  Future<void> _refresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {}
  }

  Future<void> _openDetail(RecommendedGame game) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RecommendedGameDetailPage(game: game, database: widget.database),
      ),
    );
    if (saved == true && mounted) widget.onSaved();
  }

  Future<void> _quickAdd(RecommendedGame game) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GameEditorPage(database: widget.database, draft: game.toDraft()),
      ),
    );
    if (saved == true && mounted) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ค้นพบเกม')),
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_downward, size: 14, color: Colors.black45),
                SizedBox(width: 4),
                Text(
                  'ลากลงเพื่อสุ่มเกมใหม่',
                  style: TextStyle(color: Colors.black45, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<RecommendedGame>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('กำลังโหลดเกม…'),
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _Status(
                      icon: Icons.cloud_off_outlined,
                      title: 'โหลดเกมไม่สำเร็จ',
                      message: snapshot.error.toString(),
                      onRetry: _reload,
                    );
                  }
                  final games = snapshot.data ?? [];
                  if (games.isEmpty) {
                    return _Status(
                      icon: Icons.sports_esports_outlined,
                      title: 'ยังไม่มีเกมแนะนำ',
                      message: 'API ยังไม่มีรายการเกม ลองโหลดใหม่ภายหลัง',
                      onRetry: _reload,
                    );
                  }
                  // ponytail: สุ่มลำดับด้วย seed เดียว ทุกใบการ์ดเหมือนกันหมด
                  final order = [...games]..shuffle(Random(_seed));
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: order.length,
                    itemBuilder: (context, index) {
                      final game = order[index];
                      return _GameCard(
                        game: game,
                        onAdd: () => _quickAdd(game),
                        onDetail: () => _openDetail(game),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.onAdd,
    required this.onDetail,
  });
  final RecommendedGame game;
  final VoidCallback onAdd;
  final VoidCallback onDetail;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    margin: const EdgeInsets.only(bottom: 16),
    child: InkWell(
      onTap: onDetail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameCover(url: game.imageUrl),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                Text(
                  game.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  game.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Center(
                  child: IconButton.filled(
                    tooltip: 'เพิ่มลงเกมโปรด',
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class RecommendedGameDetailPage extends StatelessWidget {
  const RecommendedGameDetailPage({
    super.key,
    required this.game,
    required this.database,
  });
  final RecommendedGame game;
  final DatabaseHelper database;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('รายละเอียดเกมแนะนำ')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: GameCover(url: game.imageUrl),
          ),
          const SizedBox(height: 24),
          Text(
            game.title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Steam App ID: ${game.appId} • ข้อมูลจาก API',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            game.description,
            style: const TextStyle(fontSize: 17, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.favorite_border),
            label: const Text('เพิ่มลงเกมโปรด'),
            onPressed: () async {
              final saved = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      GameEditorPage(database: database, draft: game.toDraft()),
                ),
              );
              if (saved == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
    ),
  );
}

class GameCover extends StatelessWidget {
  const GameCover({super.key, required this.url});
  final String url;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 460 / 215,
    child: url.isEmpty
        ? _placeholder()
        : Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : _placeholder(),
            errorBuilder: (_, error, stack) => _placeholder(),
          ),
  );

  Widget _placeholder() => const ColoredBox(
    color: Color(0xffe5ecfa),
    child: Center(
      child: Icon(Icons.sports_esports, size: 64, color: Color(0xff007aff)),
    ),
  );
}

class _Status extends StatelessWidget {
  const _Status({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });
  final IconData icon;
  final String title, message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.blueGrey),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('ลองใหม่')),
        ],
      ),
    ),
  );
}
