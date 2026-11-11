import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/sesion_service.dart';

class AuthController {
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final SesionService _sesionService = SesionService();

  Usuario? usuarioActual;
  String? token;

  Future<bool> iniciarSesion(
    String email,
    String password,
  ) async {
    final resultado = await _authService.login(
      email,
      password,
    );

    usuarioActual = resultado['usuario'] as Usuario;
    token = resultado['token'] as String;

    // Guardar la sesión en el celular
    await _sesionService.guardarSesion(usuarioActual!, token!);

    return true;
  }


  // Registrar un usuario y entrar automáticamente
  Future<bool> registrarse({
    required String nombre,
    required String apellido,
    required String email,
    required String telefono,
    required String password,
  }) async {
    // 1. Crear la cuenta
    await _authService.registrar(
      nombre: nombre,
      apellido: apellido,
      email: email,
      telefono: telefono,
      password: password,
    );

    // 2. Iniciar sesión con la cuenta nueva
    return await iniciarSesion(email, password);
  }


  // Registrarse o iniciar sesión con Google.
  // Devuelve false si el usuario cancela.
  Future<bool> iniciarSesionConGoogle() async {
    // 1. Elegir la cuenta de Google en el dispositivo
    final idToken = await _googleAuthService.obtenerIdToken();

    if (idToken == null) return false;

    // 2. Enviar el token a la API
    final resultado = await _authService.loginConGoogle(idToken);

    usuarioActual = resultado['usuario'] as Usuario;
    token = resultado['token'] as String;

    // Guardar la sesión en el celular
    await _sesionService.guardarSesion(usuarioActual!, token!);

    return true;
  }

  bool get estaAutenticado =>
      usuarioActual != null && token != null;

  bool get esAdministrador =>
      usuarioActual?.esAdministrador ?? false;

  Future<void> cerrarSesion() async {
    usuarioActual = null;
    token = null;

    // Borrar la sesión guardada y cerrar la de Google
    await _sesionService.cerrarSesion();
    await _googleAuthService.cerrarSesion();
  }
}
