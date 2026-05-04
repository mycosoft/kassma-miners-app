import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final List<String> roles;
  final List<Map<String, dynamic>> managedPits;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.roles = const [],
    this.managedPits = const [],
  });

  bool get isPitOwner => roles.contains('pit-owner');
  bool get isSiteOwner => roles.contains('site-owner');
  bool get isPitManager => roles.contains('pit-manager');
  bool get isSiteManager => roles.contains('site-manager');
  bool get isAdmin => roles.contains('admin') || roles.contains('super-admin');

  String get primaryRole {
    if (isPitOwner) return 'pit-owner';
    if (isSiteOwner) return 'site-owner';
    if (isPitManager) return 'pit-manager';
    if (isSiteManager) return 'site-manager';
    if (isAdmin) return 'admin';
    if (roles.isNotEmpty) return roles.first;
    return 'unknown';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      managedPits: (json['managed_pits'] as List<dynamic>?)
              ?.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'roles': roles,
      'managed_pits': managedPits,
    };
  }

  @override
  List<Object?> get props => [id, name, email, roles];
}
