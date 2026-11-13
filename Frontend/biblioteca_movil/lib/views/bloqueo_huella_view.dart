
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../models/usuario.dart';
import '../services/huella_service.dart';
import 'libros_view.dart';
import 'login_view.dart';

// Pantalla que pide la huella al abrir la app
// (cuando el usuario activó el ingreso con huella).
class BloqueoHuellaView extends StatefulWidget {
  final Usuario usuario;
  final String token;

  const BloqueoHuellaView({
    super.key,
    required this.usuario,
    required this.token,
  });

  @override
  State<BloqueoHuellaView> createState() => _BloqueoHuellaViewState();
}

class _BloqueoHuellaViewState extends State<BloqueoHuellaView> {
  final HuellaService _huellaService = HuellaService();

  bool _verificando = false;

  @override
  void initState() {
    super.initState();

    // Pedir la huella apenas se muestra la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ingresarConHuella();
    });
  }


  Future<void> ingresarConHuella() async {
    if (_verificando) return;

    setState(() {
      _verificando = true;
    });

    try {
      final correcta = await _huellaService.autenticar(
        'Usa tu huella para entrar a Biblioteca Móvil',
      );

      if (!correcta || !mounted) return;

      // Huella correcta: abrir el catálogo
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LibrosView(
            usuario: widget.usuario,
            token: widget.token,
          ),
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
    } finally {
      if (mounted) {
        setState(() {
          _verificando = false;
        });
      }
    }
  }


  // Salir de esta cuenta para entrar con otra
  Future<void> entrarConOtraCuenta() async {
    final esCuentaLocal = widget.token.isEmpty;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entrar con otra cuenta'),
        content: Text(
          esCuentaLocal
              ? 'Tu cuenta todavía no se ha registrado en el servidor. '
                  'Si sales, se perderá y tendrás que registrarte de nuevo.'
              : 'Se cerrará la sesión de ${widget.usuario.nombre} '
                  'en este celular.',
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

    if (confirmar != true || !mounted) return;

    // Otra persona va a entrar: se olvida también la huella
    await AuthController().cerrarSesion(olvidarHuella: true);

    if (!mounted) return;

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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.menu_book,
                  size: 70,
                  color: AppColors.primario,
                ),

                const SizedBox(height: 12),

                const Text(
                  'Biblioteca Móvil',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Hola, ${widget.usuario.nombre}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textoSecundario,
                  ),
                ),

                const SizedBox(height: 48),

                // Botón grande de huella
                IconButton(
                  iconSize: 96,
                  color: AppColors.primario,
                  tooltip: 'Ingresar con huella',
                  onPressed: _verificando ? null : ingresarConHuella,
                  icon: const Icon(Icons.fingerprint),
                ),

                const SizedBox(height: 8),

                Text(
                  _verificando
                      ? 'Verificando...'
                      : 'Toca para ingresar con tu huella',
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 48),

                TextButton(
                  onPressed: _verificando ? null : entrarConOtraCuenta,
                  child: const Text('Entrar con otra cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
