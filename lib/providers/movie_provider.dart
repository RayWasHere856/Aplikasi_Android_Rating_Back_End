import 'dart:async';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../controllers/movie_controller.dart';

class MovieProvider extends ChangeNotifier {
  List<Movie> _allMovies = [];
  bool _isLoading = false;

  final Map<String, double> _ratingsCache = {};
  final Map<String, StreamSubscription<double>> _ratingSubscriptions = {};

  List<Movie> get allMovies => _allMovies;
  bool get isLoading => _isLoading;

  // ── Movies offline

  Future<void> loadAllMovies() async {
    _isLoading = true;
    notifyListeners();

    _allMovies = await MovieController.getMovies();

    _isLoading = false;
    notifyListeners();
  }

  // Rating realtime per film 

  /// Ambil rating yang sudah di-cache (untuk dipakai langsung di build())
  double ratingFor(String movieTitle) {
    final docId = MovieController.movieDocId(movieTitle);
    return _ratingsCache[docId] ?? 0.0;
  }

  /// Mulai mendengarkan rating realtime untuk satu film.
  /// Aman dipanggil berkali-kali — subscription lama tidak akan dobel.
  void watchRating(String movieTitle) {
    final docId = MovieController.movieDocId(movieTitle);
    if (_ratingSubscriptions.containsKey(docId)) return;

    final sub = MovieController.watchAppRating(docId).listen((rating) {
      _ratingsCache[docId] = rating;
      notifyListeners();
    });

    _ratingSubscriptions[docId] = sub;
  }

  /// Hitung sekali tanpa stream (mis. untuk laporan/cek manual)
  Future<double> calculateRating(String movieTitle) async {
    final docId = MovieController.movieDocId(movieTitle);
    final rating = await MovieController.calculateAppRating(docId);
    _ratingsCache[docId] = rating;
    notifyListeners();
    return rating;
  }

  String formatRating(double rating) => MovieController.formatRating(rating);

  @override
  void dispose() {
    for (final sub in _ratingSubscriptions.values) {
      sub.cancel();
    }
    _ratingSubscriptions.clear();
    super.dispose();
  }
}