import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/game_review.dart';
import '../models/steam_game.dart';
import '../services/diary_api_service.dart';

class GameReviewSection extends StatefulWidget {
  const GameReviewSection({super.key, required this.game, this.api});

  final SteamGame game;
  final DiaryApiService? api;

  @override
  State<GameReviewSection> createState() => _GameReviewSectionState();
}

class _GameReviewSectionState extends State<GameReviewSection> {
  late final DiaryApiService _api = widget.api ?? DiaryApiService();
  late Future<GameReview?> _review = _load();

  Future<GameReview?> _load() async {
    final rows = await _api.getDiaries();
    for (final row in rows) {
      if (row.appId == widget.game.appId && row.appId.isNotEmpty) return row;
    }
    // Older API records may not have the optional appId field yet.
    for (final row in rows) {
      if (row.title == widget.game.title) return row;
    }
    return null;
  }

  void _reload() {
    final future = _load();
    setState(() {
      _review = future;
    });
  }

  @override
  void dispose() {
    if (widget.api == null) _api.close();
    super.dispose();
  }

  Future<void> _editReview(GameReview? current) async {
    final draft = await showDialog<_ReviewDraft>(
      context: context,
      builder: (_) => _ReviewEditorDialog(initial: current),
    );
    if (draft == null || !mounted) return;

    final review = GameReview(
      id: current?.id ?? '',
      title: widget.game.title,
      content: draft.content,
      mood: '${draft.rating.toStringAsFixed(1)} / 5 ดาว',
      date: DateTime.now().toIso8601String().substring(0, 10),
      appId: widget.game.appId,
    );
    try {
      if (current == null) {
        await _api.createDiary(review);
      } else {
        await _api.updateDiary(review);
      }
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกรีวิวไปยังเซิร์ฟเวอร์แล้ว')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _deleteReview(GameReview review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบรีวิวนี้?'),
        content: const Text('รายการรีวิวจะถูกลบออกจากเซิร์ฟเวอร์'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบรีวิว'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _api.deleteDiary(review.id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบรีวิวแล้ว')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 24),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.pencil_ellipsis_rectangle,
                color: Color(0xFF007AFF),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'รีวิวของฉัน',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'โหลดรีวิวใหม่',
                onPressed: _reload,
                icon: const Icon(CupertinoIcons.refresh, size: 19),
              ),
            ],
          ),
          const Text(
            'บันทึกความเห็นส่วนตัวของเกมนี้ไว้บนเซิร์ฟเวอร์',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          FutureBuilder<GameReview?>(
            future: _review,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(14),
                  child: Center(child: CupertinoActivityIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.black54),
                    ),
                    TextButton.icon(
                      onPressed: _reload,
                      icon: const Icon(CupertinoIcons.refresh),
                      label: const Text('ลองโหลดอีกครั้ง'),
                    ),
                  ],
                );
              }
              final review = snapshot.data;
              if (review == null) {
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _editReview(null),
                    icon: const Icon(CupertinoIcons.pencil),
                    label: const Text('เขียนรีวิวเกมนี้'),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 19,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${review.rating.toStringAsFixed(1)} / 5',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        review.date,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(review.content, style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _editReview(review),
                        icon: const Icon(CupertinoIcons.pencil, size: 17),
                        label: const Text('แก้ไข'),
                      ),
                      TextButton.icon(
                        onPressed: () => _deleteReview(review),
                        icon: const Icon(CupertinoIcons.delete, size: 17),
                        label: const Text('ลบ'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _ReviewDraft {
  const _ReviewDraft(this.content, this.rating);
  final String content;
  final double rating;
}

class _ReviewEditorDialog extends StatefulWidget {
  const _ReviewEditorDialog({this.initial});
  final GameReview? initial;

  @override
  State<_ReviewEditorDialog> createState() => _ReviewEditorDialogState();
}

class _ReviewEditorDialogState extends State<_ReviewEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text: widget.initial?.content ?? '',
  );
  late double _rating = widget.initial?.rating ?? 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'เขียนรีวิว' : 'แก้ไขรีวิว'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: const Key('gameReviewContent'),
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            maxLength: 800,
            decoration: const InputDecoration(
              labelText: 'รีวิวเกม',
              hintText: 'เขียนความเห็นของคุณ…',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'กรุณาเขียนรีวิวก่อนบันทึก'
                : null,
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber),
              const SizedBox(width: 6),
              const Text('คะแนน'),
              Expanded(
                child: Slider(
                  value: _rating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  label: _rating.toStringAsFixed(1),
                  onChanged: (value) => setState(() => _rating = value),
                ),
              ),
              Text(_rating.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ยกเลิก'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.pop(
              context,
              _ReviewDraft(_controller.text.trim(), _rating),
            );
          }
        },
        child: const Text('บันทึก'),
      ),
    ],
  );
}
