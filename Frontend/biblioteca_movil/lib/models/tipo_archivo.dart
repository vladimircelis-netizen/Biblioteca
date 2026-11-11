
import 'package:flutter/material.dart';

// Tipos de archivos digitales que puede tener un libro.
// Los límites coinciden con las validaciones del backend
// (CloudinaryService.cs).
enum TipoArchivo {
  portada(
    ruta: 'portada',
    nombre: 'Portada',
    icono: Icons.image,
    extensiones: ['jpg', 'jpeg', 'png', 'webp'],
    tamanoMaximoMb: 5,
  ),
  pdf(
    ruta: 'pdf',
    nombre: 'PDF del libro',
    icono: Icons.picture_as_pdf,
    extensiones: ['pdf'],
    tamanoMaximoMb: 10,
  ),
  audio(
    ruta: 'audio',
    nombre: 'Audiolibro (MP3)',
    icono: Icons.headphones,
    extensiones: ['mp3'],
    tamanoMaximoMb: 20,
  );

  // Segmento de la URL de la API: api/archivos/libros/{id}/{ruta}
  final String ruta;
  final String nombre;
  final IconData icono;
  final List<String> extensiones;
  final int tamanoMaximoMb;

  const TipoArchivo({
    required this.ruta,
    required this.nombre,
    required this.icono,
    required this.extensiones,
    required this.tamanoMaximoMb,
  });

  int get tamanoMaximoBytes => tamanoMaximoMb * 1024 * 1024;

  // Tipo MIME que valida el backend (ContentType)
  String tipoMime(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
