class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.profilePicture,
  });

  final int id;
  final String email;
  final String name;
  final String phone;
  final String role;
  final String? profilePicture;

  bool get isCitizen => role == 'CITIZEN';
  bool get isWorker => role == 'WORKER';
  bool get isAuthority => role == 'AUTHORITY';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num).toInt(),
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? json['email']?.toString() ?? 'User',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString().toUpperCase() ?? 'CITIZEN',
      profilePicture: json['profile_picture']?.toString(),
    );
  }
}
