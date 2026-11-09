
class AudiosDemo {
  static const Map<int, String> rutasAudio = {
    2: 'assets/libros/mp3/audio_prueba.mp3',
  };

  static String? obtenerRutaAudio(int libroId) {
    return rutasAudio[libroId];
  }
}
