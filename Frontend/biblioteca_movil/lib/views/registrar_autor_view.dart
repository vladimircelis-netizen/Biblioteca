
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/autor_service.dart';

// Registrar un autor.
// Al guardar, devuelve el Autor creado a la pantalla anterior
// (por ejemplo, Registrar libro lo selecciona automáticamente).
class RegistrarAutorView extends StatefulWidget {
  final String token;

  const RegistrarAutorView({
    super.key,
    required this.token,
  });

  @override
  State<RegistrarAutorView> createState() =>
      _RegistrarAutorViewState();
}

class _RegistrarAutorViewState
    extends State<RegistrarAutorView> {

  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _nacionalidadController = TextEditingController();

  final AutorService _autorService = AutorService();

  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _nacionalidadController.dispose();
    super.dispose();
  }


  Future<void> _guardarAutor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
    });

    try {
      final autor = await _autorService.crearAutor(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        nacionalidad: _nacionalidadController.text.trim(),
        token: widget.token,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Autor ${autor.nombreCompleto} registrado correctamente',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, autor);

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


  // Validación común: obligatorio y máximo 100 caracteres
  // (igual que CrearAutorDto en el backend)
  String? _validarTexto(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) {
      return 'El campo $campo es obligatorio';
    }

    if (valor.trim().length > 100) {
      return 'Máximo 100 caracteres';
    }

    return null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        title: const Text('Registrar autor'),
        backgroundColor: AppColors.primario,
        foregroundColor: AppColors.tarjeta,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Datos del autor',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _nombreController,
                maxLength: 100,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) => _validarTexto(valor, 'nombre'),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _apellidoController,
                maxLength: 100,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) => _validarTexto(valor, 'apellido'),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _nacionalidadController,
                maxLength: 100,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nacionalidad',
                  prefixIcon: Icon(Icons.flag),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) =>
                    _validarTexto(valor, 'nacionalidad'),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _guardando ? null : _guardarAutor,
                icon: const Icon(Icons.save),
                label: Text(
                  _guardando ? 'Guardando...' : 'Guardar autor',
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
      ),
    );
  }
}
