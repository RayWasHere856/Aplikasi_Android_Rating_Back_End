// Kode ini digunakan untuk mengimpor library bawaan Flutter untuk membangun antarmuka aplikasi
import 'dart:math';
import 'package:flutter/material.dart';

// Kode ini digunakan untuk menyimpan data posisi dan ukuran setiap bintang yang akan ditampilkan
class _StarData {
  final double x;
  final double y;
  final double size;
  final double opacity;

  const _StarData({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
  });
}

// Kode ini digunakan untuk menggambar titik-titik bintang secara acak di atas latar belakang
class _StarPainter extends CustomPainter {
  final List<_StarData> stars;

  const _StarPainter({required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      // Kode ini digunakan untuk menggambar setiap bintang sebagai lingkaran kecil putih semi-transparan
      final paint = Paint()
        ..color = Colors.white.withOpacity(star.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );

      // Kode ini digunakan untuk menambahkan efek pijar (glow) pada bintang yang lebih besar
      if (star.size > 1.2) {
        final glowPaint = Paint()
          ..color = const Color(0xFF90C0FF).withOpacity(star.opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

        canvas.drawCircle(
          Offset(star.x * size.width, star.y * size.height),
          star.size * 2,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Kode ini digunakan untuk membuat widget kustom bernama GradientBackground yang sifatnya statis (StatelessWidget)
class GradientBackground extends StatelessWidget {
  // Kode ini digunakan untuk menyiapkan variabel 'child' yang akan menampung widget/konten lain di dalam background ini
  final Widget child;

  // Kode ini digunakan sebagai konstruktor yang mewajibkan pemanggilan widget ini disertai dengan isi kontennya (child)
  const GradientBackground({Key? key, required this.child}) : super(key: key);

  // Kode ini digunakan untuk membuat daftar bintang secara acak dengan posisi, ukuran, dan kecerahan yang bervariasi
  static final List<_StarData> _stars = _generateStars();

  static List<_StarData> _generateStars() {
    final random = Random(42); // seed tetap agar tampilan konsisten setiap build
    return List.generate(110, (i) {
      return _StarData(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 1.3 + 0.4,
        opacity: random.nextDouble() * 0.55 + 0.25,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Kode ini digunakan untuk membuat wadah utama (container) yang bertindak sebagai latar belakang
    return Container(
      // Kode ini digunakan agar lebar dan tinggi latar belakang membentang penuh menyesuaikan ukuran layar perangkat
      width: double.infinity,
      height: double.infinity,
      // Kode ini digunakan untuk mendesain tampilan wadah dengan tema Stellar Drift — biru antariksa + ungu
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          // Kode ini digunakan untuk mengatur arah gradasi warna dari pojok kiri atas ke pojok kanan bawah
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // Kode ini digunakan untuk menentukan empat lapisan warna yang menciptakan kedalaman ruang angkasa
          colors: [
            Color(0xFF04102A), // biru antariksa sangat gelap (atas)
            Color(0xFF091830), // biru tengah malam
            Color(0xFF0E0D38), // transisi ke ungu-biru
            Color(0xFF14093C), // ungu antariksa dalam (bawah)
          ],
          // Kode ini digunakan untuk mengatur titik berhenti setiap warna agar transisi terasa natural
          stops: [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Kode ini digunakan untuk menggambar lapisan nebula biru samar di bagian tengah layar
          Positioned(
            left: -80,
            top: 80,
            child: Container(
              width: 320,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1A4090).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Kode ini digunakan untuk menggambar lapisan nebula ungu samar di bagian kanan bawah layar
          Positioned(
            right: -60,
            bottom: 120,
            child: Container(
              width: 280,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4428A8).withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Kode ini digunakan untuk menggambar semua titik bintang di atas latar belakang
          Positioned.fill(
            child: CustomPaint(
              painter: _StarPainter(stars: _stars),
            ),
          ),

          // Kode ini digunakan untuk meletakkan dan menampilkan konten utama aplikasi di atas semua lapisan latar belakang
          child,
        ],
      ),
    );
  }
}