import 'package:siram/core/services/ApiServices.dart';
import 'package:siram/data/models/ProfileModel.dart';

class ProfileRemoteDatasource {
  final ApiService _apiService;

  ProfileRemoteDatasource(this._apiService);

  Future<ProfileModel> getProfile() async {
    final response = await _apiService.get('data/profile');
    return ProfileModel.fromJson(response);
  }
}
