
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/usuario.dart';

// Sesión guardada en el celular
class Sesion {
  final Usuario usuario;
  final String token;

  Sesion({
    required this.usuario,
    required this.token,
  });

  // Cuenta creada sin internet: todavía no existe en el servidor
  // y no tiene token
  bool get esCuentaLocal => token.isEmpty;

  // El token JWT trae su fecha de vencimiento (campo "exp")
  bool get tokenVencido {
    final vencimiento = SesionService.fechaVencimiento(token);

    if (vencimiento == null) return true;

    return DateTime.now().isAfter(vencimiento);
  }
}


// Guardar la sesión para no tener que iniciar sesión
// cada vez que se abre la app (y poder entrar sin internet).
// Se usa almacenamiento cifrado porque el token da acceso a la API.
class SesionService {
  static const FlutterSecureStorage _almacenamiento =
      FlutterSecureStorage();

  static const String _claveToken = 'token';
  static const String _claveUsuario = 'usuario';
  static const String _claveModoSinConexion = 'modo_sin_conexion';
  static const String _claveUltimoEmail = 'ultimo_email';
  static const String _claveCuentaPendiente = 'cuenta_pendiente';
  static const String _claveHuellaActiva = 'huella_activa';
  static const String _claveHuellaPreguntada = 'huella_preguntada';

  // Copia de la sesión que se usa para "Ingresar con huella"
  // en el login (se conserva aunque se cierre sesión)
  static const String _claveHuellaToken = 'huella_token';
  static const String _claveHuellaUsuario = 'huella_usuario';


  Future<void> guardarSesion(Usuario usuario, String token) async {
    await _almacenamiento.write(key: _claveToken, value: token);

    await _almacenamiento.write(
      key: _claveUsuario,
      value: jsonEncode(usuario.toJson()),
    );

    await _almacenamiento.write(
      key: _claveUltimoEmail,
      value: usuario.email,
    );

    // La huella pertenece a un usuario: si entra otra persona,
    // se olvida la huella anterior; si es el mismo, se renueva
    // la copia con el token nuevo.
    final huella = await _leerSesionHuella();

    if (huella != null) {
      if (huella.usuario.email != usuario.email) {
        await _olvidarHuella();
      } else if (token.isNotEmpty) {
        await _guardarCopiaHuella(usuario, token);
      }
    }
  }


  // Devuelve la sesión guardada o null si no hay
  Future<Sesion?> obtenerSesion() async {
    try {
      final token = await _almacenamiento.read(key: _claveToken);
      final usuarioJson =
          await _almacenamiento.read(key: _claveUsuario);

      if (token == null || usuarioJson == null) return null;

      return Sesion(
        usuario: Usuario.fromJson(jsonDecode(usuarioJson)),
        token: token,
      );
    } catch (e) {
      // Si los datos guardados están dañados, se descartan
      debugPrint('No se pudo leer la sesión guardada: $e');
      await cerrarSesion();
      return null;
    }
  }


  // Borrar la sesión (el último correo se conserva
  // para escribirlo automáticamente en el login).
  // Si la cuenta se creó sin internet y no se ha registrado
  // en el servidor, también se pierde.
  //
  // olvidarHuella = false: si la huella está activada, se podrá
  // volver a entrar con ella desde el login.
  Future<void> cerrarSesion({bool olvidarHuella = false}) async {
    await _almacenamiento.delete(key: _claveToken);
    await _almacenamiento.delete(key: _claveUsuario);
    await _almacenamiento.delete(key: _claveCuentaPendiente);

    if (olvidarHuella) {
      await _olvidarHuella();
    }
  }


  // INGRESO CON HUELLA

  Future<bool> obtenerHuellaActiva() async {
    return await _almacenamiento.read(key: _claveHuellaActiva) == 'true';
  }

  // Activar: guarda una copia cifrada de la sesión actual para
  // poder entrar con la huella desde el login.
  // Desactivar: borra esa copia.
  Future<void> guardarHuellaActiva(bool activa) async {
    if (activa) {
      final sesion = await obtenerSesion();

      if (sesion != null && !sesion.esCuentaLocal) {
        await _guardarCopiaHuella(sesion.usuario, sesion.token);
      }

      await _almacenamiento.write(key: _claveHuellaActiva, value: 'true');
    } else {
      await _almacenamiento.delete(key: _claveHuellaActiva);
      await _almacenamiento.delete(key: _claveHuellaToken);
      await _almacenamiento.delete(key: _claveHuellaUsuario);
    }

    // Ya decidió: no volver a ofrecerla
    await _almacenamiento.write(key: _claveHuellaPreguntada, value: 'true');
  }


