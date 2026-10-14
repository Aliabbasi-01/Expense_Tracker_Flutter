import 'package:bcrypt/bcrypt.dart';
import 'package:sqflite/sqflite.dart';

import 'package:expense_tracker/database/database_helper.dart';

class AuthResult {
  final bool success;
  final String message;
  final Map<String, Object?>? user;

  const AuthResult.ok(this.message, {this.user}) : success = true;
  const AuthResult.fail(this.message) : success = false, user = null;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ---------- helpers ----------
  String _normalizeEmail(String email) => email.trim().toLowerCase();

  Future<Map<String, Object?>?> _findByEmail(String email) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [_normalizeEmail(email)],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  // ---------- register ----------
  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final normalized = _normalizeEmail(email);

    if (await _findByEmail(normalized) != null) {
      return const AuthResult.fail('This email is already registered');
    }

    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('users', {
        'name': name.trim(),
        'email': normalized,
        'phone': phone.trim(),
        // bcrypt salt khud hash ke andar store kar leta hai
        'password_hash': BCrypt.hashpw(password, BCrypt.gensalt()),
        'created_at': DateTime.now().toIso8601String(),
      });
      return const AuthResult.ok('Account created! Please sign in.');
    } on DatabaseException {
      return const AuthResult.fail('This email is already registered');
    } catch (_) {
      return const AuthResult.fail('Something went wrong. Please try again.');
    }
  }

  // ---------- login ----------
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final user = await _findByEmail(email);

    if (user == null) {
      return const AuthResult.fail('No account found with this email');
    }

    final savedHash = user['password_hash'] as String;

    if (!BCrypt.checkpw(password, savedHash)) {
      return const AuthResult.fail('Incorrect password');
    }

    return AuthResult.ok('Welcome back, ${user['name']}!', user: user);
  }
}
