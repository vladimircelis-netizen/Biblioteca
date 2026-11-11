import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/libro.dart';
import 'database_service.dart';
import 'package:flutter/foundation.dart';
import '../config/catalogo_inicial.dart';
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

      return await _obtenerLibrosLocales();
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

        // 3. Archivos incluidos en la app (assets).
        // Se buscan por ISBN y solo se usan si el libro
        // todavía no tiene ese archivo en Cloudinary.
        for (final libro in libros) {
          final incluido = CatalogoInicial.buscarPorIsbn(libro.isbn);

          if (incluido == null) continue;

          if (!libro.tienePdf && incluido.tienePdf) {
            await _databaseService.guardarRutaPdf(
              libro.id,
              incluido.rutaPdf!,
            );
          }

          if (!libro.tienePortada && incluido.tienePortada) {
            await _databaseService.guardarRutaPortada(
              libro.id,
              incluido.rutaPortada!,
            );
          }

          if (!libro.tieneAudio && incluido.tieneAudio) {
            await _databaseService.guardarRutaAudio(
              libro.id,
              incluido.rutaAudio!,
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

      return await _obtenerLibrosLocales();
    }
  }


  // Libros guardados en SQLite.
  // Si la app nunca se ha sincronizado (primera vez sin internet),
  // se cargan los libros incluidos en la app.
  Future<List<Libro>> _obtenerLibrosLocales() async {
    final libros = await _databaseService.obtenerLibros();

    if (libros.isNotEmpty) return libros;

    debugPrint('Primera vez sin conexión: catálogo incluido en la app');

    await _databaseService.guardarLibros(CatalogoInicial.libros);

    return await _databaseService.obtenerLibros();
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
