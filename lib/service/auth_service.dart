import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Ganti dengan IP kamu kalau test di device fisik
  // Untuk emulator Android pakai 10.0.2.2
  static const String _baseUrl = 'http://10.0.2.2:8080/api/auth';

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  // ── Simpan token ke SharedPreferences ─────────────────────────────────────
  static Future<void> saveTokens({
    required String token,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  // ── Simpan data user ───────────────────────────────────────────────────────
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  // ── Ambil token ────────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ── Ambil data user yang tersimpan ────────────────────────────────────────
  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Hapus semua data (logout) ──────────────────────────────────────────────
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  // ── Cek apakah sudah login ─────────────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── LOGIN ──────────────────────────────────────────────────────────────────
  // Returns: {'success': bool, 'message': String, 'data': Map?}
  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identifier': identifier,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        // Simpan token dan data user
        await saveTokens(
          token: data['token'],
          refreshToken: data['refresh_token'],
        );
        await saveUser(data['data']);
        return {'success': true, 'message': 'Login berhasil.', 'data': data['data']};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Login gagal.',
      };
    } on Exception catch (e) {
      return {
        'success': false,
        'message': _parseError(e),
      };
    }
  }

  // ── REGISTER ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String namaLengkap,
    String? nomorHandphone,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
              'nama_lengkap': namaLengkap,
              if (nomorHandphone != null && nomorHandphone.isNotEmpty)
                'nomor_handphone': nomorHandphone,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 && data['success'] == true) {
        return {'success': true, 'message': 'Registrasi berhasil.'};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Registrasi gagal.',
      };
    } on Exception catch (e) {
      return {
        'success': false,
        'message': _parseError(e),
      };
    }
  }

  // ── FORGOT PASSWORD ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'OTP terkirim.'};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mengirim OTP.',
      };
    } on Exception catch (e) {
      return {
        'success': false,
        'message': _parseError(e),
      };
    }
  }

  // ── RESET PASSWORD ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'otp': otp,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Password berhasil direset.'};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mereset password.',
      };
    } on Exception catch (e) {
      return {
        'success': false,
        'message': _parseError(e),
      };
    }
  }

  // ── Helper: parse error message ────────────────────────────────────────────
  static String _parseError(Exception e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'Tidak dapat terhubung ke server. Pastikan backend berjalan.';
    }
    if (msg.contains('TimeoutException')) {
      return 'Koneksi timeout. Coba lagi.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
