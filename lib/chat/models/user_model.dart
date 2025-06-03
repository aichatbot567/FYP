class UserModel {
  String id;
  String username;
  String email;

  UserModel({this.id = '', this.username = 'Unknown', this.email = ''});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
    );
  }
}