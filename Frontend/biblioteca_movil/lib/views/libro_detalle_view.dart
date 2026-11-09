
import 'package:flutter/material.dart';

import '../models/libro.dart';
import '../config/app_colors.dart';
import '../config/audios_demo.dart';

import 'lector_pdf_view.dart';
import 'reproductor_audio_view.dart';

class LibroDetalleView extends StatelessWidget {
  final Libro libro;

  const LibroDetalleView({
    super.key,
    required this.libro,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,

      // Barra superior
      appBar: AppBar(
        title: const Text('Detalle del libro'),
        backgroundColor: AppColors.primario,
        foregroundColor: AppColors.tarjeta,
      ),

      // Contenido de la pantalla
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: AppColors.tarjeta,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,

                children: [
                  // Portada del libro
                  if (libro.rutaPortada != null) ...[
                    Center(
                      child: Image.asset(
                        libro.rutaPortada!,
                        width: 160,
                        height: 240,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image,
                            size: 80,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Título del libro
                  Text(
                    libro.titulo,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Información del libro
                  Text('Autor: ${libro.nombreAutor}'),
                  const SizedBox(height: 8),

                  Text('ISBN: ${libro.isbn}'),
                  const SizedBox(height: 8),

                  Text('Año: ${libro.anioPublicacion}'),
                  const SizedBox(height: 8),

                  Text('Stock: ${libro.stock}'),

                  const SizedBox(height: 25),

                  // Botón para leer el PDF
                  if (libro.rutaPdf != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.picture_as_pdf,
                        ),
                        label: const Text('Leer PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primario,
                          foregroundColor: AppColors.tarjeta,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                        onPressed: () {
                          final rutaPdf = libro.rutaPdf;

                          if (rutaPdf == null) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LectorPdfView(
                                titulo: libro.titulo,
                                rutaPdf: rutaPdf,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Espacio entre los botones
                  const SizedBox(height: 12),

                  // Botón para escuchar el audiolibro
                  if (AudiosDemo.obtenerRutaAudio(libro.id) != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.headphones,
                        ),
                        label: const Text('Escuchar audiolibro'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primario,
                          foregroundColor: AppColors.tarjeta,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                        onPressed: () {
                          final rutaAudio =
                              AudiosDemo.obtenerRutaAudio(libro.id);

                          if (rutaAudio == null) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReproductorAudioView(
                                titulo: libro.titulo,
                                rutaAudio: rutaAudio,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
