import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';

// Kode ini digunakan untuk membuat halaman 'Tentang Kami' (About Us) yang berisi informasi aplikasi dan bersifat statis (StatelessWidget)
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Kode ini digunakan untuk membuat kerangka dasar halaman aplikasi
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Kode ini digunakan agar warna latar belakang gradasi menyatu hingga menembus ke belakang navigasi atas (AppBar)
      extendBodyBehindAppBar: true,
      
      // Kode ini digunakan untuk membuat bilah navigasi atas (AppBar) transparan dengan judul 'About Us'
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      // Kode ini digunakan untuk menerapkan widget latar belakang gradasi khusus yang telah dibuat
      body: GradientBackground(
        // Kode ini digunakan untuk memposisikan seluruh isi konten tepat di tengah layar
        child: Center(
          // Kode ini digunakan agar seluruh isi konten bisa digeser (di-scroll) jika ukuran layar pengguna terlalu kecil
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            // Kode ini digunakan untuk menyusun elemen gambar, teks, dan kotak info secara vertikal
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                // Kode ini digunakan untuk membuat bingkai lingkaran dengan garis tepi putih dan efek bayangan gelap (shadow) untuk logo aplikasi
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  // Kode ini digunakan untuk memotong sudut gambar logo agar menjadi bentuk lingkaran sempurna yang pas dengan bingkainya
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(65),
                    child: Image.asset(
                      'assets/logos/logo_apk.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Kode ini digunakan untuk menampilkan nama aplikasi dengan huruf tebal, besar, dan sedikit berjarak (letterSpacing)
                const Text(
                  'RATING APP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                // Kode ini digunakan untuk menampilkan informasi versi aplikasi saat ini
                const Text(
                  'Versi 1.0.0',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // Kode ini digunakan untuk membuat kotak informasi dengan efek kaca (Glassmorphism) yang transparan dan bergaris tepi tipis
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Column(
                    children: [
                      // Kode ini digunakan untuk menampilkan teks penjelasan singkat mengenai aplikasi dan pembuatnya
                      Text(
                        'Aplikasi Rating adalah platform modern untuk menemukan ulasan film terkini dengan antarmuka yang bersih dan interaktif yang dikembangkan oleh kelompok Tryhard.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Kode ini digunakan untuk membuat garis tipis pemisah antar elemen
                      Divider(color: Colors.white10),
                      SizedBox(height: 20),
                      
                      // Kode ini digunakan untuk menyusun ikon kode (</>) dan nama tim pengembang secara berdampingan di tengah
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.code, color: Colors.blueAccent, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'By Tryhard Team',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),

                // Kode ini digunakan untuk menampilkan teks hak cipta (copyright) di bagian paling bawah halaman
                const Text(
                  '© 2026 Tryhard Team',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}