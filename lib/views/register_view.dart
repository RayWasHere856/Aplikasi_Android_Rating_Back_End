import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ratting_test/providers/auth_provider.dart';
import 'package:ratting_test/views/login_view.dart';
import 'main_view.dart';
import '../widgets/gradient_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final authProvider = context.read<AuthProvider>();

    final String namaUser = _firstNameController.text.trim();
    final String namaAkhir = _lastNameController.text.trim();
    final String fullName =
        namaAkhir.isNotEmpty ? '$namaUser $namaAkhir' : namaUser;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent)),
    );

    final bool success = await authProvider.register(
      _emailController.text,
      _passwordController.text,
      fullName,
    );

    if (!mounted) return;
    Navigator.pop(context); // tutup loading

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => MainWrapper(userName: fullName)),
      );
    } else {
      _showError(authProvider.errorMessage ?? "Registrasi gagal.");
      authProvider.clearError();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Buat Akun Baru",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Daftar untuk mulai merating film",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 40),

                  _buildTextField(
                    controller: _firstNameController,
                    label: "Nama Awal",
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 15),

                  _buildTextField(
                    controller: _lastNameController,
                    label: "Nama Akhir (Optional)",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 15),

                  _buildTextField(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),

                  _buildTextField(
                    controller: _passwordController,
                    label: "Password",
                    icon: Icons.lock,
                    isPassword: true,
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _handleRegister,
                      child: const Text(
                        "Daftar",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Sudah punya akun?",
                          style: TextStyle(color: Colors.white70)),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => LoginScreen()),
                          );
                        },
                        child: const Text("Login sekarang",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent)),
                      ),
                    ],
                  ),
                ],
              ),
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white54)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blueAccent)),
      ),
    );
  }
}