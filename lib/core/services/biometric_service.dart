import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on Object catch (error) {
      debugPrint('Biometric availability check failed: $error');
      return false;
    }
  }

  Future<bool> authenticate({
    String reason = 'Buka DUITKU dengan biometrik',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } on Object catch (error) {
      debugPrint('Biometric authentication failed: $error');
      return false;
    }
  }
}
