class User {
  final int? id;
  final String username;
  final String passwordHash;
  final String role;
  final int? employeeId;
  final String? fullName;

  User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    this.employeeId,
    this.fullName,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password_hash': passwordHash,
      'role': role,
      'employee_id': employeeId,
      'full_name': fullName,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      role: map['role'] as String,
      employeeId: map['employee_id'] as int?,
      fullName: map['full_name'] as String?,
    );
  }
}