  // Sesión con la que se puede entrar usando la huella desde el
  // login, o null si la huella no está activada
  Future<Sesion?> obtenerSesionHuella() async {
    if (!await obtenerHuellaActiva()) return null;

    return await _leerSesionHuella();
  }


  // Volver a abrir la sesión guardada para la huella
  Future<void> restaurarSesionHuella(Sesion sesion) async {
    await guardarSesion(sesion.usuario, sesion.token);
  }


  Future<Sesion?> _leerSesionHuella() async {
    try {
      final token = await _almacenamiento.read(key: _claveHuellaToken);
      final usuarioJson =
          await _almacenamiento.read(key: _claveHuellaUsuario);

      if (token == null || token.isEmpty || usuarioJson == null) {
        return null;
      }

      return Sesion(
        usuario: Usuario.fromJson(jsonDecode(usuarioJson)),
        token: token,
      );
    } catch (e) {
      debugPrint('No se pudo leer la sesión de la huella: $e');
      return null;
    }
  }

  Future<void> _guardarCopiaHuella(Usuario usuario, String token) async {
    await _almacenamiento.write(key: _claveHuellaToken, value: token);

    await _almacenamiento.write(
      key: _claveHuellaUsuario,
      value: jsonEncode(usuario.toJson()),
    );
  }

  // Borrar todo lo de la huella (otro usuario decidirá)
  Future<void> _olvidarHuella() async {
    await _almacenamiento.delete(key: _claveHuellaActiva);
    await _almacenamiento.delete(key: _claveHuellaPreguntada);
    await _almacenamiento.delete(key: _claveHuellaToken);
    await _almacenamiento.delete(key: _claveHuellaUsuario);
  }

  // ¿Ya se le ofreció activar la huella a este usuario?
  Future<bool> obtenerHuellaPreguntada() async {
    return await _almacenamiento.read(key: _claveHuellaPreguntada) ==
        'true';
  }

  Future<void> marcarHuellaPreguntada() async {
    await _almacenamiento.write(key: _claveHuellaPreguntada, value: 'true');
  }


  // CUENTA CREADA SIN CONEXIÓN
  // Se guardan los datos del registro (cifrados) para enviarlos
  // al servidor cuando haya internet. La contraseña se borra
  // en cuanto la cuenta queda registrada en el servidor.

  Future<void> guardarCuentaPendiente(Map<String, String> datos) async {
    await _almacenamiento.write(
      key: _claveCuentaPendiente,
      value: jsonEncode(datos),
    );
  }

  Future<Map<String, String>?> obtenerCuentaPendiente() async {
    try {
      final valor =
          await _almacenamiento.read(key: _claveCuentaPendiente);

      if (valor == null) return null;

      return Map<String, String>.from(jsonDecode(valor));
    } catch (e) {
      debugPrint('No se pudo leer la cuenta pendiente: $e');
      return null;
    }
  }

  Future<void> eliminarCuentaPendiente() async {
    await _almacenamiento.delete(key: _claveCuentaPendiente);
  }


  Future<String?> obtenerUltimoEmail() async {
    return await _almacenamiento.read(key: _claveUltimoEmail);
  }


  // Recordar el modo sin conexión entre aperturas de la app
  Future<void> guardarModoSinConexion(bool activo) async {
    await _almacenamiento.write(
      key: _claveModoSinConexion,
      value: activo.toString(),
    );
  }

  Future<bool> obtenerModoSinConexion() async {
    final valor =
        await _almacenamiento.read(key: _claveModoSinConexion);

    return valor == 'true';
  }


  // Leer la fecha de vencimiento del token JWT.
  // El JWT tiene 3 partes separadas por puntos;
  // la segunda es un JSON en Base64 con el campo "exp".
  static DateTime? fechaVencimiento(String token) {
    try {
      final partes = token.split('.');

      if (partes.length != 3) return null;

      final contenido = utf8.decode(
        base64Url.decode(base64Url.normalize(partes[1])),
      );

      final datos = jsonDecode(contenido);
      final exp = datos['exp'];

      if (exp is! int) return null;

      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (_) {
      return null;
    }
  }
}
