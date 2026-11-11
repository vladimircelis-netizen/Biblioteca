
import '../models/libro.dart';

// Libros que vienen dentro de la app (carpeta assets).
//
// 1. La primera vez que se abre la app, aunque no haya internet,
//    el catálogo muestra estos libros y se pueden leer.
// 2. Cuando hay internet, el catálogo del servidor los reemplaza.
// 3. Si un libro del servidor tiene el mismo ISBN, sus archivos
//    incluidos se siguen usando cuando no hay conexión.
//
// Los ID, ISBN y AutorId coinciden con la base de datos del servidor.
// El nombre del autor se actualiza al sincronizar con la API.
class CatalogoInicial {
  static final List<Libro> libros = [
    Libro(
      id: 2,
      titulo: 'El amor en los tiempos del cólera',
      isbn: '9780307474728',
      anioPublicacion: 1985,
      stock: 10,
      autorId: 1,
      nombreAutor: 'Gabriel García Márquez',
      rutaPortada: 'assets/portadas/amor_tiempos_colera.jpg',
      rutaPdf: 'assets/libros/pdf/el-amor-en-los-tiempos-del-colera.pdf',
      rutaAudio: 'assets/libros/mp3/audio_prueba.mp3',
    ),
    Libro(
      id: 6,
      titulo: 'Libertad de elegir',
      isbn: '9788420412146',
      anioPublicacion: 1980,
      stock: 8,
      autorId: 3,
      nombreAutor: 'Milton Friedman',
      rutaPdf: 'assets/libros/pdf/LIBERTAD_DE_ELEGIR.pdf',
    ),
    Libro(
      id: 7,
      titulo: 'El libro negro de la nueva izquierda',
      isbn: '1234567893',
      anioPublicacion: 2016,
      stock: 4,
      autorId: 2,
      nombreAutor: 'Nicolas Marquez',
      rutaPortada: 'assets/portadas/nueva_izquierda.jpg',
      rutaPdf: 'assets/libros/pdf/El_LIBRO_NEGRO.pdf',
    ),
  ];

  // Buscar el libro incluido que tenga el mismo ISBN
  static Libro? buscarPorIsbn(String isbn) {
    for (final libro in libros) {
      if (libro.isbn == isbn) return libro;
    }

    return null;
  }
}
