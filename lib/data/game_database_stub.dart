import 'game_database.dart';
import '../models/steam_game.dart';

GameDatabase createGameDatabase() => _UnsupportedGameDatabase();

class _UnsupportedGameDatabase implements GameDatabase {
  Never _unsupported() =>
      throw UnsupportedError('Local database is unavailable');

  @override
  Future<void> deleteGame(String userId, String id) async => _unsupported();

  @override
  Future<List<SteamGame>> readGames(String userId) async => _unsupported();

  @override
  Future<void> replaceGames(String userId, List<SteamGame> games) async =>
      _unsupported();

  @override
  Future<void> saveGame(SteamGame game) async => _unsupported();
}
