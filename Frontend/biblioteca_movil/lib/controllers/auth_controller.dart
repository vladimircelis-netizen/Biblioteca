import '../models/usuario.dart';
import '../services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

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

    return true;
  }

  bool get estaAutenticado =>
      usuarioActual != null && token != null;

  bool get esAdministrador =>
      usuarioActual?.esAdministrador ?? false;

  void cerrarSesion() {
    usuarioActual = null;
    token = null;
  }
}
