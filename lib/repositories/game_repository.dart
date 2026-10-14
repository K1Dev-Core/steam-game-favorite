import '../models/steam_game.dart';

abstract class GameRepository {
  Stream<List<SteamGame>> watchGames();
  Future<SteamGame> saveGame(SteamGame game);
  Future<void> deleteGame(String id);
}
