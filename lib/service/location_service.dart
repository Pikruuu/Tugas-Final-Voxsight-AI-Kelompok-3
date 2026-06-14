import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  // Ganti IP ini dengan IP komputermu saat mengetes di HP fisik
  // Atau biarkan 10.0.2.2 jika menggunakan Android Emulator
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  /// Mengambil data lokasi terbaru dari database backend
  static Future<Map<String, dynamic>> getLocation(String token, String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/$deviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['success'] == true) {
        return decodedData['data'];
      } else {
        throw Exception(decodedData['message'] ?? 'Gagal memuat lokasi terbaru.');
      }
    } catch (e) {
      throw Exception('Gagal menghubungi server: $e');
    }
  }

  /// Mengambil riwayat data lokasi dari database backend
  static Future<List<dynamic>> getLocationHistory(String token, String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/$deviceId/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['success'] == true) {
        return decodedData['data'] as List<dynamic>;
      } else {
        throw Exception(decodedData['message'] ?? 'Gagal memuat riwayat lokasi.');
      }
    } catch (e) {
      throw Exception('Gagal menghubungi server: $e');
    }
  }
}