import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ratting_test/views/movie_detail_view.dart';
import '../models/movie.dart';
import '../controllers/movie_controller.dart';
import '../providers/favorite_provider.dart';
import '../providers/movie_provider.dart';
import '../widgets/gradient_background.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    // Load favorit lewat FavoriteProvider (di dalamnya tetap dari SQLite)
    await context.read<FavoriteProvider>().loadFavorites();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _removeFavorite(Movie movie) async {
    await context.read<FavoriteProvider>().toggle(movie);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${movie.title} dihapus dari Favorit"),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // context.watch agar list otomatis rebuild saat favorit berubah
    final favoriteMovies = context.watch<FavoriteProvider>().favoriteMovies;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Daftar Favorit",
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: Colors.blueAccent))
              : favoriteMovies.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadFavorites,
                      color: Colors.blueAccent,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        itemCount: favoriteMovies.length,
                        itemBuilder: (context, index) {
                          final movie = favoriteMovies[index];
                          return _buildFavoriteCard(movie);
                        },
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.star_border, size: 80, color: Colors.white24),
          SizedBox(height: 15),
          Text("Belum ada film favorit",
              style: TextStyle(color: Colors.white54, fontSize: 16)),
          SizedBox(height: 8),
          Text("Tambahkan film dari halaman detail",
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(Movie movie) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => MovieDetailScreen(movie: movie)),
        );
        // Reload setelah kembali — favorit mungkin berubah
        if (!mounted) return;
        await _loadFavorites();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                movie.imageUrl,
                width: 80,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 110,
                  color: Colors.grey[900],
                  child: const Icon(Icons.broken_image,
                      color: Colors.white38),
                ),
              ),
            ),
            const SizedBox(width: 15),

            // Info Film
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    movie.genres.join(', '),
                    style: const TextStyle(
                        color: Colors.blueAccent, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Rating App realtime — baca dari cache MovieProvider
                  Consumer<MovieProvider>(
                    builder: (context, movieProvider, _) {
                      // Pastikan rating film ini juga didengarkan realtime
                      movieProvider.watchRating(movie.title);
                      return _buildRatingRow(
                        icon: Icons.thumb_up_alt_rounded,
                        color: Colors.lightGreenAccent,
                        label: 'App Rating',
                        value: movieProvider.ratingFor(movie.title),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildRatingRow(
                    icon: Icons.star_rounded,
                    color: Colors.amber,
                    label: 'IMDB',
                    value: movie.ratingIMDB,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.white38, size: 12),
                      const SizedBox(width: 4),
                      Text(movie.duration,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                      const SizedBox(width: 10),
                      const Icon(Icons.calendar_today,
                          color: Colors.white38, size: 12),
                      const SizedBox(width: 4),
                      Text(movie.releaseYear,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            // Tombol hapus
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.redAccent),
              onPressed: () => _removeFavorite(movie),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow({
    required IconData icon,
    required Color color,
    required String label,
    required double value,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Text(MovieController.formatRating(value),
            style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}