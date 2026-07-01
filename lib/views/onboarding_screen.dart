import 'package:flutter/material.dart';
import 'package:ratting_test/views/policy_view.dart';
import '../widgets/gradient_background.dart';

// Kode ini digunakan untuk membuat cetakan data (model) yang menyimpan informasi judul, deskripsi, dan gambar untuk tiap halaman perkenalan
class OnboardingData {
  final String title;
  final String description;
  final String image;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
  });
}

// Kode ini digunakan untuk membuat kerangka halaman OnboardingScreen yang bersifat dinamis (StatefulWidget)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Kode ini digunakan untuk mengontrol dan mendeteksi pergeseran halaman (swipe) pada layar
  final PageController _pageController = PageController();
  
  // Kode ini digunakan untuk melacak urutan halaman keberapa yang sedang aktif dilihat oleh pengguna
  int _currentPage = 0;

  // Kode ini digunakan untuk menyimpan daftar konten (teks dan gambar ilustrasi) yang akan ditampilkan di masing-masing halaman
  final List<OnboardingData> onboardingContent = [
    OnboardingData(
      title: "Temukan Film Yang Pas Untuk Kamu",
      description:
          "Temukan ribuan koleksi film terbaru dan terpopuler dari seluruh dunia hanya dalam satu aplikasi.",
      image: 'assets/logos/gambar-3.jpg',
    ),
    OnboardingData(
      title: "Rating & Review",
      description:
          "Berikan penilaianmu dan tulis komentar jujur untuk membantu komunitas menemukan tontonan terbaik.",
      image: 'assets/logos/gambar-2.png',
    ),
    OnboardingData(
      title: "Pantau Tren",
      description:
          "Dapatkan rekomendasi film yang sedang tren setiap harinya berdasarkan minat dan selera pribadimu.",
      image: 'assets/logos/gambar-1.png',
    ),
  ];

  // Kode ini digunakan untuk memproses perpindahan ke halaman perkenalan selanjutnya secara halus (animasi)
  void _nextPage() {
    if (_currentPage < onboardingContent.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Kode ini digunakan untuk berpindah ke halaman Kebijakan (PolicyScreen) jika pengguna sudah mencapai halaman perkenalan terakhir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PolicyScreen()),
      );
    }
  }

  // Kode ini digunakan untuk memproses perpindahan kembali ke halaman perkenalan sebelumnya
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kode ini digunakan untuk membuat struktur dasar layar aplikasi
    return Scaffold(
      backgroundColor: Colors.transparent,
      
      // Kode ini digunakan untuk memberikan latar belakang gradasi warna pada layar
      body: GradientBackground(
        // Kode ini digunakan untuk memastikan konten tidak tertutup oleh poni layar (notch) atau status bar
        child: SafeArea(
          child: Column(
            children: [
              // Kode ini digunakan agar area gambar dan teks memakan sebagian besar ruang kosong di layar
              Expanded(
                // Kode ini digunakan untuk membuat area konten yang bisa digeser-geser ke kiri dan kanan (swipe)
                child: PageView.builder(
                  controller: _pageController,
                  // Kode ini digunakan untuk memperbarui angka '_currentPage' setiap kali layar berhasil digeser
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: onboardingContent.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(30.0),

                      // Kode ini digunakan untuk membuat desain kartu pembungkus dengan sudut melengkung dan garis tepi transparan
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Kode ini digunakan untuk menampilkan gambar ilustrasi dengan sudut yang agak melengkung
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.asset(
                                onboardingContent[index].image,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 40),
                            
                            // Kode ini digunakan untuk menampilkan teks judul utama pada kartu perkenalan
                            Text(
                              onboardingContent[index].title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Kode ini digunakan untuk menampilkan teks deskripsi penjelasan singkat
                            Text(
                              onboardingContent[index].description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Kode ini digunakan untuk menyusun titik-titik indikator halaman secara menyamping di bawah kartu
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  onboardingContent.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    // Kode ini digunakan untuk memperpanjang ukuran titik indikator jika halamannya sedang aktif dilihat
                    width: _currentPage == index ? 25.0 : 10.0,
                    height: 10.0,
                    // Kode ini digunakan untuk memberikan warna biru pada titik aktif, dan putih pudar untuk titik lainnya
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Colors.blueAccent
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Kode ini digunakan untuk membungkus area tombol navigasi bagian bawah ('Kembali' dan 'Lanjut')
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30.0,
                  vertical: 30.0,
                ),
                // Kode ini digunakan untuk mendorong tombol 'Kembali' ke ujung kiri dan 'Lanjut' ke ujung kanan
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Kode ini digunakan untuk menyembunyikan tombol 'Kembali' (menjadi ruang kosong) jika pengguna berada di halaman pertama (index 0)
                    _currentPage == 0
                        ? const SizedBox(width: 100)
                        : TextButton(
                            onPressed: _previousPage,
                            child: const Text(
                              'Kembali',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          
                    // Kode ini digunakan untuk membuat tombol aksi utama untuk berpindah ke halaman selanjutnya
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      // Kode ini digunakan untuk mengubah teks tombol menjadi 'Selesai' jika pengguna sudah berada di halaman paling akhir
                      child: Text(
                        _currentPage == onboardingContent.length - 1
                            ? 'Selesai'
                            : 'Lanjut',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}