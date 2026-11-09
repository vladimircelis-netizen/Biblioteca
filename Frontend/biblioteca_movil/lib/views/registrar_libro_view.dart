
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/autor.dart';
import '../services/autor_service.dart';
import '../services/admin_libro_service.dart';

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

  bool _guardando = false;

  late Future<List<Autor>> _autores;
  int? _autorSeleccionado;

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

  
  Future<void> _guardarLibro() async {
    if (!_formKey.currentState!.validate()) return;

    if (_autorSeleccionado == null) return;

    setState(() {
      _guardando = true;
    });

    try {
      await _libroService.registrarLibro(
        titulo: _tituloController.text.trim(),
        isbn: _isbnController.text.trim(),
        anioPublicacion: int.parse(_anioController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        autorId: _autorSeleccionado!,
        token: widget.token,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Libro registrado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

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
                    onChanged: (valor) {
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

                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardarLibro,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar libro'),
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
