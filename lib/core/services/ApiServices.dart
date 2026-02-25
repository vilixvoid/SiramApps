import 'dart:convert';
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

  // ================= TOKEN =================

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;

  // ================= POST =================

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (_token != null) "Authorization": "Bearer $_token",
    };

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

  // ================= GET =================

  Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (_token != null) "Authorization": "Bearer $_token",
    };

    final response = await http.get(url, headers: headers);

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
