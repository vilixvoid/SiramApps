import 'package:flutter/material.dart';
import 'package:siram/data/models/ProfileModel.dart';
import 'package:siram/data/repositories/ProfileRepository.dart';

enum ProfileState { idle, loading, success, error }

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileViewModel(this._repository);

  ProfileState _state = ProfileState.idle;
  ProfileModel? _profile;
  String _errorMessage = '';

  ProfileState get state => _state;
  ProfileModel? get profile => _profile;
  String get errorMessage => _errorMessage;
  bool get isLoading => _state == ProfileState.loading;

  Future<void> fetchProfile() async {
    _state = ProfileState.loading;
    notifyListeners();

    try {
      _profile = await _repository.getProfile();
      _state = ProfileState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = ProfileState.error;
    }

    notifyListeners();
  }
}
