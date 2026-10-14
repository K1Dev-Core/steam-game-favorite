import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/steam_game.dart';
import '../repositories/game_repository.dart';

class FirestoreGameRepository implements GameRepository {
  FirestoreGameRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _userId {
    final id = _auth.currentUser?.uid;
    if (id == null) throw StateError('ผู้ใช้ยังไม่ได้เข้าสู่ระบบ');
    return id;
  }

  CollectionReference<Map<String, dynamic>> get _games =>
      _firestore.collection('games');

  @override
  Stream<List<SteamGame>> watchGames() {
    final userId = _userId;
    return _games.where('userId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final games = snapshot.docs.map(SteamGame.fromFirestore).toList();
      games.sort((a, b) => b.date.compareTo(a.date));
      return games;
    });
  }

  @override
  Future<SteamGame> saveGame(SteamGame game) async {
    final userId = _userId;
    final data = {
      ...game.toFirestore(userId),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (game.id == null) {
      final document = await _games.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return game.copyWith(id: document.id, userId: userId);
    }
    await _games.doc(game.id).update(data);
    return game.copyWith(userId: userId);
  }

  @override
  Future<void> deleteGame(String id) => _games.doc(id).delete();
}
