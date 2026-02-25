import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:siram/core/services/ApiServices.dart';
import 'package:siram/data/models/UserModel.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  Future<UserModel> login(String username, String password) async {
    final data = await _apiService.post('auth/login', {
      'username': username,
      'password': password,
    });

    debugPrint('🧾 LOGIN RESPONSE: ${jsonEncode(data)}');

    final user = UserModel.fromJson(data);

    debugPrint('👤 TOKEN: "${user.token}"');

    if (user.token.isNotEmpty) {
      await _apiService.setToken(user.token); // ✅ await karena sekarang async
      debugPrint('✅ Token berhasil disimpan ke storage');
    } else {
      debugPrint('❌ TOKEN KOSONG');
    }

    return user;
  }

  Future<void> logout() async {
    await _apiService.clearToken();
  }
}
