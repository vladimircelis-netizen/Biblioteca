
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../models/libro.dart';
import '../models/autor.dart';
import '../models/tipo_archivo.dart';
import '../services/autor_service.dart';
import '../services/admin_libro_service.dart';
import '../services/archivo_service.dart';
import '../widgets/selector_archivo_widget.dart';
import 'registrar_autor_view.dart';

class EditarLibroView extends StatefulWidget {
  final Libro libro;
  final String token;

  const EditarLibroView({
    super.key,
    required this.libro,
    required this.token,
  });

  @override
  State<EditarLibroView> createState() => _EditarLibroViewState();
}

class _EditarLibroViewState extends State<EditarLibroView> {
  final _formKey = GlobalKey<FormState>();

  final _libroService = AdminLibroService();
  final _autorService = AutorService();
  final _archivoService = ArchivoService();

  late TextEditingController _tituloController;
  late TextEditingController _isbnController;
  late TextEditingController _anioController;
  late TextEditingController _stockController;

  late Future<List<Autor>> _autores;

  int? _autorSeleccionado;
  bool _guardando = false;

  // Cambia al crear un autor para redibujar la lista de autores
  int _versionAutores = 0;

  // Mensaje del paso actual: "Subiendo PDF..."
  String? _estado;

  // Archivos nuevos elegidos (reemplazan al actual)
  final Map<TipoArchivo, PlatformFile> _archivosNuevos = {};

  // Archivos actuales que se eliminarán al guardar
  final Set<TipoArchivo> _archivosPorEliminar = {};

  @override
  void initState() {
    super.initState();

    _tituloController =
        TextEditingController(text: widget.libro.titulo);

    _isbnController =
        TextEditingController(text: widget.libro.isbn);

    _anioController = TextEditingController(
      text: widget.libro.anioPublicacion.toString(),
    );

    _stockController = TextEditingController(
      text: widget.libro.stock.toString(),
    );

    _autorSeleccionado = widget.libro.autorId;
    _autores = _autorService.listarAutores();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _isbnController.dispose();
    _anioController.dispose();
    _stockController.dispose();
    super.dispose();
  }


  // Ruta guardada en la nube para cada tipo de archivo.
  // Las rutas de assets (demo) no se pueden editar.
  String? _rutaActual(TipoArchivo tipo) {
    final ruta = switch (tipo) {
      TipoArchivo.portada => widget.libro.rutaPortada,
      TipoArchivo.pdf => widget.libro.rutaPdf,
      TipoArchivo.audio => widget.libro.rutaAudio,
    };

    if (ruta == null || !ruta.startsWith('http')) return null;

    return ruta;
  }


  // Crear un autor sin salir del formulario.
  // El autor nuevo se agrega a la lista y queda seleccionado.
  Future<void> _crearAutor() async {
    final autor = await Navigator.push<Autor>(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrarAutorView(
          token: widget.token,
        ),
      ),
    );

    if (autor == null || !mounted) return;

