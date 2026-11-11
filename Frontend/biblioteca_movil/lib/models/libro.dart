
class Libro {
  final int id;
  final String titulo;
  final String isbn;
  final int anioPublicacion;
  final int stock;
  final int autorId;
  final String nombreAutor;

  // Archivos digitales (opcionales).
  // Pueden ser una URL de Cloudinary o una ruta de assets (demo).
  final String? rutaPdf;
  final String? rutaPortada;
  final String? rutaAudio;

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
    this.rutaAudio,
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
      rutaAudio: json['rutaAudio'],
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
      'rutaAudio': rutaAudio,
    };
  }

  // Comprobar qué archivos digitales tiene el libro
  bool get tienePortada => rutaPortada?.isNotEmpty ?? false;
  bool get tienePdf => rutaPdf?.isNotEmpty ?? false;
  bool get tieneAudio => rutaAudio?.isNotEmpty ?? false;

  // El libro tiene portada, PDF y audio
  bool get archivosCompletos => tienePortada && tienePdf && tieneAudio;

}
