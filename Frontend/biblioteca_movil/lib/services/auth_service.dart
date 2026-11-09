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
}
