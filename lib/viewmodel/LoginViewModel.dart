import 'package:flutter/material.dart';
import 'package:siram/data/models/UserModel.dart';
import 'package:siram/data/repositories/AuthRepository.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  LoginViewModel(this._repository);

  bool _isLoading = false;
  UserModel? _currentUser;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  String get errorMessage => _errorMessage;

  Future<UserModel> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _repository.login(username, password);
      _currentUser = user;
      return user;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _errorMessage = '';
    await _repository.logout();
    notifyListeners();
  }
}