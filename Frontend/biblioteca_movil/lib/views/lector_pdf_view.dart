
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class LectorPdfView extends StatelessWidget {
  final String titulo;
  final String rutaPdf;

  const LectorPdfView({
    super.key,
    required this.titulo,
    required this.rutaPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
      ),
      body: _visorPdf(),
    );
  }

  // El PDF puede venir de:
  // - Cloudinary (URL)
  // - Los assets de la app (demo)
  // - Un archivo descargado en el celular (ruta absoluta)
  Widget _visorPdf() {
    if (rutaPdf.startsWith('http')) {
      return PdfViewer.uri(Uri.parse(rutaPdf));
    }

    if (rutaPdf.startsWith('assets/')) {
      return PdfViewer.asset(rutaPdf);
    }

    return PdfViewer.file(rutaPdf);
  }
}
