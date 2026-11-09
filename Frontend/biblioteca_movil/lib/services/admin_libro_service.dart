
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminLibroService {
  static const String baseUrl =
      'http://localhost:5288/api/libros';

  Future<void> registrarLibro({
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
      return;
    }

    throw Exception(
      'Error al registrar libro: '
      '${respuesta.statusCode} - ${respuesta.body}',
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
      'Error al actualizar libro: '
      '${respuesta.statusCode} - ${respuesta.body}',
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
      'Error al eliminar libro: '
      '${respuesta.statusCode} - ${respuesta.body}',
    );
  }
  
}
