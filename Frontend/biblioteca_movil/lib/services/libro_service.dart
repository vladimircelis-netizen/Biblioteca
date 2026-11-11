import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/libro.dart';
import 'database_service.dart';
import 'package:flutter/foundation.dart';
import '../config/libros_demo.dart';
import '../config/portadas_demo.dart';
import '../config/audios_demo.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'connectivity_service.dart';

class LibroService {
  final String url = 'http://localhost:5288/api/libros';

  final DatabaseService _databaseService = DatabaseService();

  Future<List<Libro>> obtenerLibros() async {
    // Modo sin conexión activado por el usuario:
    // no se consulta la API, solo SQLite.
    if (ConnectivityService.modoSinConexion.value) {
      debugPrint('Modo sin conexión: libros cargados desde SQLite');

      return await _databaseService.obtenerLibros();
    }

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

        // Descargar las portadas en segundo plano
        // para poder verlas sin conexión
        _guardarPortadasEnCache(libros);

        // 3. Archivos de demostración (assets).
        // Solo se usan si el libro todavía no tiene
        // un archivo subido a Cloudinary.
        for (final libro in libros) {
          final rutaPdf = LibrosDemo.obtenerRutaPdf(libro.id);

          if (!libro.tienePdf && rutaPdf != null) {
            await _databaseService.guardarRutaPdf(
              libro.id,
              rutaPdf,
            );

            debugPrint(
              'PDF demo procesado para libro ${libro.id}: $rutaPdf',
            );
          }

          final rutaPortada =
              PortadasDemo.obtenerRutaPortada(libro.id);

          if (!libro.tienePortada && rutaPortada != null) {
            await _databaseService.guardarRutaPortada(
              libro.id,
              rutaPortada,
            );

            debugPrint(
              'Portada demo procesada para libro ${libro.id}: $rutaPortada',
            );
          }

          final rutaAudio = AudiosDemo.obtenerRutaAudio(libro.id);

          if (!libro.tieneAudio && rutaAudio != null) {
            await _databaseService.guardarRutaAudio(
              libro.id,
              rutaAudio,
            );

            debugPrint(
              'Audio demo procesado para libro ${libro.id}: $rutaAudio',
            );
          }
        }



        // Recuperar los libros con sus rutas desde SQLite
        return await _databaseService.obtenerLibros();

      } else {
        throw Exception('Error al consultar la API');
      }
    } catch (e) {
      // 4. Si falla la API, consultamos SQLite
      debugPrint('No se pudo consultar la API: $e');

      return await _databaseService.obtenerLibros();
    }
  }


  // Guardar en el celular las portadas de Cloudinary.
  // getSingleFile solo descarga las que todavía no están guardadas.
  // Es la misma caché que usa PortadaLibroWidget (CachedNetworkImage).
  Future<void> _guardarPortadasEnCache(List<Libro> libros) async {
    for (final libro in libros) {
      final rutaPortada = libro.rutaPortada;

      if (rutaPortada == null || !rutaPortada.startsWith('http')) {
        continue;
      }

      try {
        await DefaultCacheManager().getSingleFile(rutaPortada);
      } catch (e) {
        debugPrint('No se pudo guardar la portada ${libro.id}: $e');
      }
    }
  }


  // Consultar los libros directamente en la API (sin demos ni SQLite).
  // Se usa en la administración de archivos digitales, donde
  // se necesita saber qué archivos existen realmente en Cloudinary.
  Future<List<Libro>> obtenerLibrosServidor() async {
    final respuesta = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode == 200) {
      final List<dynamic> datos = jsonDecode(respuesta.body);

      return datos
          .map((json) => Libro.fromJson(json))
          .toList();
    }

    throw Exception(
      'Error al consultar los libros: ${respuesta.statusCode}',
    );
  }
}
