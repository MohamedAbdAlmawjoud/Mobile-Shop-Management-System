import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Simple salted SHA-256 hashing for local desktop app credentials.
/// Not a substitute for bcrypt/argon2 in a networked/multi-tenant product,
/// but adequate for a single-machine shop app where the DB file itself
/// is the trust boundary.
class PasswordHasher {
  // Fixed app-level salt. Fine for this use case; rotate only by
  // re-hashing all stored passwords if it ever needs to change.
  static const String _salt = 'mobile_shop_v1';

  static String hash(String plainPassword) {
    final bytes = utf8.encode('$_salt:$plainPassword');
    return sha256.convert(bytes).toString();
  }

  static bool verify(String plainPassword, String storedHash) {
    return hash(plainPassword) == storedHash;
  }
}
