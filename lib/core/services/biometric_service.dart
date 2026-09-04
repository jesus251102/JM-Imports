import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      if (!canAuthenticate) return false;

      final List<BiometricType> availableBiometrics = await _auth
          .getAvailableBiometrics();
      return availableBiometrics.isNotEmpty || canAuthenticateWithBiometrics;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticate({
    String localizedReason = 'Escanea tu huella digital',
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Fallback to PIN/Pattern if fingerprint fails
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
