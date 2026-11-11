
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/autor.dart';
import '../models/tipo_archivo.dart';
import '../services/autor_service.dart';
import '../services/admin_libro_service.dart';
import '../services/archivo_service.dart';
import '../widgets/selector_archivo_widget.dart';
import 'registrar_autor_view.dart';

class RegistrarLibroView extends StatefulWidget {
  final String token;

  const RegistrarLibroView({
    super.key,
    required this.token,
  });

  @override
  State<RegistrarLibroView> createState() =>
      _RegistrarLibroViewState();
}

class _RegistrarLibroViewState
    extends State<RegistrarLibroView> {

  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _isbnController = TextEditingController();
  final _anioController = TextEditingController();
  final _stockController = TextEditingController();

  final AutorService _autorService = AutorService();
  final AdminLibroService _libroService = AdminLibroService();
  final ArchivoService _archivoService = ArchivoService();

  bool _guardando = false;

  // Mensaje del paso actual: "Subiendo portada..."
  String? _estado;

  late Future<List<Autor>> _autores;
  int? _autorSeleccionado;

  // Cambia al crear un autor para redibujar la lista de autores
  int _versionAutores = 0;

  // Archivos elegidos en el dispositivo (opcionales)
  final Map<TipoArchivo, PlatformFile> _archivos = {};

  @override
  void initState() {
    super.initState();
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
      _archivos[tipo] = archivo;
    });
  }


  Future<void> _guardarLibro() async {
    if (!_formKey.currentState!.validate()) return;

    if (_autorSeleccionado == null) return;

    setState(() {
      _guardando = true;
      _estado = 'Guardando datos del libro...';
    });

    try {
      // 1. Registrar los datos del libro en MySQL
      final libroId = await _libroService.registrarLibro(
        titulo: _tituloController.text.trim(),
        isbn: _isbnController.text.trim(),
        anioPublicacion: int.parse(_anioController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        autorId: _autorSeleccionado!,
        token: widget.token,
      );

      // 2. Subir los archivos elegidos a Cloudinary
      final errores = <String>[];

      for (final entrada in _archivos.entries) {
        if (!mounted) return;

        setState(() {
          _estado = 'Subiendo ${entrada.key.nombre.toLowerCase()}...';
        });

        try {
          await _archivoService.subirArchivo(
            libroId: libroId,
            tipo: entrada.key,
            archivo: entrada.value,
            token: widget.token,
          );
        } catch (e) {
          errores.add(
            e.toString().replaceFirst('Exception: ', ''),
          );
        }
      }

      if (!mounted) return;

      // 3. Informar el resultado
      if (errores.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Libro registrado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // El libro sí se registró: los archivos que fallaron
        // se pueden subir después desde "Archivos digitales".
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Libro registrado, pero hubo problemas:\n'
              '${errores.join('\n')}\n'
              'Puedes subirlos desde "Archivos digitales".',
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
        title: const Text('Registrar libro'),
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
              child: Text(
                'Error al cargar autores: ${snapshot.error}',
              ),
            );
          }

          final autores = snapshot.data ?? [];

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
                      if (valor == null ||
                          valor.trim().isEmpty) {
                        return 'El título es obligatorio';
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
                      final anio = int.tryParse(valor ?? '');
                      if (anio == null ||
                          anio < 1450 ||
                          anio > 2026) {
                        return 'Ingresa un año entre 1450 y 2026';
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
                      final stock = int.tryParse(valor ?? '');
                      if (stock == null || stock < 0) {
                        return 'El stock no puede ser negativo';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    key: ValueKey('autores_$_versionAutores'),
                    initialValue: _autorSeleccionado,
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
                        return 'Selecciona un autor';
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
                    'Archivos digitales (opcional)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Se subirán a la nube al guardar el libro.',
                    style: TextStyle(
                      color: AppColors.textoSecundario,
                    ),
                  ),

                  const SizedBox(height: 12),

                  for (final tipo in TipoArchivo.values)
                    SelectorArchivoWidget(
                      tipo: tipo,
                      archivoSeleccionado: _archivos[tipo],
                      habilitado: !_guardando,
                      onSeleccionar: () => _elegirArchivo(tipo),
                      onQuitarSeleccion: () {
                        setState(() {
                          _archivos.remove(tipo);
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
                    onPressed: _guardando ? null : _guardarLibro,
                    icon: const Icon(Icons.save),
                    label: Text(
                      _guardando ? 'Guardando...' : 'Guardar libro',
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
