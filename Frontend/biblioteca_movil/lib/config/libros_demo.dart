
class LibrosDemo {
  static const Map<int, String> rutasPdf = {
    2: 'assets/libros/pdf/libro_prueba.pdf',
  };

  static String? obtenerRutaPdf(int libroId) {
    return rutasPdf[libroId];
  }
}
