import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movie.dart';
import '../controllers/movie_controller.dart';
import '../providers/auth_provider.dart';
import '../providers/movie_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/movie_detail_provider.dart';
import '../widgets/gradient_background.dart';

class MovieDetailScreen extends StatelessWidget {
  final Movie movie;
  const MovieDetailScreen({Key? key, required this.movie}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.currentUser?.uid ?? '';
    final userName = authProvider.currentUser?.displayName ??
        authProvider.currentUser?.email?.split('@')[0] ??
        'User';

    // Daftarkan MovieDetailProvider untuk scope halaman ini
    return ChangeNotifierProvider(
      create: (_) => MovieDetailProvider(
        movieTitle: movie.title,
        uid: uid,
        userName: userName,
      ),
      child: _MovieDetailView(movie: movie),
    );
  }
}

// Widget utama yang sudah bisa mengakses MovieDetailProvider
class _MovieDetailView extends StatefulWidget {
  final Movie movie;
  const _MovieDetailView({required this.movie});

  @override
  State<_MovieDetailView> createState() => _MovieDetailViewState();
}

class _MovieDetailViewState extends State<_MovieDetailView> {
  final TextEditingController _commentController = TextEditingController();
  late YoutubePlayerController _youtubeController;

  @override
  void initState() {
    super.initState();

    final videoId = YoutubePlayerController.convertUrlToId(
        widget.movie.trailerUrl);
    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: videoId ?? '',
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
      ),
    );

    // Mulai dengarkan rating realtime film ini lewat MovieProvider
    context.read<MovieProvider>().watchRating(widget.movie.title);
  }

  @override
  void dispose() {
    _youtubeController.close();
    _commentController.dispose();
    super.dispose();
  }

  // ── Dialog Edit Komentar ──────────────────────────────────

  Future<void> _showEditDialog(String docId, String oldText) async {
    final controller = TextEditingController(text: oldText);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F005C),
        title: const Text('Edit Komentar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white10)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.blueAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      await context.read<MovieDetailProvider>().editComment(docId, result);
    }
  }

  // ── Dialog Konfirmasi Hapus ───────────────────────────────

  Future<void> _showDeleteDialog(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F005C),
        title: const Text('Hapus Komentar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Yakin ingin menghapus komentar ini?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<MovieDetailProvider>().deleteComment(docId);
    }
  }

  // ── Tambah Komentar ───────────────────────────────────────

  Future<void> _addComment() async {
    try {
      FocusScope.of(context).unfocus();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
      await context
          .read<MovieDetailProvider>()
          .addComment(_commentController.text);
      if (!mounted) return;
      Navigator.pop(context);
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Komentar berhasil ditambahkan!',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            e is Exception
                ? e.toString().replaceAll("Exception: ", "")
                : "Terjadi kesalahan.",
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFav = context.watch<FavoriteProvider>().isFavorite(widget.movie);
    final currentUid = context.watch<AuthProvider>().currentUser?.uid;
    final detailProvider = context.watch<MovieDetailProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.movie.title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Gambar Header ──
              Stack(
                children: [
                  Image.network(
                    widget.movie.imageUrl,
                    width: double.infinity,
                    height: 400,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 400,
                      color: Colors.black45,
                      child: const Icon(Icons.broken_image,
                          size: 50, color: Colors.white54),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 400,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xFF0A002A), Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),

                    // ── Judul + Favorit ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(widget.movie.title,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        IconButton(
                          onPressed: () async {
                            await context
                                .read<FavoriteProvider>()
                                .toggle(widget.movie);
                          },
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.redAccent : Colors.white54,
                            size: 28,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── Info Film ──
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.white54, size: 14),
                        const SizedBox(width: 4),
                        Text(widget.movie.releaseYear,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13)),
                        const SizedBox(width: 15),
                        const Icon(Icons.access_time,
                            color: Colors.white54, size: 14),
                        const SizedBox(width: 4),
                        Text(widget.movie.duration,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13)),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Rating ──
                    Row(
                      children: [
                        Consumer<MovieProvider>(
                          builder: (context, movieProvider, _) {
                            final appRating =
                                movieProvider.ratingFor(widget.movie.title);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.lightGreenAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.lightGreenAccent
                                        .withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.thumb_up_alt_rounded,
                                      color: Colors.lightGreenAccent, size: 14),
                                  const SizedBox(width: 5),
                                  const Text('App  ',
                                      style: TextStyle(
                                          color: Colors.lightGreenAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    appRating == 0.0
                                        ? 'Belum ada'
                                        : MovieController.formatRating(appRating),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.amber.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 14),
                              const SizedBox(width: 5),
                              const Text('IMDB  ',
                                  style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                MovieController.formatRating(
                                    widget.movie.ratingIMDB),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // ── Genre ──
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: widget.movie.genres
                          .map((genre) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.blueAccent.withOpacity(0.5)),
                                ),
                                child: Text(genre,
                                    style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: 20),
                    Text("Sutradara : ${widget.movie.director}",
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 5),
                    Text("Aktor        : ${widget.movie.actors}",
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 25),

                    // ── Sinopsis ──
                    const Text("SINOPSIS",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    Text(widget.movie.description,
                        style: const TextStyle(
                            fontSize: 15, height: 1.5, color: Colors.white70)),
                    const SizedBox(height: 30),

                    // ── Trailer ──
                    const Text("TRAILER",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: YoutubePlayer(
                        controller: _youtubeController,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ── Reaksi ──
                    const Text("REAKSI ANDA",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 15),

                    StreamBuilder<QuerySnapshot>(
                      stream: detailProvider.reactionsStream,
                      builder: (context, snapshot) {
                        int likes = 0, neutrals = 0, dislikes = 0;
                        if (snapshot.hasData) {
                          for (var doc in snapshot.data!.docs) {
                            final type = doc['type'];
                            if (type == 'like') likes++;
                            if (type == 'neutral') neutrals++;
                            if (type == 'dislike') dislikes++;
                          }
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildReactionButton(
                                icon: Icons.thumb_up_alt_rounded,
                                label: "Suka",
                                count: likes,
                                isSelected:
                                    detailProvider.selectedReaction == "like",
                                activeColor: Colors.greenAccent,
                                onTap: () =>
                                    detailProvider.handleReaction("like")),
                            _buildReactionButton(
                                icon: Icons.sentiment_neutral_rounded,
                                label: "Biasa",
                                count: neutrals,
                                isSelected:
                                    detailProvider.selectedReaction == "neutral",
                                activeColor: Colors.amberAccent,
                                onTap: () =>
                                    detailProvider.handleReaction("neutral")),
                            _buildReactionButton(
                                icon: Icons.thumb_down_alt_rounded,
                                label: "Kurang",
                                count: dislikes,
                                isSelected:
                                    detailProvider.selectedReaction == "dislike",
                                activeColor: Colors.redAccent,
                                onTap: () =>
                                    detailProvider.handleReaction("dislike")),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                    const Divider(color: Colors.white10, thickness: 1),
                    const SizedBox(height: 20),

                    // ── Komentar ──
                    const Text("KOMENTAR",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Tulis pendapatmu...",
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: const BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.send_rounded,
                                color: Colors.white),
                            onPressed: _addComment,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    StreamBuilder<QuerySnapshot>(
                      stream: detailProvider.commentsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.blueAccent));
                        }
                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'Belum ada komentar. Jadilah yang pertama!',
                                style: TextStyle(color: Colors.white38),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final isOwner = data['userId'] == currentUid;
                            final isEdited = data.containsKey('editedAt');
                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isOwner
                                      ? Colors.blueAccent.withOpacity(0.3)
                                      : Colors.white10,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        Colors.blueAccent.withOpacity(0.2),
                                    child: const Icon(Icons.person,
                                        color: Colors.blueAccent),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Text(data['userName'] ?? 'User',
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12)),
                                          if (isOwner) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blueAccent
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text('Anda',
                                                  style: TextStyle(
                                                      color: Colors.blueAccent,
                                                      fontSize: 10)),
                                            ),
                                          ],
                                          if (isEdited) ...[
                                            const SizedBox(width: 6),
                                            const Text('(diedit)',
                                                style: TextStyle(
                                                    color: Colors.white24,
                                                    fontSize: 10)),
                                          ],
                                        ]),
                                        const SizedBox(height: 5),
                                        Text(data['text'] ?? '',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                height: 1.4)),
                                      ],
                                    ),
                                  ),
                                  if (isOwner)
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert,
                                          color: Colors.white38, size: 18),
                                      color: const Color(0xFF1F005C),
                                      onSelected: (value) {
                                        if (value == 'edit')
                                          _showEditDialog(
                                              doc.id, data['text']);
                                        else if (value == 'delete')
                                          _showDeleteDialog(doc.id);
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(children: [
                                            Icon(Icons.edit,
                                                color: Colors.blueAccent,
                                                size: 16),
                                            SizedBox(width: 8),
                                            Text('Edit',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ]),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(children: [
                                            Icon(Icons.delete,
                                                color: Colors.redAccent,
                                                size: 16),
                                            SizedBox(width: 8),
                                            Text('Hapus',
                                                style: TextStyle(
                                                    color: Colors.redAccent)),
                                          ]),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionButton({
    required IconData icon,
    required String label,
    required int count,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(
                  color: isSelected ? activeColor : Colors.white10, width: 2),
            ),
            child: Icon(icon,
                color: isSelected ? activeColor : Colors.white54, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: isSelected ? activeColor : Colors.white54,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12)),
          const SizedBox(height: 4),
          Text(count.toString(),
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}