
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:http_parser/http_parser.dart';

import '../models/tipo_archivo.dart';

class ArchivoService {
  static const String baseUrl =
      '${ApiConfig.baseUrl}/archivos';

  // Subir la portada, el PDF o el audio de un libro a Cloudinary.
  // Si el libro ya tenía ese archivo, el backend lo reemplaza.
  // Devuelve la URL de Cloudinary.
  Future<String> subirArchivo({
    required int libroId,
    required TipoArchivo tipo,
    required PlatformFile archivo,
    required String token,
  }) async {
    final solicitud = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/libros/$libroId/${tipo.ruta}'),
    );

    solicitud.headers['Authorization'] = 'Bearer $token';

    // El backend valida el tipo de archivo (ContentType),
    // por eso se envía explícitamente.
    final tipoMime = tipo.tipoMime(archivo.extension ?? '');

    final tamano = await archivo.length();

    if (tamano != null) {
      solicitud.files.add(
        http.MultipartFile(
          'archivo',
          archivo.readAsByteStream(),
          tamano,
          filename: archivo.name,
          contentType: MediaType.parse(tipoMime),
        ),
      );
    } else {
      solicitud.files.add(
        http.MultipartFile.fromBytes(
          'archivo',
          await archivo.readAsBytes(),
          filename: archivo.name,
          contentType: MediaType.parse(tipoMime),
        ),
      );
    }

    final respuestaStream = await solicitud.send().timeout(
      const Duration(minutes: 3),
    );

    final respuesta = await http.Response.fromStream(respuestaStream);

    if (respuesta.statusCode == 200) {
      final datos = jsonDecode(respuesta.body);

      // El backend responde rutaPortada, rutaPdf o rutaAudio
      final url = datos['rutaPortada'] ??
          datos['rutaPdf'] ??
          datos['rutaAudio'];

      return url as String;
    }

    throw Exception(
      'Error al subir ${tipo.nombre.toLowerCase()}: '
      '${_obtenerMensaje(respuesta)}',
    );
  }


  // Eliminar la portada, el PDF o el audio de un libro
  Future<void> eliminarArchivo({
    required int libroId,
    required TipoArchivo tipo,
    required String token,
  }) async {
    final respuesta = await http.delete(
      Uri.parse('$baseUrl/libros/$libroId/${tipo.ruta}'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (respuesta.statusCode == 204) {
      return;
    }

    throw Exception(
      'Error al eliminar ${tipo.nombre.toLowerCase()}: '
      '${_obtenerMensaje(respuesta)}',
    );
  }


  // Obtener el mensaje de error enviado por la API
  String _obtenerMensaje(http.Response respuesta) {
    if (respuesta.statusCode == 401 || respuesta.statusCode == 403) {
      return 'No tienes permisos de administrador o la sesión expiró.';
    }

    try {
      final datos = jsonDecode(respuesta.body);
      return datos['mensaje'] ?? '${respuesta.statusCode}';
    } catch (_) {
      return '${respuesta.statusCode}';
    }
  }
}
