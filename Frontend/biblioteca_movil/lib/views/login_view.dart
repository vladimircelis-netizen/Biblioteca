import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../services/connectivity_service.dart';
import '../services/huella_service.dart';
import '../services/sesion_service.dart';
import '../widgets/boton_google_widget.dart';
import 'libros_view.dart';
import 'registro_view.dart';

class LoginView extends StatefulWidget {
  // Correo que se escribe automáticamente (último usado)
  final String? emailInicial;

  // true: se llegó al login porque el token venció
  final bool sesionVencida;

  // Mensaje que se muestra al abrir el login
  final String? mensajeInicial;

  // true: pedir la huella apenas se abre (al iniciar la app)
  final bool pedirHuella;

  const LoginView({
    super.key,
    this.emailInicial,
    this.sesionVencida = false,
    this.mensajeInicial,
    this.pedirHuella = false,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthController _authController = AuthController();

  bool _mostrarPassword = false;
  bool _cargando = false;

  // Sesión que se puede abrir con la huella (null = no activada)
  Sesion? _sesionHuella;

  @override
  void initState() {
    super.initState();

    _emailController.text = widget.emailInicial ?? '';

    _cargarHuella();

    // Mostrar el aviso (después de dibujar la pantalla)
    final mensaje = widget.mensajeInicial ??
        (widget.sesionVencida
            ? 'Tu sesión venció. Inicia sesión nuevamente.'
            : null);

    if (mensaje != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 6),
          ),
        );
      });
    }
  }

  // ¿Hay una cuenta con el ingreso con huella activado?
  Future<void> _cargarHuella() async {
    final sesion = await SesionService().obtenerSesionHuella();

    if (sesion == null || !mounted) return;

    setState(() {
      _sesionHuella = sesion;
    });

    // Al abrir la app, pedir la huella de una vez
    if (widget.pedirHuella) {
      await _ingresarConHuella();
    }
  }


  // INGRESAR CON HUELLA
  Future<void> _ingresarConHuella() async {
    final sesion = _sesionHuella;

    if (sesion == null || _cargando) return;

    setState(() {
      _cargando = true;
    });

    try {
      final correcta = await HuellaService().autenticar(
        'Usa tu huella para entrar como ${sesion.usuario.nombre}',
      );

      if (!correcta || !mounted) return;

      // La sesión venció (7 días): con internet hay que renovarla
      // con la contraseña; sin internet se entra solo a leer.
      if (sesion.tokenVencido) {
        final sinInternet = ConnectivityService.modoSinConexion.value ||
            !await ConnectivityService().tieneConexion();

        if (!mounted) return;

        if (!sinInternet) {
          _emailController.text = sesion.usuario.email;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tu sesión venció. Ingresa una vez con tu contraseña '
                'para renovarla; luego podrás seguir usando la huella.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 6),
            ),
          );
          return;
        }

        ConnectivityService.modoSinConexion.value = true;
      }

      await _authController.iniciarSesionConHuella(sesion);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bienvenido, ${sesion.usuario.nombre}'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LibrosView(
            usuario: sesion.usuario,
            token: sesion.token,
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
          _cargando = false;
        });
      }
    }
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
    });

    try {
      await _authController.iniciarSesion(
        _emailController.text.trim(),
        _passwordController.text,
      );

      
      if (!mounted) return;

      // Obtener el usuario autenticado
      final usuario = _authController.usuarioActual;

      if (usuario == null) return;

      // Mostrar mensaje de bienvenida
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bienvenido, ${usuario.nombre}',
          ),
        ),
      );

      // Abrir el catálogo después de iniciar sesión
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LibrosView(
            usuario: usuario,
            token: _authController.token!,
          ),
        ),
      );


      // Más adelante navegaremos a la pantalla
      // correspondiente al rol del usuario.
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
          _cargando = false;
        });
      }
    }
  }

  // INICIAR SESIÓN CON GOOGLE
  // Si la cuenta no existe, la API la registra automáticamente.
  Future<void> _iniciarSesionConGoogle() async {
    setState(() {
      _cargando = true;
    });

    try {
      final completado =
          await _authController.iniciarSesionConGoogle();

      // El usuario cerró la ventana de Google
      if (!completado || !mounted) return;

      final usuario = _authController.usuarioActual;

      if (usuario == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bienvenido, ${usuario.nombre}',
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LibrosView(
            usuario: usuario,
            token: _authController.token!,
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
          _cargando = false;
        });
      }
    }
  }

  // Abrir la pantalla de registro
  void _abrirRegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegistroView(),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
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
                Icon(
                  Icons.menu_book,
                  size: 90,
                  color: AppColors.primario,
                ),

                const SizedBox(height: 15),

                const Text(
                  'Biblioteca Móvil',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // Correo electrónico
                TextFormField(
                  controller: _emailController,
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

                    if (!valor.contains('@')) {
                      return 'Ingresa un correo válido';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_mostrarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
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
                      return 'Ingresa tu contraseña';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 25),

                // Botón iniciar sesión
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cargando ? null : _iniciarSesion,
                    icon: const Icon(Icons.login),
                    label: Text(
                      _cargando
                          ? 'Ingresando...'
                          : 'Iniciar sesión',
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

                // Botón ingresar con huella (si está activada)
                if (_sesionHuella != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _cargando ? null : _ingresarConHuella,
                      icon: const Icon(Icons.fingerprint, size: 28),
                      label: Text(
                        'Ingresar con huella '
                        '(${_sesionHuella!.usuario.nombre})',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primario,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        side: const BorderSide(color: AppColors.primario),
                      ),
                    ),
                  ),
                ],

                if (_cargando) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],

                const SizedBox(height: 20),

                const SeparadorOWidget(),

                const SizedBox(height: 20),

                // Botón iniciar sesión con Google
                BotonGoogleWidget(
                  texto: 'Continuar con Google',
                  onPressed: _cargando ? null : _iniciarSesionConGoogle,
                ),

                const SizedBox(height: 16),

                // Ir a la pantalla de registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿No tienes una cuenta?'),
                    TextButton(
                      onPressed: _cargando ? null : _abrirRegistro,
                      child: const Text('Regístrate'),
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
