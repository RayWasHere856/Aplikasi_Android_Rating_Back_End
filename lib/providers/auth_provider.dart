import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get displayName => _currentUser?.displayName ?? 'Guest User';
  String get email => _currentUser?.email ?? 'Belum ada email';

  AuthProvider() {
    // Ambil status login secara langsung (synchronous) saat provider dibuat,
    // supaya tidak ada celah waktu sebelum stream authStateChanges sempat emit nilai pertamanya
    _currentUser = FirebaseAuth.instance.currentUser;

    // Mendengarkan perubahan status login secara realtime untuk update berikutnya
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  //Login

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AuthController.validateEmail(email);
      if (password.trim().isEmpty) {
        throw Exception("Password tidak boleh kosong!");
      }

      final credential = await AuthController.login(email, password);
      _currentUser = credential.user;

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthController.friendlyAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } on FormatException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  //Register

  Future<bool> register(String email, String password, String fullName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (fullName.trim().isEmpty) {
        throw Exception("Nama Awal tidak boleh kosong!");
      }
      AuthController.validateEmail(email);
      AuthController.validatePassword(password);

      final credential = await AuthController.register(email, password, fullName);
      _currentUser = credential.user;

      await AuthController.saveUserData({
        'displayName': fullName,
        'email': email.trim(),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } on FormatException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('firebase_auth') || msg.contains('[')) {
        final code = RegExp(r'\[.*?/(.+?)\]').firstMatch(msg)?.group(1) ?? '';
        _errorMessage = AuthController.friendlyAuthError(code);
      } else {
        _errorMessage = msg.replaceAll('Exception: ', '');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  //Logout

  Future<void> logout() async {
    await AuthController.logout();
    _currentUser = null;
    notifyListeners();
  }

  //Profile

  Future<void> reloadUser() async {
    await AuthController.reloadUser();
    _currentUser = FirebaseAuth.instance.currentUser;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}