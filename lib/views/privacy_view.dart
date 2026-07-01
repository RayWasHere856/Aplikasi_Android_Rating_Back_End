import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';

// Kode ini digunakan untuk membuat halaman statis (StatelessWidget) yang menampilkan informasi kebijakan privasi aplikasi
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Kode ini digunakan untuk membuat kerangka dasar halaman layar kebijakan privasi
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Kode ini digunakan agar warna latar belakang gradasi menyatu hingga menembus ke belakang AppBar
      extendBodyBehindAppBar: true,
      
      // Kode ini digunakan untuk membuat bagian navigasi atas (AppBar) menjadi transparan
      appBar: AppBar(
        title: const Text(
          'Kebijakan Privasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      // Kode ini digunakan untuk menerapkan latar belakang warna gradasi khusus pada keseluruhan halaman
      body: GradientBackground(
        // Kode ini digunakan agar teks kebijakan privasi yang panjang dapat digeser (scroll) ke bawah
        child: SingleChildScrollView(
          // Kode ini digunakan untuk memberikan jarak (ruang kosong) khusus di kiri, atas, kanan, dan bawah konten agar tidak menabrak tepi layar
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
          // Kode ini digunakan untuk menyusun ikon, judul, dan teks kebijakan privasi secara vertikal (dari atas ke bawah)
          child: Column(
            children: [
              // Kode ini digunakan untuk menampilkan ikon keamanan atau tameng besar berwarna biru di bagian atas halaman
              const Icon(
                Icons.security_outlined,
                size: 80,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 20),
              
              // Kode ini digunakan untuk menampilkan teks judul utama halaman
              const Text(
                'Komitmen Privasi Kami',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              
              // Kode ini digunakan untuk menampilkan tanggal pembaruan informasi kebijakan privasi
              const Text(
                'Terakhir diperbarui: April 2026',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 30),

              // Kode ini digunakan untuk memanggil fungsi pembuat kotak kartu yang berisi poin pertama kebijakan privasi
              _buildPrivacyCard(
                title: '1. Pengantar',
                content:
                    'Selamat datang di Ratting App. Kami dari Kelompok Tryhard sangat menghargai privasi Anda dan berkomitmen untuk melindungi data pribadi Anda melalui teknologi enkripsi terbaru.',
              ),
              // Kode ini digunakan untuk memanggil fungsi pembuat kotak kartu yang berisi poin kedua
              _buildPrivacyCard(
                title: '2. Pengumpulan Data',
                content:
                    'Kami hanya mengumpulkan informasi yang Anda berikan secara sukarela, seperti nama pengguna untuk personalisasi pengalaman aplikasi dan interaksi komentar pada film.',
              ),
              // Kode ini digunakan untuk memanggil fungsi pembuat kotak kartu yang berisi poin ketiga
              _buildPrivacyCard(
                title: '3. Keamanan Informasi',
                content:
                    'Tim Kelompok Tryhard menerapkan standar keamanan tinggi untuk mencegah akses tidak sah. Data Anda disimpan dalam lingkungan cloud yang terenkripsi dan dipantau secara berkala.',
              ),
              // Kode ini digunakan untuk memanggil fungsi pembuat kotak kartu yang berisi poin keempat
              _buildPrivacyCard(
                title: '4. Penggunaan Pihak Ketiga',
                content:
                    'Aplikasi ini menggunakan layanan YouTube Player API. Dengan menggunakan fitur video, Anda juga tunduk pada Ketentuan Layanan dan Kebijakan Privasi YouTube.',
              ),
              // Kode ini digunakan untuk memanggil fungsi pembuat kotak kartu yang berisi poin kelima
              _buildPrivacyCard(
                title: '5. Hak Pengguna',
                content:
                    'Anda berhak untuk mengubah atau menghapus data ulasan dan komentar Anda kapan saja melalui fitur manajemen akun yang kami sediakan.',
              ),

              const SizedBox(height: 30),

              // Kode ini digunakan untuk menampilkan teks hak cipta (footer) di bagian paling bawah halaman
              const Text(
                'Dibuat dengan dedikasi tinggi oleh',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
              const Text(
                'KELOMPOK TRYHARD',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Kode ini digunakan sebagai fungsi pembantu (helper) untuk mendesain kotak teks tiap poin kebijakan agar seragam dan kodenya tidak diulang-ulang
  Widget _buildPrivacyCard({required String title, required String content}) {
    // Kode ini digunakan untuk membuat kotak pembungkus teks dengan latar belakang agak transparan, sudut melengkung, dan garis tepi tipis
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kode ini digunakan untuk menampilkan teks judul (poin nomor) dengan warna biru tebal
          Text(
            title,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          
          // Kode ini digunakan untuk menampilkan teks penjelasan detail dari masing-masing poin dengan jarak antar baris yang nyaman dibaca
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}