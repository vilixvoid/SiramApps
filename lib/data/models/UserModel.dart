class UserModel {
  final String username;
  final String token;

  UserModel({required this.username, required this.token});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? '',
      token: json['accessToken'] ?? '', // ✅ fix: 'accessToken' bukan 'token'
    );
  }
}
