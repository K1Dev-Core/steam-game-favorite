import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_comment.dart';
import '../services/api_service.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key, this.api});
  final ApiService? api;
  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  late final ApiService _api = widget.api ?? ApiService();
  late Future<List<GameComment>> _future = _api.fetchComments();
  int _seed = 0;

  @override
  void dispose() {
    if (widget.api == null) _api.close();
    super.dispose();
  }

  void _reload() => setState(() {
    _seed = Random().nextInt(1 << 30);
    _future = _api.fetchComments();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('ชุมชน'),
      actions: [
        IconButton(
          tooltip: 'โหลดคอมเมนต์ใหม่',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<GameComment>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('กำลังโหลดคอมเมนต์…'),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(height: 16),
                  const Text('โหลดคอมเมนต์ไม่สำเร็จ'),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _reload,
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            ),
          );
        }
        final comments = [...(snapshot.data ?? [])]
          ..shuffle(Random(_seed));
        if (comments.isEmpty) {
          return const Center(child: Text('ยังไม่มีคอมเมนต์'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final c = comments[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(
                            0xFF007AFF,
                          ).withValues(alpha: 0.12),
                          child: Text(
                            c.user[0],
                            style: const TextStyle(
                              color: Color(0xFF007AFF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.user,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                c.date,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Stars(rating: c.rating),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(c.text, style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '@${c.gameTitle}',
                        style: const TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});
  final double rating;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) {
      final icon = rating >= i + 1
          ? Icons.star
          : rating > i
          ? Icons.star_half
          : Icons.star_border;
      return Icon(icon, color: Colors.amber.shade700, size: 15);
    }),
  );
}
