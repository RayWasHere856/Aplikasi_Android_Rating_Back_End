import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class ApiService {
  static const String _url = 'https://gist.githubusercontent.com/RayWasHere856/f27cd25a371652b5a679ca95bf81ade2/raw/b55844d082a5f14928b1d0f8385ea85c3f9613c8/gistfile1.json';

  // Fungsi asynchronous untuk mengambil daftar film
  static Future<List<Movie>> fetchMovies() async {
    try {
      final response = await http.get(Uri.parse(_url));

      // Jika response sukses (kode 200 OK)
      if (response.statusCode == 200) {
        // 1. Ubah teks JSON mentah menjadi bentuk List/Map Dart
        final List<dynamic> parsedData = json.decode(response.body);

        // 2. Looping (map) semua data tersebut dan terjemahkan menggunakan Movie.fromJson
        return parsedData.map((jsonItem) => Movie.fromJson(jsonItem)).toList();
      } else {
        throw Exception('Gagal mengambil data dari server. Kode: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan atau parsing: $e');
    }
  }
}