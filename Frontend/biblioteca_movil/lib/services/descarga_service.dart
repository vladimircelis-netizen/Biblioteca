
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../models/tipo_archivo.dart';
import 'database_service.dart';

// Archivo descargado en el celular
class Descarga {
  final String rutaLocal;

  // true: en el servidor hay una versión nueva del archivo
  final bool desactualizada;

  Descarga({
    required this.rutaLocal,
    required this.desactualizada,
  });
}


// Descargar el PDF y el audio de un libro para usarlos sin conexión.
// Los archivos se guardan en la carpeta interna de la app
// y sus rutas en la tabla "descargas" de SQLite.
class DescargaService {
  final DatabaseService _databaseService = DatabaseService();

  // Carpeta donde se guardan los archivos descargados
  Future<Directory> _carpetaDescargas() async {
    final documentos = await getApplicationDocumentsDirectory();

    final carpeta = Directory(join(documentos.path, 'descargas'));

    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }

    return carpeta;
  }


  // Consultar si el archivo está descargado.
  // urlActual: la URL que tiene el libro ahora en el servidor.
  Future<Descarga?> obtenerDescarga({
    required int libroId,
    required TipoArchivo tipo,
    required String? urlActual,
  }) async {
    final datos =
        await _databaseService.obtenerDescarga(libroId, tipo.ruta);

    if (datos == null) return null;

    final rutaLocal = datos['rutaLocal'] as String;
    final urlOrigen = datos['urlOrigen'] as String;

    // Si el archivo fue borrado del celular, quitar el registro
    if (!await File(rutaLocal).exists()) {
      await _databaseService.eliminarDescarga(libroId, tipo.ruta);
      return null;
    }

    // Si el administrador eliminó el archivo en el servidor,
    // también se elimina la descarga
    if (urlActual == null || urlActual.isEmpty) {
      await eliminarDescarga(libroId: libroId, tipo: tipo);
      return null;
    }

    return Descarga(
      rutaLocal: rutaLocal,
      desactualizada: urlOrigen != urlActual,
    );
  }


  // Descargar el archivo mostrando el progreso (0.0 a 1.0).
  // Devuelve la ruta local del archivo.
  Future<String> descargarArchivo({
    required int libroId,
    required TipoArchivo tipo,
    required String url,
    required void Function(double progreso) onProgreso,
  }) async {
    final carpeta = await _carpetaDescargas();

    final extension = tipo == TipoArchivo.pdf ? 'pdf' : 'mp3';

    final rutaFinal = join(
      carpeta.path,
      'libro_${libroId}_${tipo.ruta}.$extension',
    );

    // Se descarga primero a un archivo temporal para no dañar
    // la descarga anterior si se corta la conexión
    final archivoTemporal = File('$rutaFinal.tmp');

    final cliente = http.Client();

    try {
      final respuesta = await cliente
          .send(http.Request('GET', Uri.parse(url)))
          .timeout(const Duration(seconds: 30));

      if (respuesta.statusCode != 200) {
        throw Exception(
          'No se pudo descargar el archivo (${respuesta.statusCode})',
        );
      }

      final total = respuesta.contentLength ?? 0;
      var recibidos = 0;

      final escritura = archivoTemporal.openWrite();

      try {
        await for (final bloque in respuesta.stream) {
          escritura.add(bloque);
          recibidos += bloque.length;

          if (total > 0) {
            onProgreso(recibidos / total);
          }
        }
      } finally {
        await escritura.close();
      }

      // Reemplazar la descarga anterior (si existía)
      await archivoTemporal.rename(rutaFinal);

      await _databaseService.guardarDescarga(
        libroId: libroId,
        tipo: tipo.ruta,
        rutaLocal: rutaFinal,
        urlOrigen: url,
      );

      return rutaFinal;
    } on SocketException {
      throw Exception('Sin conexión a internet');
    } catch (e) {
      // Borrar el archivo incompleto
      if (await archivoTemporal.exists()) {
        await archivoTemporal.delete();
      }

      debugPrint('Error al descargar $url: $e');
      rethrow;
    } finally {
      cliente.close();
    }
  }


  // Borrar el archivo del celular y su registro en SQLite
  Future<void> eliminarDescarga({
    required int libroId,
    required TipoArchivo tipo,
  }) async {
    final datos =
        await _databaseService.obtenerDescarga(libroId, tipo.ruta);

    if (datos != null) {
      final archivo = File(datos['rutaLocal'] as String);

      if (await archivo.exists()) {
        await archivo.delete();
      }
    }

    await _databaseService.eliminarDescarga(libroId, tipo.ruta);
  }
}
