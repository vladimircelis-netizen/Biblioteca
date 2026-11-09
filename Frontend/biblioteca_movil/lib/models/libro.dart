
class Libro {
  final int id;
  final String titulo;
  final String isbn;
  final int anioPublicacion;
  final int stock;
  final int autorId;
  final String nombreAutor;

  // Ruta del archivo PDF (opcional)
  final String? rutaPdf;
  final String? rutaPortada;

  Libro({
    required this.id,
    required this.titulo,
    required this.isbn,
    required this.anioPublicacion,
    required this.stock,
    required this.autorId,
    required this.nombreAutor,
    this.rutaPdf,
    this.rutaPortada,
  });

  factory Libro.fromJson(Map<String, dynamic> json) {
    return Libro(
      id: json['id'],
      titulo: json['titulo'],
      isbn: json['isbn'],
      anioPublicacion: json['anioPublicacion'],
      stock: json['stock'],
      autorId: json['autorId'],
      nombreAutor: json['nombreAutor'],
      rutaPdf: json['rutaPdf'],
      rutaPortada: json['rutaPortada'],
    );
  }

  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'isbn': isbn,
      'anioPublicacion': anioPublicacion,
      'stock': stock,
      'autorId': autorId,
      'nombreAutor': nombreAutor,
      'rutaPdf': rutaPdf,
      'rutaPortada': rutaPortada,
    };
  }

}
