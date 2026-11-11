
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/autor.dart';

class AutorService {
  static const String baseUrl =
      'http://localhost:5288/api/autores';

  Future<List<Autor>> listarAutores() async {
    final respuesta = await http.get(
      Uri.parse(baseUrl),
    );

    if (respuesta.statusCode == 200) {
      final List<dynamic> datos =
          jsonDecode(respuesta.body);

      return datos
          .map((json) => Autor.fromJson(json))
          .toList();
    }

    throw Exception(
      'Error al consultar autores: ${respuesta.statusCode}',
    );
  }


  // Registrar un autor y devolverlo con el ID asignado por la API
  Future<Autor> crearAutor({
    required String nombre,
    required String apellido,
    required String nacionalidad,
    required String token,
  }) async {
    final respuesta = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'nacionalidad': nacionalidad,
      }),
    );

    if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
      return Autor.fromJson(jsonDecode(respuesta.body));
    }

    // 401/403: el token venció o el usuario no es administrador
    if (respuesta.statusCode == 401 || respuesta.statusCode == 403) {
      throw Exception(
        'No tienes permisos de administrador o la sesión expiró. '
        'Cierra sesión y vuelve a entrar.',
      );
    }

    // 400: datos inválidos (validaciones de CrearAutorDto)
    if (respuesta.statusCode == 400) {
      throw Exception('Revisa los datos del autor');
    }

    throw Exception(
      'Error al registrar autor: ${respuesta.statusCode}',
    );
  }
}
