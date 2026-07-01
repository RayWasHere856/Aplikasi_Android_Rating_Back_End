import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ratting_test/views/about_view.dart';
import 'package:ratting_test/views/edit_profile_view.dart';
import 'package:ratting_test/views/login_view.dart';
import 'privacy_view.dart';
import '../controllers/auth_controller.dart';
import '../providers/auth_provider.dart';
import '../widgets/gradient_background.dart';

class ProfileScreen extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final Function(String, String, String, String) onProfileChanged;

  const ProfileScreen({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.onProfileChanged,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ── Load data via AuthProvider ──────────────────────────

  Future<void> _loadUserData() async {
    await context.read<AuthProvider>().reloadUser();
    final base64 = await AuthController.loadPhotoBase64();
    if (mounted) {
      setState(() => _photoBase64 = base64);
    }
  }

  // ── Logout via AuthProvider ──────────────────────────────

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F005C),
        title: const Text('Sign Out',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Yakin ingin keluar dari akun ini?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    await context.read<AuthProvider>().logout();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // context.watch agar nama/email otomatis update jika berubah (mis. setelah edit profil)
    final authProvider = context.watch<AuthProvider>();
    final String fullName = authProvider.displayName;
    final String displayEmail = authProvider.email;

    final String initials = fullName.trim().isNotEmpty
        ? fullName
            .trim()
            .split(' ')
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    // Widget avatar: base64 > inisial
    Widget avatarWidget;
    if (_photoBase64 != null && _photoBase64!.isNotEmpty) {
      avatarWidget = CircleAvatar(
        radius: 52,
        backgroundImage: MemoryImage(base64Decode(_photoBase64!)),
      );
    } else {
      avatarWidget = CircleAvatar(
        radius: 52,
        backgroundColor: Colors.blueAccent.withOpacity(0.2),
        child: Text(initials,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Profil Saya",
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [

              // ── Header Profil ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  children: [
                    avatarWidget,
                    const SizedBox(height: 16),
                    Text(fullName,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(displayEmail,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.5))),
                  ],
                ),
              ),

              // ── Menu List ──
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30)),
                  ),
                  child: ListView(
                    children: [
                      _buildMenuItem(
                        context,
                        Icons.settings_outlined,
                        "Edit Profil",
                        () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(
                                currentFirstName: fullName,
                                currentLastName: "",
                                currentEmail: displayEmail,
                                currentPassword: "",
                                onSave: widget.onProfileChanged,
                              ),
                            ),
                          );
                          // Reload data setelah kembali dari edit
                          if (!mounted) return;
                          _loadUserData();
                        },
                      ),
                      _buildMenuItem(
                        context,
                        Icons.info_outline_rounded,
                        "About Us",
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AboutUsScreen()),
                        ),
                      ),
                      _buildMenuItem(
                        context,
                        Icons.privacy_tip_outlined,
                        "Kebijakan Pengguna",
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen()),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Colors.white12),
                      ),

                      _buildMenuItem(
                        context,
                        Icons.logout_rounded,
                        "Sign Out",
                        _handleLogout,
                        color: Colors.redAccent,
                        textColor: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? Colors.blueAccent).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color ?? Colors.blueAccent, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
                color: textColor ?? Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 15)),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 14,
            color: (color ?? Colors.white).withOpacity(0.3)),
        onTap: onTap,
      ),
    );
  }
}