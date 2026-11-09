
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
}
