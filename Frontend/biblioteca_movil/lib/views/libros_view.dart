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
import '../widgets/portada_libro_widget.dart';
import '../controllers/auth_controller.dart';
import '../services/sesion_service.dart';
import '../services/auth_service.dart';

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

  // Cuenta creada sin internet (todavía no está en el servidor)
  bool get _esCuentaLocal => widget.token.isEmpty;

  bool _sincronizandoCuenta = false;

  @override
  void initState() {
    super.initState();

    _libros = _controller.listarLibros();

    verificarConexion();

    // Intentar registrar la cuenta local en el servidor
    if (_esCuentaLocal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sincronizarCuentaLocal();
      });
    }

    _conexionSubscription =
        _connectivityService.cambiosConexion.listen((resultados) {
      if (!mounted) return;

      setState(() {
        _tieneConexion = resultados.any(
          (resultado) => resultado != ConnectivityResult.none,
        );
      });

      // Volvió la conexión: registrar la cuenta local
      if (_tieneConexion) {
        sincronizarCuentaLocal();
      }
    });
  }


  // Registrar en el servidor la cuenta creada sin internet.
  // Si lo logra, la pantalla se recarga con la sesión real.
  Future<void> sincronizarCuentaLocal() async {
    if (!_esCuentaLocal ||
        _sincronizandoCuenta ||
        ConnectivityService.modoSinConexion.value) {
      return;
    }

    _sincronizandoCuenta = true;

    final authController = AuthController();

    try {
      final registrada =
          await authController.sincronizarCuentaPendiente();

      if (!registrada || !mounted) return;

      final usuario = authController.usuarioActual;
      final token = authController.token;

      if (usuario == null || token == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu cuenta quedó registrada. Catálogo actualizado.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Recargar el catálogo con la sesión del servidor
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LibrosView(
            usuario: usuario,
            token: token,
          ),
        ),
      );
    } on SinConexionException {
      // Sigue sin internet: se intentará más tarde
    } on CorreoRegistradoException catch (e) {
      if (!mounted) return;

      // El correo ya tenía otra cuenta: iniciar sesión con ella
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginView(
            emailInicial: widget.usuario.email,
            mensajeInicial: e.mensaje,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('No se pudo registrar la cuenta local: $e');
    } finally {
      _sincronizandoCuenta = false;
    }
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

  // Activar o desactivar el modo sin conexión (ícono de wifi)
  void cambiarModoConexion() {
    // Si se vuelve a conectar con el token vencido
    // (se entró sin internet), hay que iniciar sesión de nuevo.
    // Las cuentas locales no tienen token: se registran solas.
    if (ConnectivityService.modoSinConexion.value &&
        !_esCuentaLocal &&
        Sesion(usuario: widget.usuario, token: widget.token)
            .tokenVencido) {
      ConnectivityService.establecerModoSinConexion(false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginView(
            emailInicial: widget.usuario.email,
            sesionVencida: true,
          ),
        ),
        (route) => false,
      );
      return;
    }

    ConnectivityService.cambiarModoSinConexion();

    final sinConexion = ConnectivityService.modoSinConexion.value;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sinConexion
              ? 'Modo sin conexión: se muestran los libros guardados'
              : _tieneConexion
                  ? 'Conectado: actualizando libros desde el servidor'
                  : 'Modo en línea activado, pero el celular no tiene internet',
        ),
        backgroundColor: sinConexion ? Colors.orange : Colors.green,
      ),
    );

    // Volver a cargar los libros con el nuevo modo
    actualizarLibros();

    // Al conectarse, registrar la cuenta local
    if (!sinConexion) {
      sincronizarCuentaLocal();
    }
  }

  // Ícono según el modo y la conexión real del celular
  Widget _iconoConexion() {
    final sinConexion = ConnectivityService.modoSinConexion.value;

    IconData icono;
    Color color;
    String descripcion;

    if (sinConexion) {
      icono = Icons.wifi_off;
      color = Colors.orangeAccent;
      descripcion = 'Modo sin conexión. Toca para conectar';
    } else if (_tieneConexion) {
      icono = Icons.wifi;
      color = Colors.greenAccent;
      descripcion = 'Conectado. Toca para trabajar sin conexión';
    } else {
      icono = Icons.signal_wifi_connected_no_internet_4;
      color = Colors.white70;
      descripcion = 'El celular no tiene internet';
    }

    return IconButton(
      icon: Icon(icono, color: color),
      tooltip: descripcion,
      onPressed: cambiarModoConexion,
    );
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
                // La administración necesita la API
                if (ConnectivityService.modoSinConexion.value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Activa la conexión (ícono de wifi) '
                        'para administrar la biblioteca',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

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
            onSelected: (opcion) async {
              if (opcion == 'salir') {
                // La cuenta local se pierde si se cierra sesión
                // antes de registrarla en el servidor
                if (_esCuentaLocal) {
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cerrar sesión'),
                      content: const Text(
                        'Tu cuenta todavía no se ha registrado en el '
                        'servidor porque no ha habido conexión. '
                        'Si cierras sesión, se perderá y tendrás que '
                        'registrarte de nuevo.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Cerrar sesión',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmar != true) return;
                }

                // Borrar la sesión guardada y cerrar la de Google
                await AuthController().cerrarSesion();

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginView(
                      emailInicial: widget.usuario.email,
                    ),
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
          // Conectar o desconectar la aplicación
          _iconoConexion(),

          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar libros',
            onPressed: actualizarLibros,
          ),
        ],
      ),

      body: Column(
        children: [
          // Aviso de cuenta creada sin internet
          if (_esCuentaLocal)
            Container(
              width: double.infinity,
              color: Colors.blue.shade50,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: const Row(
                children: [
                  Icon(Icons.sync, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tu cuenta se registrará automáticamente '
                      'cuando tengas internet.',
                    ),
                  ),
                ],
              ),
            ),

          // Aviso del modo sin conexión
          if (ConnectivityService.modoSinConexion.value)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_off, size: 18, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modo sin conexión: mostrando los libros guardados',
                    ),
                  ),
                ],
              ),
            ),

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
                        leading: PortadaLibroWidget(
                          rutaPortada: libro.rutaPortada,
                          ancho: 40,
                          alto: 60,
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
