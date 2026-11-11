
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

// Muestra la portada de un libro.
// - Si la ruta es una URL (Cloudinary) usa CachedNetworkImage:
//   la imagen se guarda en el celular y se sigue viendo sin internet.
// - Si es una ruta de assets (demo) usa Image.asset.
// - Si no hay portada muestra un ícono.
class PortadaLibroWidget extends StatelessWidget {
  final String? rutaPortada;
  final double ancho;
  final double alto;

  const PortadaLibroWidget({
    super.key,
    required this.rutaPortada,
    this.ancho = 50,
    this.alto = 75,
  });

  @override
  Widget build(BuildContext context) {
    final ruta = rutaPortada;

    if (ruta == null || ruta.isEmpty) {
      return _iconoSinPortada(Icons.menu_book);
    }

    final esUrl = ruta.startsWith('http');

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: esUrl
          ? CachedNetworkImage(
              imageUrl: ruta,
              width: ancho,
              height: alto,
              fit: BoxFit.cover,
              placeholder: (context, url) {
                return SizedBox(
                  width: ancho,
                  height: alto,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorWidget: (context, url, error) {
                return _iconoSinPortada(Icons.broken_image);
              },
            )
          : Image.asset(
              ruta,
              width: ancho,
              height: alto,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _iconoSinPortada(Icons.broken_image);
              },
            ),
    );
  }

  Widget _iconoSinPortada(IconData icono) {
    return SizedBox(
      width: ancho,
      height: alto,
      child: Icon(
        icono,
        color: AppColors.primario,
        size: ancho * 0.7,
      ),
    );
  }
}
