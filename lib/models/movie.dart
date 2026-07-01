class Movie {
  final String title;
  final String imageUrl;
  final String releaseYear;
  final String duration;
  final double rating;       // rating dari user aplikasi
  final double ratingIMDB;   // rating dari IMDB
  final List<String> genres;
  final String director;
  final String actors;
  final String description;
  final String trailerUrl;

  Movie({
    required this.title,
    required this.imageUrl,
    required this.releaseYear,
    required this.duration,
    required this.rating,
    required this.ratingIMDB,
    required this.genres,
    required this.director,
    required this.actors,
    required this.description,
    required this.trailerUrl,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    List<String> parsedGenres = [];
    if (json['genres'] is String) {
      parsedGenres = (json['genres'] as String)
          .split(',')
          .map((e) => e.trim())
          .toList();
    } else if (json['genres'] is List) {
      parsedGenres = List<String>.from(json['genres']);
    }

    return Movie(
      title: json['title'] ?? 'No Title',
      imageUrl: json['imageUrl'] ?? '',
      releaseYear: json['releaseYear'] ?? 'Unknown',
      duration: json['duration'] ?? '0m',
      rating: (json['rating'] ?? 0.0).toDouble(),
      ratingIMDB: (json['ratingIMDB'] ?? 0.0).toDouble(),
      genres: parsedGenres,
      director: json['director'] ?? 'Unknown',
      actors: json['actors'] ?? 'Unknown',
      description: json['description'] ?? 'No Description',
      trailerUrl: json['trailerUrl'] ?? '',
    );
  }
}