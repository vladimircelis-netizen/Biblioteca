
class PortadasDemo {
  static const Map<int, String> rutasPortadas = {
    2: 'assets/portadas/amor_colera.jpg',
  };

  static String? obtenerRutaPortada(int libroId) {
    return rutasPortadas[libroId];
  }
}
