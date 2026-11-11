import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/boton_google_widget.dart';
import 'libros_view.dart';

class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  final AuthController _authController = AuthController();

  bool _mostrarPassword = false;
  bool _cargando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }


  // REGISTRO CON CORREO Y CONTRASEÑA
  Future<void> _registrarse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
    });

    try {
      await _authController.registrarse(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        email: _emailController.text.trim(),
        telefono: _telefonoController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      _abrirCatalogo('Cuenta creada. Bienvenido');
    } catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }


  // REGISTRO CON GOOGLE
  Future<void> _registrarseConGoogle() async {
    setState(() {
      _cargando = true;
    });

    try {
      final completado =
          await _authController.iniciarSesionConGoogle();

      // El usuario cerró la ventana de Google
      if (!completado || !mounted) return;

      _abrirCatalogo('Bienvenido');
    } catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }


  // Abrir el catálogo y quitar el login y el registro
  // del historial de navegación
  void _abrirCatalogo(String saludo) {
    final usuario = _authController.usuarioActual;

    if (usuario == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$saludo, ${usuario.nombre}'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => LibrosView(
          usuario: usuario,
          token: _authController.token!,
        ),
      ),
      (route) => false,
    );
  }


  void _mostrarError(Object e) {
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: AppColors.primario,
        foregroundColor: AppColors.tarjeta,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_add,
                  size: 70,
                  color: AppColors.primario,
                ),

                const SizedBox(height: 10),

                const Text(
                  'Regístrate en Biblioteca Móvil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                // Registro rápido con Google
                BotonGoogleWidget(
                  texto: 'Registrarse con Google',
                  onPressed: _cargando ? null : _registrarseConGoogle,
                ),

                const SizedBox(height: 20),

                const SeparadorOWidget(),

                const SizedBox(height: 20),

                // Nombre
                TextFormField(
                  controller: _nombreController,
                  enabled: !_cargando,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresa tu nombre';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Apellido
                TextFormField(
                  controller: _apellidoController,
                  enabled: !_cargando,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresa tu apellido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Correo electrónico
                TextFormField(
                  controller: _emailController,
                  enabled: !_cargando,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresa tu correo';
                    }

                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(valor.trim())) {
                      return 'Ingresa un correo válido';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Teléfono (opcional)
                TextFormField(
                  controller: _telefonoController,
                  enabled: !_cargando,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Contraseña
                TextFormField(
                  controller: _passwordController,
                  enabled: !_cargando,
                  obscureText: !_mostrarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    helperText: 'Mínimo 8 caracteres',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _mostrarPassword = !_mostrarPassword;
                        });
                      },
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Ingresa una contraseña';
                    }

                    // El backend exige mínimo 8 caracteres
                    if (valor.length < 8) {
                      return 'La contraseña debe tener al menos 8 caracteres';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirmar contraseña
                TextFormField(
                  controller: _confirmarPasswordController,
                  enabled: !_cargando,
                  obscureText: !_mostrarPassword,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    if (valor != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 25),

                // Botón crear cuenta
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cargando ? null : _registrarse,
                    icon: const Icon(Icons.how_to_reg),
                    label: Text(
                      _cargando ? 'Creando cuenta...' : 'Crear cuenta',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primario,
                      foregroundColor: AppColors.tarjeta,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                    ),
                  ),
                ),

                if (_cargando) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],

                const SizedBox(height: 16),

                // Volver al login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿Ya tienes una cuenta?'),
                    TextButton(
                      onPressed: _cargando
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Inicia sesión'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
