import '../models/steam_game.dart';
import 'game_database_stub.dart'
    if (dart.library.io) 'game_database_sqflite.dart'
    if (dart.library.js_interop) 'game_database_web.dart'
    as platform;

abstract interface class GameDatabase {
  Future<List<SteamGame>> readGames(String userId);
  Future<void> replaceGames(String userId, List<SteamGame> games);
  Future<void> saveGame(SteamGame game);
  Future<void> deleteGame(String userId, String id);
}

GameDatabase createGameDatabase() => platform.createGameDatabase();
