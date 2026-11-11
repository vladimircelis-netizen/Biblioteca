
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AdminLibroService {
  static const String baseUrl =
      '${ApiConfig.baseUrl}/libros';

  // Registrar un libro y devolver el ID asignado por la API.
  // El ID se usa después para subir sus archivos digitales.
  Future<int> registrarLibro({
    required String titulo,
    required String isbn,
    required int anioPublicacion,
    required int stock,
    required int autorId,
    required String token,
  }) async {
    final respuesta = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'titulo': titulo,
        'isbn': isbn,
        'anioPublicacion': anioPublicacion,
        'stock': stock,
        'autorId': autorId,
      }),
    );

    if (respuesta.statusCode == 201 ||
        respuesta.statusCode == 200) {
      final datos = jsonDecode(respuesta.body);
      return datos['id'] as int;
    }

    throw Exception(
      'Error al registrar libro: ${_obtenerMensaje(respuesta)}',
    );
  }

  
  Future<void> actualizarLibro({
    required int id,
    required String titulo,
    required String isbn,
    required int anioPublicacion,
    required int stock,
    required int autorId,
    required String token,
  }) async {
    final respuesta = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'titulo': titulo,
        'isbn': isbn,
        'anioPublicacion': anioPublicacion,
        'stock': stock,
        'autorId': autorId,
      }),
    );

    if (respuesta.statusCode == 204) {
      return;
    }

    throw Exception(
      'Error al actualizar libro: ${_obtenerMensaje(respuesta)}',
    );
  }

  
  Future<void> eliminarLibro({
    required int id,
    required String token,
  }) async {
    final respuesta = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (respuesta.statusCode == 204) {
      return;
    }

    throw Exception(
      'Error al eliminar libro: ${_obtenerMensaje(respuesta)}',
    );
  }


  // Obtener un mensaje de error entendible.
  // 401/403: el token venció o el usuario no es administrador.
  // Otros: el mensaje que envía la API (ej. "El ISBN ya existe").
  String _obtenerMensaje(http.Response respuesta) {
    if (respuesta.statusCode == 401 || respuesta.statusCode == 403) {
      return 'No tienes permisos de administrador o la sesión expiró. '
          'Cierra sesión y vuelve a entrar.';
    }

    try {
      final datos = jsonDecode(respuesta.body);

      return datos['message'] ??
          datos['mensaje'] ??
          '${respuesta.statusCode}';
    } catch (_) {
      return '${respuesta.statusCode}';
    }
  }

}
