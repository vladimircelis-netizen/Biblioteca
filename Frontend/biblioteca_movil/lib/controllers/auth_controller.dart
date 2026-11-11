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


  // Crear una cuenta sin internet.
  // Queda guardada solo en el celular con rol Lector
  // (puede ver el catálogo y leer) hasta que haya conexión.
  Future<void> registrarseSinConexion({
    required String nombre,
    required String apellido,
    required String email,
    required String telefono,
    required String password,
  }) async {
    final emailNormalizado = email.trim().toLowerCase();

    // Datos para registrar la cuenta en el servidor más adelante
    await _sesionService.guardarCuentaPendiente({
      'nombre': nombre,
      'apellido': apellido,
      'email': emailNormalizado,
      'telefono': telefono,
      'password': password,
    });

    // Sesión local: sin token (id 0 hasta tener el del servidor)
    usuarioActual = Usuario(
      id: 0,
      nombre: nombre,
      apellido: apellido,
      email: emailNormalizado,
      rol: 'Lector',
    );
    token = '';

    await _sesionService.guardarSesion(usuarioActual!, '');
  }


  // Registrar en el servidor la cuenta creada sin internet
  // e iniciar sesión con ella.
  // - Devuelve false si no hay ninguna cuenta pendiente.
  // - Lanza SinConexionException si todavía no hay conexión.
  // - Lanza CorreoRegistradoException si el correo ya tiene
  //   otra cuenta en el servidor (la cuenta local se descarta).
  Future<bool> sincronizarCuentaPendiente() async {
    final datos = await _sesionService.obtenerCuentaPendiente();

    if (datos == null) return false;

    final email = datos['email']!;
    final password = datos['password']!;

    try {
      // 1. Crear la cuenta en el servidor
      await _authService.registrar(
        nombre: datos['nombre']!,
        apellido: datos['apellido']!,
        email: email,
        telefono: datos['telefono'] ?? '',
        password: password,
      );
    } on CorreoRegistradoException {
      // Puede que la cuenta ya se haya registrado en un intento
      // anterior (por ejemplo, se cortó la conexión justo después).
      // Si la contraseña coincide, es la misma persona.
      try {
        await iniciarSesion(email, password);
      } on SinConexionException {
        rethrow;
      } catch (_) {
        await cerrarSesion();

        throw CorreoRegistradoException(
          'Ya existe una cuenta con el correo $email. '
          'Inicia sesión con tu contraseña.',
        );
      }

      await _sesionService.eliminarCuentaPendiente();
      return true;
    }

    // 2. Iniciar sesión: guarda la sesión con el token real
    await iniciarSesion(email, password);

    // 3. Borrar los datos pendientes (incluida la contraseña)
    await _sesionService.eliminarCuentaPendiente();

    return true;
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
