
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'sesion_service.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  // Modo sin conexión elegido por el usuario (ícono de wifi).
  // Android no permite que una app encienda o apague el wifi,
  // así que este modo solo afecta a la aplicación:
  // mientras está activo no se consulta la API y se usa SQLite.
  static final ValueNotifier<bool> modoSinConexion =
      ValueNotifier<bool>(false);

  Future<bool> tieneConexion() async {
    final resultados = await _connectivity.checkConnectivity();

    return resultados.any(
      (resultado) => resultado != ConnectivityResult.none,
    );
  }

  Stream<List<ConnectivityResult>> get cambiosConexion {
    return _connectivity.onConnectivityChanged;
  }

  // Activar o desactivar el modo sin conexión
  // (queda guardado para la próxima vez que se abra la app)
  static void cambiarModoSinConexion() {
    establecerModoSinConexion(!modoSinConexion.value);
  }

  static void establecerModoSinConexion(bool activo) {
    modoSinConexion.value = activo;
    SesionService().guardarModoSinConexion(activo);
  }
}
