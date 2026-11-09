
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> tieneConexion() async {
    final resultados = await _connectivity.checkConnectivity();

    return resultados.any(
      (resultado) => resultado != ConnectivityResult.none,
    );
  }

  Stream<List<ConnectivityResult>> get cambiosConexion {
    return _connectivity.onConnectivityChanged;
  }
}
