import 'dart:convert';

import 'package:crypto/crypto.dart';

class User {
  final int? id;
  final String name;
  final String email;
  final String password;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email, 'password': password};
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }

  static String hashPassword(String plainPassword) {
    final bytes = utf8.encode(plainPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool verifyPassword(String plainPassword) {
    return hashPassword(plainPassword) == password;
  }
}
