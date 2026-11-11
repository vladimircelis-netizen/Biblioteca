class Usuario {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String rol;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.rol,
  });

  // Convertir la respuesta JSON de la API
  // en un objeto Usuario de Dart
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      email: json['email'],
      rol: json['rol'],
    );
  }

  // Convertir el usuario en JSON para guardarlo
  // en el celular (sesión guardada)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'rol': rol,
    };
  }

  // Nombre completo del usuario
  String get nombreCompleto => '$nombre $apellido';

  // Comprobar si tiene rol de Administrador
  bool get esAdministrador => rol == 'Administrador';
}
