
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

// Ingreso con huella (o el método biométrico del celular).
// Funciona como cerradura de la app: la sesión ya está guardada
// en el celular y la huella solo confirma que es su dueño.
// No se guarda ninguna contraseña para esto.
class HuellaService {
  final LocalAuthentication _autenticacion = LocalAuthentication();

  // ¿El celular tiene lector y al menos una huella registrada?
  Future<bool> estaDisponible() async {
    try {
      if (!await _autenticacion.canCheckBiometrics) return false;

      final biometricos =
          await _autenticacion.getAvailableBiometrics();

      return biometricos.isNotEmpty;
    } catch (e) {
      debugPrint('No se pudo consultar la huella: $e');
      return false;
    }
  }


  // Pedir la huella.
  // - true: la huella es correcta.
  // - false: el usuario canceló.
  // - Exception: un problema que hay que mostrar (bloqueo, sin huellas…).
  //
  // soloHuella = false permite usar el PIN o patrón del celular
  // si el lector falla (se usa al abrir la app).
  Future<bool> autenticar(
    String motivo, {
    bool soloHuella = false,
  }) async {
    try {
      return await _autenticacion.authenticate(
        localizedReason: motivo,
        biometricOnly: soloHuella,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.timeout:
        case LocalAuthExceptionCode.userRequestedFallback:
          return false;

        case LocalAuthExceptionCode.noBiometricsEnrolled:
          throw Exception(
            'No hay huellas registradas en el celular. '
            'Agrégalas en los Ajustes de Android.',
          );

        case LocalAuthExceptionCode.noBiometricHardware:
          throw Exception('Este celular no tiene lector de huella.');

        case LocalAuthExceptionCode.temporaryLockout:
          throw Exception(
            'Demasiados intentos. Espera unos segundos e inténtalo de nuevo.',
          );

        case LocalAuthExceptionCode.biometricLockout:
          throw Exception(
            'La huella está bloqueada. Desbloquea el celular con tu PIN '
            'y vuelve a intentarlo.',
          );

        default:
          throw Exception(
            'No se pudo usar la huella: ${e.description ?? e.code.name}',
          );
      }
    }
  }
}
