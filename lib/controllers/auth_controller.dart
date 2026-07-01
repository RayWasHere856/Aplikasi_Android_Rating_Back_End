import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AuthController {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // ── Getter ──────────────────────────────────────────────

  /// User yang sedang login
  static User? get currentUser => _auth.currentUser;

  /// UID user yang sedang login
  static String? get uid => _auth.currentUser?.uid;

  /// Nama tampilan user
  static String get displayName =>
      _auth.currentUser?.displayName ?? 'Guest User';

  /// Email user
  static String get email =>
      _auth.currentUser?.email ?? 'Belum ada email';

  // ── Auth ────────────────────────────────────────────────

  /// Login dengan email & password
  static Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Register akun baru
  static Future<UserCredential> register(
      String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    await credential.user?.updateDisplayName(name.trim());
    return credential;
  }

  /// Logout
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Profile ─────────────────────────────────────────────

  /// Reload data user terbaru dari Firebase
  static Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Update nama tampilan user di Firebase Auth
  static Future<void> updateDisplayName(String name) async {
    if (name.trim().isEmpty) throw Exception("Nama tidak boleh kosong!");
    await _auth.currentUser?.updateDisplayName(name.trim());
  }

  /// Update password user
  static Future<void> updatePassword(String newPassword) async {
    if (newPassword.trim().length < 6) {
      throw Exception("Password minimal harus 6 karakter!");
    }
    await _auth.currentUser?.updatePassword(newPassword.trim());
  }

  // ── Firestore — Data User ────────────────────────────────

  /// Ambil data user dari Firestore (termasuk foto base64)
  static Future<Map<String, dynamic>?> loadUserData() async {
    final id = uid;
    if (id == null) return null;

    final doc = await _db.collection('users').doc(id).get();
    if (doc.exists) return doc.data();
    return null;
  }

  /// Simpan data user ke Firestore
  static Future<void> saveUserData(Map<String, dynamic> data) async {
    final id = uid;
    if (id == null) throw Exception("User tidak ditemukan.");

    await _db.collection('users').doc(id).set(
          {...data, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
  }

  /// Ambil foto base64 dari Firestore
  static Future<String?> loadPhotoBase64() async {
    final data = await loadUserData();
    return data?['photoBase64'];
  }

  // ── Update Semua Sekaligus ───────────────────────────────

  /// Update nama, password (opsional), dan foto (opsional) sekaligus
  static Future<void> updateProfile({
    required String name,
    String? newPassword,
    File? photoFile,
  }) async {
    if (name.trim().isEmpty) throw Exception("Nama tidak boleh kosong!");

    // Update display name di Firebase Auth
    await updateDisplayName(name);

    // Update password jika diisi
    if (newPassword != null &&
        newPassword.trim().isNotEmpty &&
        newPassword.trim().length >= 6) {
      await _auth.currentUser?.updatePassword(newPassword.trim());
    }

    // Siapkan data untuk Firestore
    final Map<String, dynamic> firestoreData = {
      'displayName': name.trim(),
    };

    // Konversi foto ke base64 jika ada
    if (photoFile != null) {
      final bytes = await photoFile.readAsBytes();
      firestoreData['photoBase64'] = base64Encode(bytes);
    }

    // Simpan ke Firestore
    await saveUserData(firestoreData);

    // Reload agar perubahan langsung terlihat
    await reloadUser();
  }

  // ── Validasi ─────────────────────────────────────────────

  /// Validasi format email
  static void validateEmail(String email) {
    if (email.trim().isEmpty) throw Exception("Email tidak boleh kosong!");
    if (!email.contains('@')) {
      throw const FormatException(
          "Format email salah! Harus menggunakan karakter '@'.");
    }
  }

  /// Validasi password saat register
  static void validatePassword(String password) {
    if (password.trim().length < 6) {
      throw Exception("Password minimal harus 6 karakter!");
    }
  }

  /// Pesan error Firebase Auth yang lebih ramah
  static String friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Tidak ada akun dengan email tersebut.';
      case 'wrong-password':
        return 'Password salah, silakan coba lagi.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar sebelumnya.';
      case 'weak-password':
        return 'Password terlalu lemah.';
      case 'requires-recent-login':
        return 'Sesi login sudah lama. Silakan logout dan login kembali.';
      default:
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}