    setState(() {
      _autores = _autores.then((lista) => [...lista, autor]);
      _autorSeleccionado = autor.id;
      _versionAutores++;
    });
  }


  Future<void> _elegirArchivo(TipoArchivo tipo) async {
    final archivo = await seleccionarArchivo(context, tipo);

    if (archivo == null || !mounted) return;

    setState(() {
      _archivosNuevos[tipo] = archivo;
      _archivosPorEliminar.remove(tipo);
    });
  }


  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _estado = 'Guardando datos del libro...';
    });

    try {
      // 1. Actualizar los datos del libro en MySQL
      await _libroService.actualizarLibro(
        id: widget.libro.id,
        titulo: _tituloController.text.trim(),
        isbn: _isbnController.text.trim(),
        anioPublicacion: int.parse(_anioController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        autorId: _autorSeleccionado!,
        token: widget.token,
      );

      final errores = <String>[];

      // 2. Subir los archivos nuevos (reemplazan a los actuales)
      for (final entrada in _archivosNuevos.entries) {
        if (!mounted) return;

        setState(() {
          _estado = 'Subiendo ${entrada.key.nombre.toLowerCase()}...';
        });

        try {
          await _archivoService.subirArchivo(
            libroId: widget.libro.id,
            tipo: entrada.key,
            archivo: entrada.value,
            token: widget.token,
          );
        } catch (e) {
          errores.add(e.toString().replaceFirst('Exception: ', ''));
        }
      }

      // 3. Eliminar los archivos marcados
      for (final tipo in _archivosPorEliminar) {
        if (!mounted) return;

        setState(() {
          _estado = 'Eliminando ${tipo.nombre.toLowerCase()}...';
        });

        try {
          await _archivoService.eliminarArchivo(
            libroId: widget.libro.id,
            tipo: tipo,
            token: widget.token,
          );
        } catch (e) {
          errores.add(e.toString().replaceFirst('Exception: ', ''));
        }
      }

      if (!mounted) return;

      // 4. Informar el resultado
      if (errores.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Libro actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Datos actualizados, pero hubo problemas:\n'
              '${errores.join('\n')}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 6),
          ),
        );
      }

      Navigator.pop(context, true);
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
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
          _estado = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        title: const Text('Editar libro'),
        backgroundColor: AppColors.primario,
        foregroundColor: AppColors.tarjeta,
      ),
      body: FutureBuilder<List<Autor>>(
        future: _autores,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar autores: ${snapshot.error}'),
            );
          }

          final autores = snapshot.data ?? [];

          final autorDisponible = autores.any(
            (autor) => autor.id == _autorSeleccionado,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Datos del libro',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _tituloController,
                    maxLength: 200,
                    enabled: !_guardando,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Ingrese el título';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _isbnController,
                    keyboardType: TextInputType.number,
                    enabled: !_guardando,
                    decoration: const InputDecoration(
                      labelText: 'ISBN',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null ||
                          !RegExp(r'^(\d{10}|\d{13})$')
                              .hasMatch(valor.trim())) {
                        return 'El ISBN debe tener 10 o 13 dígitos';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _anioController,
                    keyboardType: TextInputType.number,
                    enabled: !_guardando,
                    decoration: const InputDecoration(
                      labelText: 'Año de publicación',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      final anio = int.tryParse(valor?.trim() ?? '');
                      if (anio == null || anio < 1450 || anio > 2026) {
                        return 'Ingrese un año entre 1450 y 2026';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    enabled: !_guardando,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      final stock = int.tryParse(valor?.trim() ?? '');
                      if (stock == null || stock < 0) {
                        return 'Ingrese un stock válido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    key: ValueKey('autores_$_versionAutores'),
                    initialValue: autorDisponible
                        ? _autorSeleccionado
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Autor',
                      border: OutlineInputBorder(),
                    ),
                    items: autores.map((autor) {
                      return DropdownMenuItem<int>(
                        value: autor.id,
                        child: Text(autor.nombreCompleto),
                      );
                    }).toList(),
                    onChanged: _guardando
                        ? null
                        : (valor) {
                            setState(() {
                              _autorSeleccionado = valor;
                            });
                          },
                    validator: (valor) {
                      if (valor == null) {
                        return 'Seleccione un autor';
                      }
                      return null;
                    },
                  ),

                  // Crear el autor si no está en la lista
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _guardando ? null : _crearAutor,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Nuevo autor'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ARCHIVOS DIGITALES
                  const Text(
                    'Archivos digitales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Los cambios en los archivos se aplican al guardar.',
                    style: TextStyle(
                      color: AppColors.textoSecundario,
                    ),
                  ),

                  const SizedBox(height: 12),

                  for (final tipo in TipoArchivo.values)
                    SelectorArchivoWidget(
                      tipo: tipo,
                      rutaActual: _rutaActual(tipo),
                      archivoSeleccionado: _archivosNuevos[tipo],
                      marcadoParaEliminar:
                          _archivosPorEliminar.contains(tipo),
                      habilitado: !_guardando,
                      onSeleccionar: () => _elegirArchivo(tipo),
                      onQuitarSeleccion: () {
                        setState(() {
                          _archivosNuevos.remove(tipo);
                          _archivosPorEliminar.remove(tipo);
                        });
                      },
                      onEliminarActual: () {
                        setState(() {
                          _archivosPorEliminar.add(tipo);
                        });
                      },
                    ),

                  const SizedBox(height: 16),

                  // Progreso del guardado
                  if (_estado != null) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      _estado!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],

                  ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardarCambios,
                    icon: const Icon(Icons.save),
                    label: Text(
                      _guardando
                          ? 'Guardando...'
                          : 'Guardar cambios',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primario,
                      foregroundColor: AppColors.tarjeta,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
