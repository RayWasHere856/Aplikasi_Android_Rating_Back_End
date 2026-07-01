import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/movie_controller.dart';

class MovieDetailProvider extends ChangeNotifier {
  final String movieTitle;
  final String uid;
  final String userName;

  final _db = FirebaseFirestore.instance;
  late final String _movieDocId;

  String _selectedReaction = "";
  bool _isLoadingReaction = false;

  String get selectedReaction => _selectedReaction;
  bool get isLoadingReaction => _isLoadingReaction;

  // ── Referensi Firestore ──────────────────────────────────

  CollectionReference get _reactionsRef => _db
      .collection('ratings')
      .doc(_movieDocId)
      .collection('reactions');

  CollectionReference get commentsRef => _db
      .collection('ratings')
      .doc(_movieDocId)
      .collection('comments');

  // Stream komentar realtime — diakses langsung dari view lewat getter ini
  Stream<QuerySnapshot> get commentsStream =>
      commentsRef.orderBy('createdAt', descending: true).snapshots();

  // Stream reaksi realtime — untuk menghitung jumlah like/neutral/dislike
  Stream<QuerySnapshot> get reactionsStream => _reactionsRef.snapshots();

  MovieDetailProvider({
    required this.movieTitle,
    required this.uid,
    required this.userName,
  }) {
    _movieDocId = MovieController.movieDocId(movieTitle);
    _loadUserReaction();
  }

  // ── Reaksi ────────────────────────────────────────────────

  Future<void> _loadUserReaction() async {
    if (uid.isEmpty) return;
    _isLoadingReaction = true;
    notifyListeners();

    final doc = await _reactionsRef.doc(uid).get();
    if (doc.exists) {
      _selectedReaction = (doc.data() as Map<String, dynamic>)['type'] ?? '';
    }

    _isLoadingReaction = false;
    notifyListeners();
  }

  Future<void> handleReaction(String type) async {
    if (uid.isEmpty) return;
    final reactionRef = _reactionsRef.doc(uid);

    if (_selectedReaction == type) {
      // Batalkan reaksi jika sama
      await reactionRef.delete();
      _selectedReaction = '';
    } else {
      // Set reaksi baru
      await reactionRef.set({
        'type': type,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _selectedReaction = type;
    }
    notifyListeners();
  }

  // ── Komentar ──────────────────────────────────────────────

  Future<void> addComment(String text) async {
    if (uid.isEmpty) throw Exception("User tidak ditemukan.");
    if (text.trim().isEmpty) throw Exception("Komentar tidak boleh kosong!");

    await commentsRef.add({
      'userId': uid,
      'userName': userName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editComment(String docId, String newText) async {
    if (newText.trim().isEmpty) return;
    await commentsRef.doc(docId).update({
      'text': newText.trim(),
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment(String docId) async {
    await commentsRef.doc(docId).delete();
  }
}