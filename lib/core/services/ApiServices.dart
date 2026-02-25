import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late final String baseUrl;
  String? _token;

  static const _tokenKey = 'auth_token';

  ApiService() {
    baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    if (baseUrl.isEmpty) {
      throw Exception("API_BASE_URL belum di set di .env");
    }
  }

  // ✅ Load token dari storage saat app start
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  // ✅ Simpan token ke memory + storage
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // ✅ Hapus token dari memory + storage
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    final headers = <String, String>{
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    if (_token != null) {
      headers["Authorization"] = "Bearer $_token";
    }

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else if (response.statusCode == 401) {
      throw Exception('Sesi berakhir, silakan login kembali');
    } else {
      throw Exception(data['message'] ?? 'Terjadi kesalahan');
    }
  }
}
