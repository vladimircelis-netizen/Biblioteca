import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/usuario.dart';

// No se pudo contactar con la API (sin internet o servidor apagado)
class SinConexionException implements Exception {
  final String mensaje;

  SinConexionException([
    this.mensaje = 'No hay conexión con el servidor',
  ]);

  @override
  String toString() => mensaje;
}

// El correo ya tiene una cuenta en el servidor
class CorreoRegistradoException implements Exception {
  final String mensaje;

  CorreoRegistradoException(this.mensaje);

  @override
  String toString() => mensaje;
}


class AuthService {
  // Dirección de nuestra API Biblioteca
  static const String baseUrl =
      'http://localhost:5288/api/usuarios';

  // Enviar un POST con tiempo límite.
  // Si no hay conexión lanza SinConexionException.
  Future<http.Response> _post(String ruta, Map<String, dynamic> datos) async {
    try {
      return await http
          .post(
            Uri.parse('$baseUrl/$ruta'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(datos),
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw SinConexionException();
    } on TimeoutException {
      throw SinConexionException();
    } on http.ClientException {
      throw SinConexionException();
    }
  }

  Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final respuesta = await _post('login', {
      'email': email,
      'password': password,
    });

    final datos = jsonDecode(respuesta.body);

    if (respuesta.statusCode == 200) {
      final usuario = Usuario.fromJson(datos['usuario']);
      final String token = datos['token'];

      return {
        'usuario': usuario,
        'token': token,
      };
    }

    if (respuesta.statusCode == 401) {
      throw Exception(
        datos['mensaje'] ?? 'Correo o contraseña incorrectos',
      );
    }

    throw Exception(
      'Error al iniciar sesión: ${respuesta.statusCode}',
    );
  }


  // Registrar un usuario con correo y contraseña.
  // La API lo crea con el rol Lector.
  Future<void> registrar({
    required String nombre,
    required String apellido,
    required String email,
    required String telefono,
    required String password,
  }) async {
    final respuesta = await _post('registro', {
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'password': password,
    });

    if (respuesta.statusCode == 201) {
      return;
    }

    // 409: el correo ya está registrado
    if (respuesta.statusCode == 409) {
      final datos = jsonDecode(respuesta.body);

      throw CorreoRegistradoException(
        datos['mensaje'] ?? 'El correo electrónico ya está registrado',
      );
    }

    // 400: datos inválidos (validaciones del DTO)
    if (respuesta.statusCode == 400) {
      throw Exception(
        'Revisa los datos ingresados',
      );
    }

    throw Exception(
      'Error al registrar usuario: ${respuesta.statusCode}',
    );
  }


  // Enviar el ID token de Google a la API.
  // La API lo verifica, registra al usuario si es nuevo
  // y devuelve el token JWT, igual que el login.
  Future<Map<String, dynamic>> loginConGoogle(String idToken) async {
    final respuesta = await _post('google', {
      'idToken': idToken,
    });

    final datos = jsonDecode(respuesta.body);

    if (respuesta.statusCode == 200) {
      final usuario = Usuario.fromJson(datos['usuario']);
      final String token = datos['token'];

      return {
        'usuario': usuario,
        'token': token,
      };
    }

    throw Exception(
      datos['mensaje'] ??
          'Error al iniciar sesión con Google: ${respuesta.statusCode}',
    );
  }
}
