
class Autor {
  final int id;
  final String nombre;
  final String apellido;
  final String nacionalidad;

  Autor({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.nacionalidad,
  });

  factory Autor.fromJson(Map<String, dynamic> json) {
    return Autor(
      id: json['id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      nacionalidad: json['nacionalidad'] ?? '',
    );
  }

  String get nombreCompleto => '$nombre $apellido';
}
