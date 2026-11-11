
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
  // para escribirlo automáticamente en el login)
  Future<void> cerrarSesion() async {
    await _almacenamiento.delete(key: _claveToken);
    await _almacenamiento.delete(key: _claveUsuario);
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
