import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/steam_game.dart';
import 'game_database.dart';

GameDatabase createGameDatabase() => _SqfliteGameDatabase();

class _SqfliteGameDatabase implements GameDatabase {
  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    final root = await getDatabasesPath();
    return openDatabase(
      path.join(root, 'steam_favorites.db'),
      version: 1,
      onCreate: (database, version) => database.execute('''
        CREATE TABLE steam_games (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          appId TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          date TEXT NOT NULL,
          genre TEXT NOT NULL,
          imageUrl TEXT NOT NULL,
          rating REAL NOT NULL,
          isFavorite INTEGER NOT NULL DEFAULT 1
        )
      '''),
    );
  }

  @override
  Future<List<SteamGame>> readGames(String userId) async {
    final rows = await (await database).query(
      'steam_games',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC, title COLLATE NOCASE ASC',
    );
    return rows.map(SteamGame.fromMap).toList();
  }

  @override
  Future<void> replaceGames(String userId, List<SteamGame> games) async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete(
        'steam_games',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      final batch = transaction.batch();
      for (final game in games) {
        batch.insert(
          'steam_games',
          game.toMap(userId: userId),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> saveGame(SteamGame game) async {
    await (await database).insert(
      'steam_games',
      game.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteGame(String userId, String id) async {
    await (await database).delete(
      'steam_games',
      where: 'userId = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }
}
