import 'package:flutter/material.dart';
import '../models/steam_game.dart';
import '../data/database_helper.dart';

class GameEditorPage extends StatefulWidget {
  final SteamGame? game;
  final DatabaseHelper? database;
  const GameEditorPage({super.key, this.game, this.database});
  @override
  State<GameEditorPage> createState() => _GameEditorPageState();
}

class _GameEditorPageState extends State<GameEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.game?.title ?? '');
  late final _description = TextEditingController(
    text: widget.game?.description ?? '',
  );
  late final _appId = TextEditingController(text: widget.game?.appId ?? '');
  late final _image = TextEditingController(text: widget.game?.imageUrl ?? '');
  late String _mood = widget.game?.mood ?? 'มีความสุข';
  late double _rating = widget.game?.rating ?? 4;
  late String _date =
      widget.game?.date ?? DateTime.now().toIso8601String().split('T').first;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _appId.dispose();
    _image.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await (widget.database ?? DatabaseHelper.instance).saveGame(
        SteamGame(
          id: widget.game?.id,
          appId: _appId.text.trim(),
          title: _title.text.trim(),
          description: _description.text.trim(),
          date: _date,
          mood: _mood,
          imageUrl: _image.text.trim(),
          rating: _rating,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'บันทึกไม่สำเร็จ กรุณาลองใหม่';
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked.toIso8601String().split('T').first);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.game == null ? 'เพิ่มเกมโปรด' : 'แก้ไขเกม'),
        ),
        body: AbsorbPointer(
          absorbing: _saving,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('gameTitle'),
                    controller: _title,
                    decoration: _decoration('ชื่อเกม *'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'กรุณากรอกชื่อเกม'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('gameDescription'),
                    controller: _description,
                    decoration: _decoration('รายละเอียด / ความรู้สึก *'),
                    minLines: 3,
                    maxLines: 5,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'กรุณากรอกรายละเอียด'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _mood,
                    decoration: _decoration('อารมณ์'),
                    items: ['มีความสุข', 'เศร้า', 'โกรธ', 'ผ่อนคลาย']
                        .map(
                          (mood) =>
                              DropdownMenuItem(value: mood, child: Text(mood)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _mood = value!),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'คะแนนของฉัน: ${_rating.toStringAsFixed(1)} / 5',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _rating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: _rating.toStringAsFixed(1),
                    onChanged: (value) => setState(() => _rating = value),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month),
                    title: Text(_date),
                    subtitle: const Text('วันที่บันทึก'),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _appId,
                    decoration: _decoration('Steam App ID (ไม่บังคับ)'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _image,
                    decoration: _decoration('URL รูปเกม (ไม่บังคับ)'),
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final uri = Uri.tryParse(value.trim());
                      return uri != null &&
                              uri.scheme == 'https' &&
                              uri.host.isNotEmpty
                          ? null
                          : 'กรอก URL รูปแบบ https://';
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'เว้นรูปว่างเพื่อใช้ไอคอนเกม',
                    style: TextStyle(color: Colors.black54),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('บันทึก'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
