
import '../models/libro.dart';
import '../services/libro_service.dart';

class LibroController {
  final LibroService _service = LibroService();

  Future<List<Libro>> listarLibros() async {
    return await _service.obtenerLibros();
  }

  // Libros tal como están en el servidor (para administración)
  Future<List<Libro>> listarLibrosServidor() async {
    return await _service.obtenerLibrosServidor();
  }
}
