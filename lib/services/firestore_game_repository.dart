import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/game_database.dart';
import '../models/steam_game.dart';
import '../repositories/game_repository.dart';
import 'favorites_api_service.dart';

class FirestoreGameRepository implements GameRepository {
  FirestoreGameRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    GameDatabase? database,
    FavoritesApiService? api,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _database = database ?? createGameDatabase(),
       _api = api ?? FavoritesApiService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final GameDatabase _database;
  final FavoritesApiService _api;

  String get _userId {
    final id = _auth.currentUser?.uid;
    if (id == null) throw StateError('ผู้ใช้ยังไม่ได้เข้าสู่ระบบ');
    return id;
  }

  Future<String> get _idToken async =>
      await _auth.currentUser?.getIdToken() ??
      (throw StateError('กรุณาเข้าสู่ระบบใหม่'));

  CollectionReference<Map<String, dynamic>> get _games =>
      _firestore.collection('games');

  @override
  Stream<List<SteamGame>> watchGames() async* {
    final userId = _userId;
    yield await _database.readGames(userId);

    try {
      final token = await _idToken;
      final serverGames = await _api.getGames(token);
      await _database.replaceGames(userId, serverGames);
      yield await _database.readGames(userId);
    } catch (_) {}

    await for (final snapshot
        in _games.where('userId', isEqualTo: userId).snapshots()) {
      final games = snapshot.docs.map(SteamGame.fromFirestore).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      await _database.replaceGames(userId, games);
      yield await _database.readGames(userId);
    }
  }

  @override
  Future<SteamGame> saveGame(SteamGame game) async {
    final userId = _userId;
    final saved = game.copyWith(id: game.id ?? _games.doc().id, userId: userId);
    final token = await _idToken;
    final remote = game.id == null
        ? await _api.createGame(saved, token)
        : await _api.updateGame(saved, token);
    await _database.saveGame(remote.copyWith(userId: userId));
    return remote.copyWith(userId: userId);
  }

  @override
  Future<void> deleteGame(String id) async {
    final userId = _userId;
    final token = await _idToken;
    await _api.deleteGame(id, token);
    await _database.deleteGame(userId, id);
  }
}
