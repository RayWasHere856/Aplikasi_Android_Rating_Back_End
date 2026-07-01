import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../controllers/movie_controller.dart' as movie_ctrl;

class FavoriteProvider extends ChangeNotifier {
  /// Daftar film favorit milik user yang sedang login (in-memory, dari SQLite)
  List<Movie> get favoriteMovies => movie_ctrl.favoriteMovies;

  /// Panggil sekali setelah user login (mis. di splash atau home initState)
  Future<void> loadFavorites() async {
    await movie_ctrl.MovieController.loadFavorites();
    notifyListeners();
  }

  bool isFavorite(Movie movie) {
    return movie_ctrl.MovieController.isFavorite(movie);
  }

  Future<void> toggle(Movie movie) async {
    await movie_ctrl.MovieController.toggleFavorite(movie);
    notifyListeners();
  }
}