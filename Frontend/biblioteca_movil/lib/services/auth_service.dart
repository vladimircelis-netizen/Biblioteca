import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/usuario.dart';

class AuthService {
  // Dirección de nuestra API Biblioteca
  static const String baseUrl =
      'http://localhost:5288/api/usuarios';

  Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/login');

    final respuesta = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

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
    final respuesta = await http.post(
      Uri.parse('$baseUrl/registro'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'telefono': telefono,
        'password': password,
      }),
    );

    if (respuesta.statusCode == 201) {
      return;
    }

    // 409: el correo ya está registrado
    if (respuesta.statusCode == 409) {
      final datos = jsonDecode(respuesta.body);

      throw Exception(
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
    final respuesta = await http.post(
      Uri.parse('$baseUrl/google'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'idToken': idToken,
      }),
    );

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
