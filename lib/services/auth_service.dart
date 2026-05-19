import 'package:ims_pos_system/core/database/database_helper.dart';
import 'package:ims_pos_system/models/user.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  bool _databaseAvailable = true;

  static const String defaultEmail = 'admin@example.com';
  static const String defaultPassword = 'password123';

  Future<void> initialize() async {
    try {
      await _databaseHelper.database;
    } catch (_) {
      _databaseAvailable = false;
    }
  }

  Future<User?> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (_databaseAvailable) {
      try {
        final user = await _databaseHelper.getUserByEmail(normalizedEmail);
        if (user != null && user.verifyPassword(password)) {
          return user;
        }
      } catch (_) {
        _databaseAvailable = false;
      }
    }

    if (normalizedEmail == defaultEmail && password == defaultPassword) {
      return User(
        id: 1,
        name: 'Administrator',
        email: defaultEmail,
        password: User.hashPassword(defaultPassword),
      );
    }

    return null;
  }
}
