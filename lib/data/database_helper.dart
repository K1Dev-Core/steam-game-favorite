import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/steam_game.dart';

class DatabaseHelper {
  DatabaseHelper({this.databasePath, DatabaseFactory? factory})
    : _factory = factory ?? databaseFactory;
  static final instance = DatabaseHelper();
  final String? databasePath;
  final DatabaseFactory _factory;
  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    try {
      final path =
          databasePath ??
          join(await _factory.getDatabasesPath(), 'steam_favorites_hw2.db');
      return await _factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''CREATE TABLE games (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            appId TEXT NOT NULL,
            title TEXT NOT NULL CHECK(length(trim(title)) > 0),
            description TEXT NOT NULL CHECK(length(trim(description)) > 0),
            date TEXT NOT NULL,
            mood TEXT NOT NULL,
            imageUrl TEXT NOT NULL,
            rating REAL NOT NULL CHECK(rating >= 0 AND rating <= 5)
          )''');
          },
        ),
      );
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<List<SteamGame>> readGames() async {
    final rows = await (await database).query('games', orderBy: 'id DESC');
    return rows.map(SteamGame.fromMap).toList();
  }

  Future<void> saveGame(SteamGame game) async {
    final db = await database;
    if (game.id == null) {
      await db.insert('games', game.toMap());
    } else {
      final count = await db.update(
        'games',
        game.toMap(),
        where: 'id = ?',
        whereArgs: [game.id],
      );
      if (count != 1) throw StateError('Game no longer exists');
    }
  }

  Future<void> deleteGame(int id) async {
    await (await database).delete('games', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening != null) await (await opening).close();
    _opening = null;
  }
}
