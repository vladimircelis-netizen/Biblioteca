
import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../models/libro.dart';
import '../models/autor.dart';
import '../services/autor_service.dart';
import '../services/admin_libro_service.dart';

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

  late TextEditingController _tituloController;
  late TextEditingController _isbnController;
  late TextEditingController _anioController;
  late TextEditingController _stockController;

  late Future<List<Autor>> _autores;

  int? _autorSeleccionado;
  bool _guardando = false;

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

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
    });

    try {
      await _libroService.actualizarLibro(
        id: widget.libro.id,
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
          content: Text('Libro actualizado correctamente'),
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
                  TextFormField(
                    controller: _tituloController,
                    maxLength: 200,
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

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _anioController,
                    keyboardType: TextInputType.number,
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

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
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

                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    value: autorDisponible
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
                    onChanged: (valor) {
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

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _guardando ? null : _guardarCambios,
                    child: Text(
                      _guardando
                          ? 'Guardando...'
                          : 'Guardar cambios',
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
