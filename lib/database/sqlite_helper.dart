import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/movie.dart';
import 'dart:convert';

class SqliteHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ratting_app.db');

    return await openDatabase(
      path,
      version: 2, // naik versi karena ada perubahan schema
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cached_movies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        imageUrl TEXT,
        releaseYear TEXT,
        duration TEXT,
        rating REAL,
        ratingIMDB REAL,
        genres TEXT,
        director TEXT,
        actors TEXT,
        description TEXT,
        trailerUrl TEXT,
        cachedAt INTEGER
      )
    ''');

    // Tambah kolom userId agar favorit per-user
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        imageUrl TEXT,
        releaseYear TEXT,
        duration TEXT,
        rating REAL,
        ratingIMDB REAL,
        genres TEXT,
        director TEXT,
        actors TEXT,
        description TEXT,
        trailerUrl TEXT,
        addedAt INTEGER,
        UNIQUE(userId, title)
      )
    ''');
  }

  // Migrasi dari versi lama ke versi baru
  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Hapus tabel lama dan buat ulang dengan schema baru
      await db.execute('DROP TABLE IF EXISTS favorites');
      await db.execute('''
        CREATE TABLE favorites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          title TEXT NOT NULL,
          imageUrl TEXT,
          releaseYear TEXT,
          duration TEXT,
          rating REAL,
          ratingIMDB REAL,
          genres TEXT,
          director TEXT,
          actors TEXT,
          description TEXT,
          trailerUrl TEXT,
          addedAt INTEGER,
          UNIQUE(userId, title)
        )
      ''');
    }
  }

  // ── Helper konversi

  static Map<String, dynamic> movieToMap(Movie movie,
      {String? userId}) {
    return {
      if (userId != null) 'userId': userId,
      'title': movie.title,
      'imageUrl': movie.imageUrl,
      'releaseYear': movie.releaseYear,
      'duration': movie.duration,
      'rating': movie.rating,
      'ratingIMDB': movie.ratingIMDB,
      'genres': jsonEncode(movie.genres),
      'director': movie.director,
      'actors': movie.actors,
      'description': movie.description,
      'trailerUrl': movie.trailerUrl,
      if (userId != null)
        'addedAt': DateTime.now().millisecondsSinceEpoch
      else
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Movie mapToMovie(Map<String, dynamic> map) {
    return Movie(
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      releaseYear: map['releaseYear'] ?? '',
      duration: map['duration'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      ratingIMDB: (map['ratingIMDB'] ?? 0.0).toDouble(),
      genres: List<String>.from(jsonDecode(map['genres'] ?? '[]')),
      director: map['director'] ?? '',
      actors: map['actors'] ?? '',
      description: map['description'] ?? '',
      trailerUrl: map['trailerUrl'] ?? '',
    );
  }

  // CACHED MOVIES

  static Future<void> cacheMovies(List<Movie> movies) async {
    final db = await database;
    await db.delete('cached_movies');
    final batch = db.batch();
    for (final movie in movies) {
      batch.insert('cached_movies', movieToMap(movie),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Movie>> getCachedMovies() async {
    final db = await database;
    final maps = await db.query('cached_movies');
    return maps.map((m) => mapToMovie(m)).toList();
  }

  static Future<bool> isCacheValid() async {
    final db = await database;
    final result = await db.query('cached_movies',
        columns: ['cachedAt'], orderBy: 'cachedAt DESC', limit: 1);
    if (result.isEmpty) return false;
    final cachedAt = result.first['cachedAt'] as int?;
    if (cachedAt == null) return false;
    final diff = DateTime.now().millisecondsSinceEpoch - cachedAt;
    return diff < const Duration(hours: 1).inMilliseconds;
  }

  // FAVORITES per user

  /// Tambah favorit untuk user tertentu
  static Future<void> addFavorite(String userId, Movie movie) async {
    final db = await database;
    await db.insert(
      'favorites',
      movieToMap(movie, userId: userId),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Hapus favorit untuk user tertentu
  static Future<void> removeFavorite(String userId, String title) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'userId = ? AND title = ?',
      whereArgs: [userId, title],
    );
  }

  /// Ambil semua favorit milik user tertentu
  static Future<List<Movie>> getFavorites(String userId) async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'addedAt DESC',
    );
    return maps.map((m) => mapToMovie(m)).toList();
  }

  /// Cek apakah film sudah difavoritkan oleh user tertentu
  static Future<bool> isFavorite(String userId, String title) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'userId = ? AND title = ?',
      whereArgs: [userId, title],
    );
    return result.isNotEmpty;
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}