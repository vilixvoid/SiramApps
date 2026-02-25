class ProfileModel {
  final int id;
  final String name;
  final String email;
  final String username;
  final String phone;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.phone,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}
