import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/ios_navigation_bar.dart';
import '../models/steam_game.dart';
import '../repositories/game_repository.dart';
import '../widgets/game_artwork.dart';

class GameEditorPage extends StatefulWidget {
  final SteamGame? game;
  final SteamGame? draft;
  final GameRepository repository;
  const GameEditorPage({
    super.key,
    this.game,
    this.draft,
    required this.repository,
  });
  @override
  State<GameEditorPage> createState() => _GameEditorPageState();
}

class _GameEditorPageState extends State<GameEditorPage> {
  final _formKey = GlobalKey<FormState>();
  SteamGame? get _initial => widget.game ?? widget.draft;
  late final _title = TextEditingController(text: _initial?.title ?? '');
  late final _description = TextEditingController(
    text: _initial?.description ?? '',
  );
  late final _appId = TextEditingController(text: _initial?.appId ?? '');
  late final _image = TextEditingController(text: _initial?.imageUrl ?? '');
  late String _genre = _initial?.genre ?? 'Action';
  late double _rating = _initial?.rating ?? 4;
  late bool _isFavorite = _initial?.isFavorite ?? true;
  late String _date =
      _initial?.date ?? DateTime.now().toIso8601String().split('T').first;
  bool _saving = false;
  String? _error;
  final _picker = ImagePicker();

  static const _genres = [
    'Action',
    'Adventure',
    'FPS',
    'RPG',
    'Survival',
    'Strategy',
    'Simulation',
    'อื่น ๆ',
  ];

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
      final saved = await widget.repository.saveGame(
        SteamGame(
          id: widget.game?.id,
          appId: _appId.text.trim(),
          title: _title.text.trim(),
          description: _description.text.trim(),
          date: _date,
          mood: _genre,
          genre: _genre,
          imageUrl: _image.text.trim(),
          rating: _rating,
          isFavorite: _isFavorite,
        ),
      );
      if (mounted) Navigator.pop(context, saved);
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

  Future<void> _chooseImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('เลือกจากคลังรูป'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('ถ่ายรูปปกเกม'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 40,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 280000) {
        setState(() => _error = 'รูปยังมีขนาดใหญ่ไป ลองเลือกรูปที่เล็กลง');
        return;
      }
      final name = file.name.toLowerCase();
      final mime =
          file.mimeType ??
          (name.endsWith('.png')
              ? 'image/png'
              : name.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg');
      if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(mime)) {
        setState(() => _error = 'รองรับรูปแบบ JPEG, PNG และ WebP');
        return;
      }
      setState(() {
        _image.text = 'data:$mime;base64,${base64Encode(bytes)}';
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'เปิดรูปไม่สำเร็จ กรุณาลองใหม่');
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
        appBar: IosNavigationBar(
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
                    initialValue: _genres.contains(_genre) ? _genre : 'อื่น ๆ',
                    decoration: _decoration('หมวดหมู่เกม'),
                    items: _genres
                        .map(
                          (genre) => DropdownMenuItem(
                            value: genre,
                            child: Text(genre),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _genre = value!),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('เก็บไว้ในรายการโปรด'),
                    value: _isFavorite,
                    onChanged: (value) => setState(() => _isFavorite = value),
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
                    decoration: _decoration(
                      'URL รูปเกม (ใส่ URL หรือเลือกรูปด้านล่าง)',
                    ),
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      if (RegExp(
                        r'^data:image/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$',
                      ).hasMatch(value.trim())) {
                        return value.trim().length <= 400000
                            ? null
                            : 'รูปมีขนาดใหญ่เกินไป กรุณาเลือกรูปที่เล็กลง';
                      }
                      final uri = Uri.tryParse(value.trim());
                      return uri != null &&
                              uri.scheme == 'https' &&
                              uri.host.isNotEmpty
                          ? null
                          : 'กรอก URL รูปแบบ https://';
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GameArtwork(
                        source: _image.text,
                        placeholder: const ColoredBox(
                          color: Color(0xFFE5ECFA),
                          child: Center(
                            child: Icon(
                              Icons.sports_esports,
                              size: 48,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _chooseImage,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('ถ่ายรูปหรือเลือกภาพปก'),
                  ),
                  if (_image.text.startsWith('data:image/'))
                    TextButton.icon(
                      onPressed: () => setState(() => _image.clear()),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('เอารูปที่เลือกออก'),
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
