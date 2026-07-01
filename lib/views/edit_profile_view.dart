import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import '../providers/auth_provider.dart';
import '../widgets/gradient_background.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentFirstName;
  final String currentLastName;
  final String currentEmail;
  final String currentPassword;
  final Function(String, String, String, String) onSave;

  const EditProfileScreen({
    Key? key,
    required this.currentFirstName,
    required this.currentLastName,
    required this.currentEmail,
    required this.currentPassword,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _passwordController;

  File? _pickedImage;
  String? _currentPhotoBase64;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.currentFirstName);
    _passwordController = TextEditingController(text: "");
    _loadCurrentPhoto();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Load foto dari Firestore via Controller ─────────────
  // (foto belum dipindah ke AuthProvider, tetap akses controller langsung)

  Future<void> _loadCurrentPhoto() async {
    final base64 = await AuthController.loadPhotoBase64();
    if (base64 != null && mounted) {
      setState(() => _currentPhotoBase64 = base64);
    }
  }

  // ── Pilih foto ──────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 70,
    );
    if (picked != null && mounted) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F005C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Pilih Sumber Foto',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Simpan via AuthProvider ──────────────────────────────

  Future<void> _saveChanges() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent)),
      );

      // Update nama & password tetap lewat AuthController.updateProfile
      // (method ini juga menangani photoFile & saveUserData ke Firestore)
      await AuthController.updateProfile(
        name: _firstNameController.text,
        newPassword: _passwordController.text.trim().isNotEmpty
            ? _passwordController.text
            : null,
        photoFile: _pickedImage,
      );

      // Refresh AuthProvider supaya nama terbaru langsung tercermin
      // di seluruh halaman yang memakainya (mis. profile_view.dart)
      if (!mounted) return;
      await context.read<AuthProvider>().reloadUser();

      if (!mounted) return;
      Navigator.pop(context); // tutup loading

      widget.onSave(_firstNameController.text.trim(), "", "", "");
      Navigator.pop(context); // kembali ke profile

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui!',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      final msg = e is Exception
          ? e.toString().replaceAll("Exception: ", "")
          : "Terjadi kesalahan.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan tampilan avatar
    Widget avatarChild;
    if (_pickedImage != null) {
      avatarChild = CircleAvatar(
          radius: 60, backgroundImage: FileImage(_pickedImage!));
    } else if (_currentPhotoBase64 != null &&
        _currentPhotoBase64!.isNotEmpty) {
      avatarChild = CircleAvatar(
          radius: 60,
          backgroundImage: MemoryImage(base64Decode(_currentPhotoBase64!)));
    } else {
      final initials = widget.currentFirstName.isNotEmpty
          ? widget.currentFirstName
              .trim()
              .split(' ')
              .map((e) => e[0])
              .take(2)
              .join()
              .toUpperCase()
          : '?';
      avatarChild = CircleAvatar(
        radius: 60,
        backgroundColor: Colors.blueAccent.withOpacity(0.2),
        child: Text(initials,
            style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Edit Profil",
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ── Foto Profil ──
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      avatarChild,
                      GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _showImageSourceSheet,
                  child: const Text('Ganti Foto Profil',
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 24),

                // ── Form ──
                _buildTextField(
                  controller: _firstNameController,
                  label: "Nama Lengkap",
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: "Password Baru (Opsional)",
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Minimal 6 karakter. Kosongkan jika tidak ingin mengubah.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 11),
                  ),
                ),

                const SizedBox(height: 40),

                // ── Tombol Simpan ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _saveChanges,
                    child: const Text("Simpan Perubahan",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }
}