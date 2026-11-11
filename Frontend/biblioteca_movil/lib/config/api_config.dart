
class ApiConfig {
  // Dirección de la API BibliotecaAPI.
  //
  // - Desarrollo (flutter run): usa localhost.
  // - APK para instalar en el celular: se indica la URL del servidor
  //   al compilar, por ejemplo:
  //
  //   flutter build apk --release --dart-define=API_URL=https://biblioteca-api.onrender.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:5288/api',
  );

  // Tiempo máximo de espera de la API.
  // En el plan gratuito de Render el servidor se "duerme" tras
  // 15 minutos sin uso y tarda alrededor de un minuto en despertar.
  // Sin internet no afecta: el error llega de inmediato.
  static const Duration tiempoEspera = Duration(seconds: 70);
}
