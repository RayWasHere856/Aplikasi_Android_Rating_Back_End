import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ratting_test/views/movie_detail_view.dart';
import 'dart:async';
import '../models/movie.dart';
import '../controllers/movie_controller.dart';
import '../providers/movie_provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/gradient_background.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({Key? key, required this.userName}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Movie> _foundMovies = [];
  bool _isLoading = true;
  bool _isOffline = false;
  String _errorMessage = '';

  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchMovies();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_foundMovies.isNotEmpty &&
          _currentPage <
              (_foundMovies.length > 3 ? 2 : _foundMovies.length - 1)) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _fetchMovies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Cek status koneksi
      final online = await MovieController.isOnline();

      // Ambil film lewat MovieProvider (offline-first tetap ditangani di controller)
      final movieProvider = context.read<MovieProvider>();
      await movieProvider.loadAllMovies();

      // Load favorit lewat FavoriteProvider
      await context.read<FavoriteProvider>().loadFavorites();

      // Mulai dengarkan rating realtime untuk setiap film yang baru dimuat
      for (final movie in movieProvider.allMovies) {
        movieProvider.watchRating(movie.title);
      }

      if (!mounted) return;
      setState(() {
        _foundMovies = movieProvider.allMovies;
        _isLoading = false;
        _isOffline = !online;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat data. Periksa koneksi internet.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _runFilter(String keyword) {
    final allMovies = context.read<MovieProvider>().allMovies;
    setState(() {
      _foundMovies = keyword.isEmpty
          ? allMovies
          : allMovies
              .where((m) =>
                  m.title.toLowerCase().contains(keyword.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // context.watch agar UI rebuild otomatis saat daftar film berubah
    final allMovies = context.watch<MovieProvider>().allMovies;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Selamat Datang, ${widget.userName}!',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent))
              : _errorMessage.isNotEmpty
                  ? _buildErrorState()
                  : RefreshIndicator(
                      onRefresh: _fetchMovies,
                      color: Colors.blueAccent,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),

                              // ── Banner offline ──
                              if (_isOffline)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color:
                                            Colors.orange.withOpacity(0.4)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.wifi_off_rounded,
                                          color: Colors.orange, size: 16),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Kamu sedang offline. Menampilkan data tersimpan.',
                                          style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // ── Search Bar ──
                              TextField(
                                onChanged: _runFilter,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Cari film favoritmu...',
                                  hintStyle:
                                      const TextStyle(color: Colors.white54),
                                  prefixIcon: const Icon(Icons.search,
                                      color: Colors.white54),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Colors.blueAccent),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── Banner Carousel ──
                              if (_foundMovies.isNotEmpty)
                                SizedBox(
                                  height: 180,
                                  child: PageView.builder(
                                    controller: _pageController,
                                    onPageChanged: (page) => setState(
                                        () => _currentPage = page),
                                    itemCount: _foundMovies.length > 3
                                        ? 3
                                        : _foundMovies.length,
                                    itemBuilder: (context, index) {
                                      final movie = _foundMovies[index];
                                      return GestureDetector(
                                        onTap: () => _navigateToDetail(movie),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 5.0),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(15.0),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                  movie.imageUrl),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15.0),
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  Colors.black
                                                      .withOpacity(0.8),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                            alignment: Alignment.bottomLeft,
                                            padding: const EdgeInsets.all(15),
                                            child: Text(
                                              movie.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              const SizedBox(height: 10),

                              // ── Dot Indicator ──
                              if (_foundMovies.isNotEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _foundMovies.length > 3
                                        ? 3
                                        : _foundMovies.length,
                                    (index) => Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4.0),
                                      width: _currentPage == index
                                          ? 20.0
                                          : 8.0,
                                      height: 8.0,
                                      decoration: BoxDecoration(
                                        color: _currentPage == index
                                            ? Colors.blueAccent
                                            : Colors.white38,
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 25),

                              // ── Trending Now ──
                              const Text('TRENDING NOW',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              const SizedBox(height: 10),

                              _foundMovies.isNotEmpty
                                  ? ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _foundMovies.length > 4
                                          ? 4
                                          : _foundMovies.length,
                                      itemBuilder: (context, index) {
                                        final movie = _foundMovies[index];
                                        return GestureDetector(
                                          onTap: () =>
                                              _navigateToDetail(movie),
                                          child: Card(
                                            margin: const EdgeInsets.only(
                                                bottom: 15),
                                            color: Colors.white
                                                .withOpacity(0.05),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              side: const BorderSide(
                                                  color: Colors.white10),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(15),
                                                    bottomLeft:
                                                        Radius.circular(15),
                                                  ),
                                                  child: Image.network(
                                                    movie.imageUrl,
                                                    width: 100,
                                                    height: 130,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) =>
                                                            Container(
                                                      width: 100,
                                                      height: 130,
                                                      color: Colors.grey[900],
                                                      child: const Icon(
                                                          Icons.movie,
                                                          color: Colors.white38,
                                                          size: 40),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 15),
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12,
                                                        horizontal: 4),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          movie.title,
                                                          style: const TextStyle(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .white),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          movie.genres
                                                              .join(', '),
                                                          style: const TextStyle(
                                                              color: Colors
                                                                  .blueAccent,
                                                              fontSize: 11),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        // Rating App realtime — baca dari cache MovieProvider
                                                        Consumer<MovieProvider>(
                                                          builder: (context,
                                                              movieProvider,
                                                              _) {
                                                            return _buildRatingRow(
                                                              icon: Icons
                                                                  .thumb_up_alt_rounded,
                                                              color: Colors
                                                                  .lightGreenAccent,
                                                              label: 'App',
                                                              value:
                                                                  movieProvider
                                                                      .ratingFor(
                                                                          movie
                                                                              .title),
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        _buildRatingRow(
                                                          icon: Icons
                                                              .star_rounded,
                                                          color: Colors.amber,
                                                          label: 'IMDB',
                                                          value:
                                                              movie.ratingIMDB,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : const Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 40.0),
                                      child: Center(
                                        child: Text('Film tidak ditemukan',
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white54)),
                                      ),
                                    ),

                              const SizedBox(height: 25),

                              // ── Grid Semua Film ──
                              const Text('TEMUKAN FILM YANG KAMU CARI',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              const SizedBox(height: 10),

                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.7,
                                ),
                                itemCount: allMovies.length,
                                itemBuilder: (context, index) {
                                  final movie = allMovies[index];
                                  return GestureDetector(
                                    onTap: () => _navigateToDetail(movie),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        image: DecorationImage(
                                          image:
                                              NetworkImage(movie.imageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.9),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              movie.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            // Rating App realtime — baca dari cache MovieProvider
                                            Consumer<MovieProvider>(
                                              builder:
                                                  (context, movieProvider, _) {
                                                return _buildRatingRow(
                                                  icon: Icons
                                                      .thumb_up_alt_rounded,
                                                  color: Colors
                                                      .lightGreenAccent,
                                                  label: 'App',
                                                  value: movieProvider
                                                      .ratingFor(movie.title),
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 2),
                                            _buildRatingRow(
                                              icon: Icons.star_rounded,
                                              color: Colors.amber,
                                              label: 'IMDB',
                                              value: movie.ratingIMDB,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Future<void> _navigateToDetail(Movie movie) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => MovieDetailScreen(movie: movie)),
    );
    // Reload favorit setelah kembali dari detail
    if (!mounted) return;
    await context.read<FavoriteProvider>().loadFavorites();
    if (mounted) setState(() {});
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 60, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('Tidak ada koneksi internet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_errorMessage,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent),
            onPressed: _fetchMovies,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Coba Lagi',
                style: TextStyle(color: Colors.white)),
          ),
        ],
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