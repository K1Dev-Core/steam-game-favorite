import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/steam_game.dart';
import '../models/backlog_game.dart';
import 'game_database.dart';

GameDatabase createGameDatabase() => _SqfliteGameDatabase();

class _SqfliteGameDatabase implements GameDatabase {
  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    final root = await getDatabasesPath();
    return openDatabase(
      path.join(root, 'steam_favorites.db'),
      version: 2,
      onCreate: (database, version) async {
        await database.execute('''
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
      ''');
        await database.execute(_createBacklogTable);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) await database.execute(_createBacklogTable);
      },
    );
  }

  static const _createBacklogTable = '''
    CREATE TABLE backlog_games (
      id TEXT PRIMARY KEY,
      ownerId TEXT NOT NULL,
      title TEXT NOT NULL,
      appId TEXT NOT NULL DEFAULT '',
      genre TEXT NOT NULL,
      note TEXT NOT NULL DEFAULT '',
      status TEXT NOT NULL,
      createdAt TEXT NOT NULL
    )
  ''';

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

  @override
  Future<List<BacklogGame>> readBacklog(String ownerId) async {
    final rows = await (await database).query(
      'backlog_games',
      where: 'ownerId = ?',
      whereArgs: [ownerId],
      orderBy: 'createdAt DESC, title COLLATE NOCASE ASC',
    );
    return rows.map(BacklogGame.fromMap).toList();
  }

  @override
  Future<void> saveBacklog(BacklogGame game) async {
    await (await database).insert(
      'backlog_games',
      game.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteBacklog(String ownerId, String id) async {
    await (await database).delete(
      'backlog_games',
      where: 'ownerId = ? AND id = ?',
      whereArgs: [ownerId, id],
    );
  }
}
