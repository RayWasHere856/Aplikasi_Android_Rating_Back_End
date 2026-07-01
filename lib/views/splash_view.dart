import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ratting_test/controllers/prefference_controller.dart';
import 'package:ratting_test/providers/auth_provider.dart';
import 'package:ratting_test/views/onboarding_screen.dart';
import 'package:ratting_test/views/login_view.dart';
import 'package:ratting_test/views/main_view.dart';
import '../widgets/gradient_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    // Tunda sebentar agar splash screen sempat terlihat
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // ── PRIORITAS 1: Cek apakah user sudah login lewat AuthProvider ──
    // context.read karena kita hanya butuh nilainya sekali, bukan listen perubahan
    final authProvider = context.read<AuthProvider>();
    final bool isLoggedIn = authProvider.isLoggedIn;

    if (isLoggedIn) {
      // User sudah login → langsung ke Home, skip semua
      final String userName = authProvider.currentUser?.displayName ??
          authProvider.currentUser?.email?.split('@')[0] ??
          'User';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainWrapper(userName: userName),
        ),
      );
      return;
    }

    // ── PRIORITAS 2: Cek apakah sudah pernah onboarding ──
    final bool hasSeenOnboarding = await PreferencesController.isOnboardingDone();

    if (!mounted) return;

    if (hasSeenOnboarding) {
      // Sudah pernah onboarding → langsung ke Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      // Pertama kali buka app → tampilkan Onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kode ini digunakan untuk menampilkan splash screen dengan latar belakang
    // tema Stellar Drift (ungu-biru) dan logo aplikasi di tengah
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo aplikasi ──
              Image.asset(
                'assets/logos/logo-no-title.png',
                width: 140,
                height: 140,
              ),
              const SizedBox(height: 30),

              const Text(
                'Rating Film',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Temukan & nilai film favoritmu',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 45),

              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white70,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}