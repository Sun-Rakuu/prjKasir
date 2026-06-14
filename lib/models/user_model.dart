class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AppUser.fromMap(
    Map<String, dynamic> map,
  ) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'cashier',
    );
  }

  bool get isAdmin => role == 'admin';

  bool get isCashier => role == 'cashier';
}