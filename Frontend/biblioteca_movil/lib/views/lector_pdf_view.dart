
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
      body: PdfViewer.asset(rutaPdf),
    );
  }
}
