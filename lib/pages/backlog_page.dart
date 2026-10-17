import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/game_database.dart';
import '../models/backlog_game.dart';
import '../widgets/ios_navigation_bar.dart';

const _backlogGenres = [
  'Action',
  'Adventure',
  'FPS',
  'RPG',
  'Survival',
  'Strategy',
  'Simulation',
  'อื่น ๆ',
];
const _backlogStatuses = ['อยากเล่น', 'กำลังเล่น', 'เล่นจบแล้ว'];

class BacklogPage extends StatefulWidget {
  const BacklogPage({super.key, required this.database, required this.ownerId});

  final GameDatabase database;
  final String ownerId;

  @override
  State<BacklogPage> createState() => _BacklogPageState();
}

class _BacklogPageState extends State<BacklogPage> {
  List<BacklogGame> _games = [];
  String _filter = 'ทั้งหมด';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final games = await widget.database.readBacklog(widget.ownerId);
      if (mounted) setState(() => _games = games);
    } catch (_) {
      if (mounted) setState(() => _error = 'อ่านรายการในเครื่องไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([BacklogGame? game]) async {
    final draft = await showModalBottomSheet<BacklogGame>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BacklogEditor(initial: game),
    );
    if (draft == null) return;

    final saved = draft.copyWith(
      id: game?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      ownerId: widget.ownerId,
    );
    try {
      await widget.database.saveBacklog(saved);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              game == null
                  ? 'เพิ่มเข้าเกมที่อยากเล่นแล้ว'
                  : 'บันทึกการแก้ไขแล้ว',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) _showMessage('บันทึกลงเครื่องไม่สำเร็จ กรุณาลองใหม่');
    }
  }

  Future<void> _delete(BacklogGame game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบเกมออกจากรายการ?'),
        content: Text('ลบ “${game.title}” ออกจากเกมที่อยากเล่นในเครื่องนี้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true || game.id == null) return;
    try {
      await widget.database.deleteBacklog(widget.ownerId, game.id!);
      await _load();
    } catch (_) {
      if (mounted) _showMessage('ลบไม่สำเร็จ กรุณาลองใหม่');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<BacklogGame> get _visibleGames => _filter == 'ทั้งหมด'
      ? _games
      : _games.where((game) => game.status == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final visible = _visibleGames;
    return Scaffold(
      appBar: IosNavigationBar(
        title: const Text('เกมที่อยากเล่น'),
        actions: [
          IconButton(
            tooltip: 'เพิ่มเกมในเครื่อง',
            onPressed: () => _edit(),
            icon: const Icon(CupertinoIcons.add_circled_solid),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
            child: Text(
              '${_games.length} เกม · บันทึกเฉพาะในเครื่อง ไม่ต้องใช้อินเทอร์เน็ต',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: ['ทั้งหมด', ..._backlogStatuses]
                  .map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(status),
                        selected: _filter == status,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _filter = status),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CupertinoActivityIndicator())
                : _error != null
                ? _EmptyMessage(
                    icon: CupertinoIcons.exclamationmark_circle,
                    title: _error!,
                    action: TextButton(
                      onPressed: _load,
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  )
                : visible.isEmpty
                ? _EmptyMessage(
                    icon: CupertinoIcons.game_controller,
                    title: _filter == 'ทั้งหมด'
                        ? 'ยังไม่มีเกมในรายการ'
                        : 'ยังไม่มีเกมสถานะนี้',
                    message:
                        'เพิ่มเกมที่เล็งไว้ แล้วกลับมาจัดการสถานะได้ทุกเมื่อ',
                    action: FilledButton.icon(
                      onPressed: () => _edit(),
                      icon: const Icon(CupertinoIcons.add),
                      label: const Text('เพิ่มเกมที่อยากเล่น'),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final game = visible[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () => _edit(game),
                            contentPadding: const EdgeInsets.fromLTRB(
                              14,
                              6,
                              6,
                              6,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFEAF2FF),
                              child: Icon(
                                CupertinoIcons.game_controller_solid,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              game.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                [
                                  game.genre,
                                  game.status,
                                  if (game.note.isNotEmpty) game.note,
                                ].join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            trailing: IconButton(
                              tooltip: 'ลบออกจากรายการ',
                              onPressed: () => _delete(game),
                              icon: const Icon(
                                CupertinoIcons.trash,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: Colors.blueGrey),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}

class _BacklogEditor extends StatefulWidget {
  const _BacklogEditor({this.initial});
  final BacklogGame? initial;

  @override
  State<_BacklogEditor> createState() => _BacklogEditorState();
}

class _BacklogEditorState extends State<_BacklogEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _appId = TextEditingController(text: widget.initial?.appId ?? '');
  late final _note = TextEditingController(text: widget.initial?.note ?? '');
  late String _genre = widget.initial?.genre ?? _backlogGenres.first;
  late String _status = widget.initial?.status ?? _backlogStatuses.first;

  @override
  void dispose() {
    _title.dispose();
    _appId.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      BacklogGame(
        id: widget.initial?.id,
        ownerId: widget.initial?.ownerId ?? '',
        title: _title.text.trim(),
        appId: _appId.text.trim(),
        genre: _genre,
        note: _note.text.trim(),
        status: _status,
        createdAt:
            widget.initial?.createdAt ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF2F2F7),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      18,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initial == null ? 'เพิ่มเกมที่อยากเล่น' : 'แก้ไขรายการ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              autofocus: true,
              decoration: _decoration('ชื่อเกม *'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'กรุณากรอกชื่อเกม'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _appId,
              decoration: _decoration('Steam App ID (ไม่บังคับ)'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _genre,
              decoration: _decoration('หมวดเกม'),
              items: _backlogGenres
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _genre = value ?? _genre),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: _decoration('สถานะ'),
              items: _backlogStatuses
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _note,
              decoration: _decoration('โน้ตสั้น ๆ (ไม่บังคับ)'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: const Text('บันทึกลงเครื่อง'),
            ),
          ],
        ),
      ),
    ),
  );
}
