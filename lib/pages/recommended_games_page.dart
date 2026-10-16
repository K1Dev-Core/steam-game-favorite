import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/ios_navigation_bar.dart';
import '../models/recommended_game.dart';
import '../models/steam_game.dart';
import '../repositories/game_repository.dart';
import '../services/api_service.dart';
import '../widgets/game_artwork.dart';
import 'game_editor_page.dart';

class RecommendedGamesPage extends StatefulWidget {
  const RecommendedGamesPage({
    super.key,
    required this.repository,
    required this.onSaved,
    this.api,
  });
  final GameRepository repository;
  final VoidCallback onSaved;
  final ApiService? api;
  @override
  State<RecommendedGamesPage> createState() => _RecommendedGamesPageState();
}

class _RecommendedGamesPageState extends State<RecommendedGamesPage> {
  late final ApiService _api = widget.api ?? ApiService();
  late Future<List<RecommendedGame>> _future = _api.fetchGames();
  int _seed = 0;
  int _shuffleTurns = 0;
  @override
  void dispose() {
    if (widget.api == null) _api.close();
    super.dispose();
  }

  void _reload() => setState(() {
    _seed = Random().nextInt(1 << 30);
    _shuffleTurns++;
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
        builder: (_) => RecommendedGameDetailPage(
          game: game,
          repository: widget.repository,
        ),
      ),
    );
    if (saved == true && mounted) widget.onSaved();
  }

  Future<void> _quickAdd(RecommendedGame game) async {
    final saved = await Navigator.push<SteamGame>(
      context,
      MaterialPageRoute(
        builder: (_) => GameEditorPage(
          repository: widget.repository,
          draft: game.toDraft(),
        ),
      ),
    );
    if (saved != null && mounted) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: IosNavigationBar(
      title: const Text('ค้นพบเกม'),
      actions: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _reload,
          child: AnimatedRotation(
            turns: _shuffleTurns.toDouble(),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            child: const Icon(CupertinoIcons.shuffle, size: 23),
          ),
        ),
      ],
    ),
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
                          CupertinoActivityIndicator(),
                          SizedBox(height: 16),
                          Text('กำลังโหลดเกม…'),
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _Status(
                      icon: CupertinoIcons.wifi_slash,
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
                  final order = [...games]..shuffle(Random(_seed));
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: order.length,
                    itemBuilder: (context, index) {
                      final game = order[index];
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(game.appId),
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(
                          milliseconds: 260 + (index.clamp(0, 4) * 40),
                        ),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - value)),
                            child: child,
                          ),
                        ),
                        child: _GameCard(
                          game: game,
                          onAdd: () => _quickAdd(game),
                          onDetail: () => _openDetail(game),
                        ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  textAlign: TextAlign.start,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  game.description,
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CupertinoButton.tinted(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    onPressed: onAdd,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.add, size: 17),
                        SizedBox(width: 6),
                        Text(
                          'เพิ่มเกมโปรด',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
    ),
  );
}

class RecommendedGameDetailPage extends StatelessWidget {
  const RecommendedGameDetailPage({
    super.key,
    required this.game,
    required this.repository,
  });
  final RecommendedGame game;
  final GameRepository repository;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const IosNavigationBar(title: Text('รายละเอียดเกมแนะนำ')),
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
              final saved = await Navigator.push<SteamGame>(
                context,
                MaterialPageRoute(
                  builder: (_) => GameEditorPage(
                    repository: repository,
                    draft: game.toDraft(),
                  ),
                ),
              );
              if (saved != null && context.mounted) {
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
        : GameArtwork(source: url, placeholder: _placeholder()),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 32, color: CupertinoColors.secondaryLabel),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            onPressed: onRetry,
            child: const Text(
              'ลองใหม่',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}
