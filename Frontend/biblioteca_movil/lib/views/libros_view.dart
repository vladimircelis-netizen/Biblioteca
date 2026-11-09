import 'package:flutter/material.dart';
import '../controllers/libro_controller.dart';
import '../models/libro.dart';
import '../config/app_colors.dart';
import 'libro_detalle_view.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/connectivity_service.dart';
import '../models/usuario.dart';
import 'login_view.dart';
import 'admin_view.dart';

class LibrosView extends StatefulWidget {
  
  final Usuario usuario;
  final String token;

  const LibrosView({
    super.key,
    required this.usuario,
    required this.token,
  });

  @override
  State<LibrosView> createState() => _LibrosViewState();
}

class _LibrosViewState extends State<LibrosView> {
  final LibroController _controller = LibroController();

  final ConnectivityService _connectivityService =
    ConnectivityService();

  StreamSubscription<List<ConnectivityResult>>? _conexionSubscription;

  bool _tieneConexion = false;

  late Future<List<Libro>> _libros;

  String textoBusqueda = '';

  @override
  void initState() {
    super.initState();

    _libros = _controller.listarLibros();

    verificarConexion();

    _conexionSubscription =
        _connectivityService.cambiosConexion.listen((resultados) {
      if (!mounted) return;

      setState(() {
        _tieneConexion = resultados.any(
          (resultado) => resultado != ConnectivityResult.none,
        );
      });
    });
  }

  Future<void> verificarConexion() async {
    final conexion = await _connectivityService.tieneConexion();

    if (!mounted) return;

    setState(() {
      _tieneConexion = conexion;
    });
  }

  @override
  void dispose() {
    _conexionSubscription?.cancel();
    super.dispose();
  }

  // Consultar nuevamente los libros
  void actualizarLibros() {
    setState(() {
      _libros = _controller.listarLibros();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,

      // Barra superior
      appBar: AppBar(
        title: const Text('Biblioteca Móvil'),
        backgroundColor: AppColors.primario,
        foregroundColor: AppColors.tarjeta,
        actions: [
          if (widget.usuario.esAdministrador)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Panel de administración',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminView(
                      token: widget.token,
                    ),
                      
                  ),
                );
              },
            ),



          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Mi cuenta',
            onSelected: (opcion) {
              if (opcion == 'salir') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginView(),
                  ),
                  (route) => false,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.usuario.nombreCompleto,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Rol: ${widget.usuario.rol}'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'salir',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 10),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
          Icon(
            _tieneConexion ? Icons.wifi : Icons.wifi_off,
            color: _tieneConexion ? Colors.greenAccent : Colors.white70,
          ),
          const SizedBox(width: 8),

          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar libros',
            onPressed: actualizarLibros,
          ),
        ],
      ),

      body: Column(
        children: [
          // Campo para buscar libros
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar libro por título...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.tarjeta,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (valor) {
                setState(() {
                  textoBusqueda = valor;
                });
              },
            ),
          ),

          // Lista de libros
          Expanded(
            child: FutureBuilder<List<Libro>>(
              future: _libros,
              builder: (context, snapshot) {

                // Mientras se consultan los datos
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Si ocurre un error
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                    ),
                  );
                }

                // Obtener los libros de la API
                final libros = snapshot.data ?? [];

                // Filtrar por título
                final librosFiltrados = libros.where((libro) {
                  return libro.titulo.toLowerCase().contains(
                    textoBusqueda.toLowerCase().trim(),
                  );
                }).toList();

                // Si la base de datos no tiene libros
                if (libros.isEmpty) {
                  return const Center(
                    child: Text('No hay libros disponibles'),
                  );
                }

                // Si la búsqueda no tiene resultados
                if (librosFiltrados.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron libros'),
                  );
                }

                // Mostrar los libros encontrados
                return ListView.builder(
                  itemCount: librosFiltrados.length,
                  itemBuilder: (context, index) {

                    final libro = librosFiltrados[index];

                    return Card(
                      color: AppColors.tarjeta,
                      margin: const EdgeInsets.all(10),

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

                        // Abrir los detalles del libro
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LibroDetalleView(
                                libro: libro,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
