import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Untuk emulator Android gunakan 10.0.2.2.
  // Untuk device fisik gunakan IP host di jaringan yang sama.
  static const String baseUrl = "http://10.0.2.2:3000/api";

  // DASHBOARD
  static Future<Map<String, dynamic>> getDashboard(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/dashboard"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint("=== DASHBOARD ===");
    debugPrint("STATUS : ${response.statusCode}");
    debugPrint("BODY   : ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      "Gagal mengambil dashboard (${response.statusCode})",
    );
  }

  // ALERTS
  static Future<List<dynamic>> getAlerts(String token) async {

    debugPrint("Token Alert = $token");
    debugPrint(token);

    final response = await http.get(
      Uri.parse("$baseUrl/alerts"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint("=== ALERTS ===");
    debugPrint("STATUS : ${response.statusCode}");
    debugPrint("BODY   : ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['data'] != null &&
          data['data']['alerts'] != null) {
        return data['data']['alerts'];
      }

      return [];
    }

    throw Exception(
      "Gagal mengambil alerts (${response.statusCode})",
    );
  }

}