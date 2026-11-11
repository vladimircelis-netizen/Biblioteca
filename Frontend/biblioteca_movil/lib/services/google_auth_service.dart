
import 'package:google_sign_in/google_sign_in.dart';
import '../config/google_config.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // initialize() solo se puede llamar una vez en toda la app
  static bool _inicializado = false;

  Future<void> _inicializar() async {
    if (_inicializado) return;

    if (GoogleConfig.webClientId.isEmpty) {
      throw Exception(
        'Falta configurar el ID de cliente de Google '
        '(lib/config/google_config.dart)',
      );
    }

    await _googleSignIn.initialize(
      serverClientId: GoogleConfig.webClientId,
    );

    _inicializado = true;
  }

  // Abrir la ventana de Google y obtener el ID token.
  // Devuelve null si el usuario cancela.
  Future<String?> obtenerIdToken() async {
    await _inicializar();

    try {
      final cuenta = await _googleSignIn.authenticate();

      final idToken = cuenta.authentication.idToken;

      if (idToken == null) {
        throw Exception('Google no devolvió el token de identidad');
      }

      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }

      throw Exception(
        'No se pudo iniciar sesión con Google: '
        '${e.description ?? e.code.name}',
      );
    }
  }

  // Cerrar la sesión de Google para que la próxima vez
  // se pueda elegir otra cuenta
  Future<void> cerrarSesion() async {
    if (!_inicializado) return;

    await _googleSignIn.signOut();
  }
}
