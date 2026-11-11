import 'package:flutter/material.dart';
import 'services/connectivity_service.dart';
import 'services/sesion_service.dart';
import 'views/libros_view.dart';
import 'views/login_view.dart';

Future<void> main() async {
  // Necesario para leer el almacenamiento antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  final pantallaInicial = await decidirPantallaInicial();

  runApp(MyApp(pantallaInicial: pantallaInicial));
}


// Elegir la primera pantalla según la sesión guardada:
// - Sin sesión: login.
// - Cuenta creada sin internet: catálogo (se registra en el
//   servidor desde LibrosView cuando haya conexión).
// - Token vigente: catálogo.
// - Token vencido sin internet: catálogo en modo sin conexión.
// - Token vencido con internet: login para renovar la sesión.
Future<Widget> decidirPantallaInicial() async {
  final sesionService = SesionService();

  try {
    // Recuperar el modo sin conexión elegido la última vez
    ConnectivityService.modoSinConexion.value =
        await sesionService.obtenerModoSinConexion();

    final sesion = await sesionService.obtenerSesion();

    if (sesion == null) {
      return LoginView(
        emailInicial: await sesionService.obtenerUltimoEmail(),
      );
    }

    if (sesion.esCuentaLocal || !sesion.tokenVencido) {
      return LibrosView(
        usuario: sesion.usuario,
        token: sesion.token,
      );
    }

    // El token venció: ¿se puede renovar ahora?
    final hayInternet = !ConnectivityService.modoSinConexion.value &&
        await ConnectivityService().tieneConexion();

    if (hayInternet) {
      return LoginView(
        emailInicial: sesion.usuario.email,
        sesionVencida: true,
      );
    }

    // Sin internet: entrar solo a leer los libros guardados.
    // No se guarda este modo: es solo para esta apertura.
    ConnectivityService.modoSinConexion.value = true;

    return LibrosView(
      usuario: sesion.usuario,
      token: sesion.token,
    );
  } catch (e) {
    debugPrint('No se pudo recuperar la sesión: $e');
    return const LoginView();
  }
}


class MyApp extends StatelessWidget {
  final Widget pantallaInicial;

  const MyApp({
    super.key,
    required this.pantallaInicial,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Biblioteca Móvil',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: pantallaInicial,
    );
  }
}
