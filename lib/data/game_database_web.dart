import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/steam_game.dart';
import '../models/backlog_game.dart';
import 'game_database.dart';

GameDatabase createGameDatabase() => _WebGameDatabase();

class _WebGameDatabase implements GameDatabase {
  String _key(String userId) => 'steam_favorites_$userId';
  String _backlogKey(String ownerId) => 'steam_backlog_$ownerId';

  Future<List<BacklogGame>> _readBacklog(String ownerId) async {
    final preferences = await SharedPreferences.getInstance();
    final json = preferences.getString(_backlogKey(ownerId));
    if (json == null) return [];
    final rows = jsonDecode(json) as List<dynamic>;
    return rows
        .map(
          (row) => BacklogGame.fromMap(Map<String, Object?>.from(row as Map)),
        )
        .toList();
  }

  Future<void> _writeBacklog(String ownerId, List<BacklogGame> games) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _backlogKey(ownerId),
      jsonEncode(games.map((game) => game.toMap()).toList()),
    );
  }

  Future<List<SteamGame>> _read(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final json = preferences.getString(_key(userId));
    if (json == null) return [];
    final rows = jsonDecode(json) as List<dynamic>;
    return rows
        .map((row) => SteamGame.fromMap(Map<String, Object?>.from(row as Map)))
        .toList();
  }

  Future<void> _write(String userId, List<SteamGame> games) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key(userId),
      jsonEncode(games.map((game) => game.toMap(userId: userId)).toList()),
    );
  }

  @override
  Future<List<SteamGame>> readGames(String userId) => _read(userId);

  @override
  Future<void> replaceGames(String userId, List<SteamGame> games) =>
      _write(userId, games);

  @override
  Future<void> saveGame(SteamGame game) async {
    final games = await _read(game.userId);
    final index = games.indexWhere((item) => item.id == game.id);
    if (index == -1) {
      games.add(game);
    } else {
      games[index] = game;
    }
    await _write(game.userId, games);
  }

  @override
  Future<void> deleteGame(String userId, String id) async {
    final games = await _read(userId);
    games.removeWhere((game) => game.id == id);
    await _write(userId, games);
  }

  @override
  Future<List<BacklogGame>> readBacklog(String ownerId) =>
      _readBacklog(ownerId);

  @override
  Future<void> saveBacklog(BacklogGame game) async {
    final games = await _readBacklog(game.ownerId);
    final index = games.indexWhere((item) => item.id == game.id);
    if (index == -1) {
      games.add(game);
    } else {
      games[index] = game;
    }
    await _writeBacklog(game.ownerId, games);
  }

  @override
  Future<void> deleteBacklog(String ownerId, String id) async {
    final games = await _readBacklog(ownerId);
    games.removeWhere((game) => game.id == id);
    await _writeBacklog(ownerId, games);
  }
}
