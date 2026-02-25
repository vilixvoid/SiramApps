import 'package:siram/data/datasources/remote/ProfileRemoteDataSource.dart';
import 'package:siram/data/models/ProfileModel.dart';

class ProfileRepository {
  final ProfileRemoteDatasource _remoteDataSource;

  ProfileRepository(this._remoteDataSource);

  Future<ProfileModel> getProfile() async {
    try {
      return await _remoteDataSource.getProfile();
    } catch (e) {
      throw Exception('Gagal mengambil data profil: $e');
    }
  }
}
