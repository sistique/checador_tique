class User {
  final String username;
  final String passwordHash;
  final int empleadoId;

  User({required this.username, required this.passwordHash, required this.empleadoId});

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'passwordHash': passwordHash,
      'empleadoId': empleadoId,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'],
      passwordHash: map['passwordHash'],
      empleadoId: map['empleadoId'],
    );
  }
}
