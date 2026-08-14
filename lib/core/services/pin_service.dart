import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Handles PIN hashing. The raw PIN never leaves this class.
class PinService {
  const PinService();

  static const int pinLength = 6;

  String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String hashPin(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt::$pin')).toString();

  bool verify({
    required String pin,
    required String salt,
    required String expectedHash,
  }) =>
      hashPin(pin, salt) == expectedHash;
}
