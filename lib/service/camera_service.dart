import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class CameraService {
  final String url;
  WebSocketChannel? _channel;
  bool _isConnected = false;

  CameraService({required this.url});

  bool get isConnected => _isConnected;

  // Mengembalikan stream data dari WebSocket untuk streaming kamera
  Stream<String>? get stream =>
      _channel?.stream.map((event) => event.toString());

  /// Fungsi untuk memulai koneksi streaming WebSocket
  Future<void> connect() async {
    if (_isConnected) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      throw Exception('Gagal terhubung ke stream kamera: $e');
    }
  }

  /// Fungsi untuk menghentikan streaming WebSocket
  Future<void> disconnect() async {
    if (!_isConnected) return;
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  /// Membersihkan memori saat layar ditutup
  void dispose() {
    disconnect();
  }

  // ===========================================================================
  // FUNGSI REST API (HTTP) KE BACKEND
  // ===========================================================================

  // Ganti IP ini dengan IP komputermu saat mengetes di HP fisik
  // Atau biarkan 10.0.2.2 jika menggunakan Android Emulator
  static const String baseUrl = 'http://10.0.2.2:8080/api'; 

  /// Mengambil data status kamera terbaru dari database backend
  static Future<Map<String, dynamic>> getCameraStatus(String token, String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/camera/$deviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['success'] == true) {
        return decodedData['data'];
      } else {
        throw Exception(decodedData['message'] ?? 'Gagal memuat status kamera.');
      }
    } catch (e) {
      throw Exception('Gagal menghubungi server: $e');
    }
  }

  /// Mengambil riwayat data kamera dari database backend
  static Future<List<dynamic>> getCameraHistory(String token, String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/camera/$deviceId/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['success'] == true) {
        return decodedData['data'] as List<dynamic>;
      } else {
        throw Exception(decodedData['message'] ?? 'Gagal memuat riwayat kamera.');
      }
    } catch (e) {
      throw Exception('Gagal menghubungi server: $e');
    }
  }
}