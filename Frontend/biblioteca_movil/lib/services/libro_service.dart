import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/libro.dart';
import 'database_service.dart';
import 'package:flutter/foundation.dart';
import '../config/libros_demo.dart';
import '../config/portadas_demo.dart';

class LibroService {
  final String url = 'http://localhost:5288/api/libros';

  final DatabaseService _databaseService = DatabaseService();

  Future<List<Libro>> obtenerLibros() async {
    try {
      // 1. Intentamos consultar la API
      final respuesta = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (respuesta.statusCode == 200) {
        debugPrint('API conectada correctamente: 200 OK');


        final List<dynamic> datos = jsonDecode(respuesta.body);

        final libros = datos
            .map((json) => Libro.fromJson(json))
            .toList();

        // 2. Guardamos los libros en SQLite
        
        await _databaseService.guardarLibros(libros);

        // Guardar las rutas PDF de demostración en SQLite
        for (final libro in libros) {
          final rutaPdf = LibrosDemo.obtenerRutaPdf(libro.id);
          debugPrint(
            'Libro ID: ${libro.id} - Ruta encontrada: $rutaPdf',
          );

          if (rutaPdf != null) {
            await _databaseService.guardarRutaPdf(
              libro.id,
              rutaPdf,
            );

            debugPrint(
              'PDF procesado para libro ${libro.id}: $rutaPdf',
            );
          }
        }

        
        // Guardar las portadas de demostración en SQLite
        
        for (final libro in libros) {
          final rutaPortada =
              PortadasDemo.obtenerRutaPortada(libro.id);

          debugPrint(
            'Libro ID: ${libro.id} - Portada encontrada: $rutaPortada',
          );

          if (rutaPortada != null) {
            await _databaseService.guardarRutaPortada(
              libro.id,
              rutaPortada,
            );

            debugPrint(
              'Portada procesada para libro ${libro.id}: $rutaPortada',
            );
          }
        }



        // Recuperar los libros con sus rutas PDF y portadas desde SQLite
        return await _databaseService.obtenerLibros();

      } else {
        throw Exception('Error al consultar la API');
      }
    } catch (e) {
      // 3. Si falla la API, consultamos SQLite
      debugPrint('No se pudo consultar la API: $e');

      return await _databaseService.obtenerLibros();
    }
  }
}
