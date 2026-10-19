import 'package:bcrypt/bcrypt.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    UserCredential credential;
    try {
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_authError(e));
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
      await credential.user?.delete();
      return const AuthResult.fail('This email is already registered');
    } on FirebaseException catch (e) {
      await credential.user?.delete();
      return AuthResult.fail('Could not save your account: ${e.message}');
    } catch (e) {
      await credential.user?.delete();
      return AuthResult.fail('Could not save your account: $e');
    }
  }

  String _authError(FirebaseAuthException error) {
    if (error.code == 'configuration-not-found' ||
        error.message?.contains('CONFIGURATION_NOT_FOUND') == true) {
      return 'Firebase Authentication is not configured for this app. Enable Email/Password sign-in in the linked Firebase project and try again.';
    }

    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Enter a valid email address';
      case 'weak-password':
        return 'Choose a stronger password';
      case 'network-request-failed':
        return 'Check your internet connection and try again';
      default:
        return error.message ?? 'Could not authenticate. Please try again.';
    }
  }

  Future<Map<String, Object?>?> _ensureLocalUser(User user) async {
    final existing = await _findByEmail(user.email ?? '');
    if (existing != null) return existing;

    final db = await DatabaseHelper.instance.database;
    final email = _normalizeEmail(user.email ?? '');
    final displayName = user.displayName?.trim();
    final userId = await db.insert('users', {
      'name': displayName == null || displayName.isEmpty
          ? email.split('@').first
          : displayName,
      'email': email,
      'phone': '',
      'password_hash': '',
      'created_at': DateTime.now().toIso8601String(),
    });
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.first;
  }

  Future<Map<String, Object?>?> restoreSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return _ensureLocalUser(user);
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw StateError('Sign in again before changing your password.');
    }

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: currentPassword),
      );
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      throw StateError(_passwordChangeError(error));
    }

    final db = await DatabaseHelper.instance.database;
    await db.update(
      'users',
      {'password_hash': BCrypt.hashpw(newPassword, BCrypt.gensalt())},
      where: 'email = ?',
      whereArgs: [_normalizeEmail(email)],
    );
  }

  String _passwordChangeError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
        return 'Current password is incorrect.';
      case 'requires-recent-login':
        return 'Please sign in again before changing your password.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      default:
        return error.message ?? 'Could not change your password.';
    }
  }

  // ---------- login ----------
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final normalized = _normalizeEmail(email);
    User? firebaseUser;
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      firebaseUser = credential.user;
    } on FirebaseAuthException catch (error) {
      if (error.code != 'user-not-found' &&
          error.code != 'invalid-credential') {
        return AuthResult.fail(_authError(error));
      }

      final localUser = await _findByEmail(normalized);
      if (localUser == null) {
        return const AuthResult.fail('No account found with this email');
      }
      final savedHash = localUser['password_hash'] as String;
      if (savedHash.isEmpty || !BCrypt.checkpw(password, savedHash)) {
        return const AuthResult.fail('Incorrect password');
      }

      try {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: normalized,
              password: password,
            );
        firebaseUser = credential.user;
        await firebaseUser?.updateDisplayName(localUser['name'] as String);
      } on FirebaseAuthException catch (migrationError) {
        return AuthResult.fail(_authError(migrationError));
      }
    }

    if (firebaseUser == null) {
      return const AuthResult.fail('Could not sign in. Please try again.');
    }

    try {
      final user = await _ensureLocalUser(firebaseUser);
      if (user == null) {
        return const AuthResult.fail('Could not load your account');
      }
      return AuthResult.ok('Welcome back, ${user['name']}!', user: user);
    } on DatabaseException catch (e) {
      return AuthResult.fail('Could not load your account: $e');
    }
  }
}
