class User {
  final String id, username, fullName;
  User({required this.id, required this.username, required this.fullName});
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      fullName: json['fullName'],
    );
  }
}

