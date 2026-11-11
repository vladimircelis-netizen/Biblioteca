
class GoogleConfig {
  // ID de cliente de tipo "Aplicación web" creado en
  // Google Cloud Console > APIs y servicios > Credenciales.
  //
  // Debe ser el MISMO valor configurado en el backend
  // (Google:ClientId), porque la API verifica que el token
  // de Google fue emitido para este cliente.
  //
  // Ejemplo: '1234567890-abc123.apps.googleusercontent.com'
  static const String webClientId = '';
}
