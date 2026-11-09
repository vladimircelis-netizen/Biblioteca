
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../controllers/libro_controller.dart';
import '../models/libro.dart';
import 'editar_libro_view.dart';
import '../services/admin_libro_service.dart';

class GestionarLibrosView extends StatefulWidget {
  final String token;

  const GestionarLibrosView({
    super.key,
    required this.token,
  });

  @override
  State<GestionarLibrosView> createState() =>
      _GestionarLibrosViewState();
}

class _GestionarLibrosViewState
    extends State<GestionarLibrosView> {

  final LibroController _controller = LibroController();
  final AdminLibroService _adminLibroService = AdminLibroService();

  late Future<List<Libro>> _libros;

  @override
  void initState() {
    super.initState();
    _libros = _controller.listarLibros();
  }

  // Actualizar la lista de libros
  void actualizarLibros() {
    setState(() {
      _libros = _controller.listarLibros();
    });
  }

  // ELIMINAR LIBRO
  Future<void> eliminarLibro(Libro libro) async {

    // Mostrar ventana de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar libro'),
        content: Text(
          '¿Estás seguro de eliminar "${libro.titulo}"? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    // Si cancela, no hacemos nada
    if (confirmar != true || !mounted) return;

    try {
      // Enviar solicitud DELETE a la API
      await _adminLibroService.eliminarLibro(
        id: libro.id,
        token: widget.token,
      );

      if (!mounted) return;

      // Actualizar la lista
      actualizarLibros();

      // Mostrar mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Libro eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,

      appBar: AppBar(
        title: const Text('Gestionar libros'),
        backgroundColor: AppColors.primario,
        foregroundColor: AppColors.tarjeta,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: actualizarLibros,
          ),
        ],
      ),

      body: FutureBuilder<List<Libro>>(
        future: _libros,
        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar libros: ${snapshot.error}',
              ),
            );
          }

          final libros = snapshot.data ?? [];

          if (libros.isEmpty) {
            return const Center(
              child: Text('No hay libros registrados'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: libros.length,
            itemBuilder: (context, index) {

              final libro = libros[index];

              return Card(
                color: AppColors.tarjeta,
                margin: const EdgeInsets.only(bottom: 12),

                child: ListTile(
                  leading: const Icon(
                    Icons.menu_book,
                    color: AppColors.primario,
                  ),

                  title: Text(libro.titulo),

                  subtitle: Text(
                    'Autor: ${libro.nombreAutor}\n'
                    'Año: ${libro.anioPublicacion}\n'
                    'Stock: ${libro.stock}',
                  ),

                  isThreeLine: true,

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // BOTÓN EDITAR
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                        ),
                        tooltip: 'Editar libro',
                        onPressed: () async {
                          final actualizado =
                              await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditarLibroView(
                                libro: libro,
                                token: widget.token,
                              ),
                            ),
                          );

                          if (!mounted) return;

                          if (actualizado == true) {
                            actualizarLibros();
                          }
                        },
                      ),

                      // BOTÓN ELIMINAR
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        tooltip: 'Eliminar libro',
                        onPressed: () {
                          eliminarLibro(libro);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
