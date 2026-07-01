import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movie.dart';
import '../database/sqlite_helper.dart';
import '../services/api_services.dart';
import 'auth_controller.dart';

// Favorit in-memory untuk user yang sedang login
List<Movie> favoriteMovies = [];

class MovieController {

  // ── Koneksi ─────────────────────────────────────────────

  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ── MOVIES offline

  static Future<List<Movie>> getMovies() async {
    final online = await isOnline();
    if (online) {
      try {
        final movies = await ApiService.fetchMovies();
        await SqliteHelper.cacheMovies(movies);
        return movies;
      } catch (e) {
        return await SqliteHelper.getCachedMovies();
      }
    } else {
      return await SqliteHelper.getCachedMovies();
    }
  }

  // FAVORITES (per-user

  /// Load favorit user yang sedang login dari SQLite
  static Future<void> loadFavorites() async {
    final uid = AuthController.uid;
    if (uid == null) return;

    final saved = await SqliteHelper.getFavorites(uid);
    favoriteMovies
      ..clear()
      ..addAll(saved);
  }

  /// Cek apakah film sudah difavoritkan
  static bool isFavorite(Movie movie) {
    return favoriteMovies.any((m) => m.title == movie.title);
  }

  /// Toggle favorit — simpan/hapus di SQLite milik user ini saja
  static Future<bool> toggleFavorite(Movie movie) async {
    final uid = AuthController.uid;
    if (uid == null) return false;

    if (isFavorite(movie)) {
      await SqliteHelper.removeFavorite(uid, movie.title);
      favoriteMovies.removeWhere((m) => m.title == movie.title);
      return false;
    } else {
      await SqliteHelper.addFavorite(uid, movie);
      favoriteMovies.add(movie);
      return true;
    }
  }

  /// Hitung rating app berdasarkan reaksi user di Firestore
  /// Rating = rata-rata semua reaksi (skala 0-10)
  static Future<double> calculateAppRating(String movieDocId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .doc(movieDocId)
          .collection('reactions')
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      int likes = 0, neutrals = 0, dislikes = 0;
      for (var doc in snapshot.docs) {
        final type = doc['type'];
        if (type == 'like') likes++;
        if (type == 'neutral') neutrals++;
        if (type == 'dislike') dislikes++;
      }

      final total = likes + neutrals + dislikes;
      if (total == 0) return 0.0;

      // Skor: like=1, neutral=0.5, dislike=0
      // Skala 0-10
      final score = ((likes * 1.0) + (neutrals * 0.5) + (dislikes * 0.0)) / total;
      return double.parse((score * 10).toStringAsFixed(1));
    } catch (e) {
      return 0.0;
    }
  }

  /// Stream rating realtime dari Firestore
  static Stream<double> watchAppRating(String movieDocId) {
    return FirebaseFirestore.instance
        .collection('ratings')
        .doc(movieDocId)
        .collection('reactions')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return 0.0;

      int likes = 0, neutrals = 0, dislikes = 0;
      for (var doc in snapshot.docs) {
        final type = doc['type'];
        if (type == 'like') likes++;
        if (type == 'neutral') neutrals++;
        if (type == 'dislike') dislikes++;
      }

      final total = likes + neutrals + dislikes;
      if (total == 0) return 0.0;

      final score =
          ((likes * 1.0) + (neutrals * 0.5) + (dislikes * 0.0)) / total;
      return double.parse((score * 10).toStringAsFixed(1));
    });
  }

  /// Buat ID dokumen dari judul film
  static String movieDocId(String title) {
    return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  // ── Format Helper ────────────────────────────────────────

  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }
}