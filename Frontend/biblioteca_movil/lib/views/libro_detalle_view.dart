
import 'package:flutter/material.dart';

import '../models/libro.dart';
import '../models/tipo_archivo.dart';
import '../config/app_colors.dart';
import '../config/catalogo_inicial.dart';
import '../services/connectivity_service.dart';
import '../services/descarga_service.dart';
import '../widgets/portada_libro_widget.dart';

import 'lector_pdf_view.dart';
import 'reproductor_audio_view.dart';

class LibroDetalleView extends StatefulWidget {
  final Libro libro;

  const LibroDetalleView({
    super.key,
    required this.libro,
  });

  @override
  State<LibroDetalleView> createState() => _LibroDetalleViewState();
}

class _LibroDetalleViewState extends State<LibroDetalleView> {
  final DescargaService _descargaService = DescargaService();

  // Archivos descargados en el celular (PDF y audio)
  final Map<TipoArchivo, Descarga?> _descargas = {};

  // Progreso de las descargas en curso (0.0 a 1.0)
  final Map<TipoArchivo, double> _progreso = {};

  Libro get libro => widget.libro;

  @override
  void initState() {
    super.initState();
    cargarDescargas();
  }


  // URL del archivo en el servidor
  String? _urlArchivo(TipoArchivo tipo) {
    return tipo == TipoArchivo.pdf ? libro.rutaPdf : libro.rutaAudio;
  }

  // Solo se pueden descargar los archivos de Cloudinary.
  // Los archivos demo ya vienen dentro de la app.
  bool _esDescargable(TipoArchivo tipo) {
    return _urlArchivo(tipo)?.startsWith('http') ?? false;
  }


  // Consultar qué archivos ya están descargados
  Future<void> cargarDescargas() async {
    for (final tipo in [TipoArchivo.pdf, TipoArchivo.audio]) {
      if (!_esDescargable(tipo)) continue;

      final descarga = await _descargaService.obtenerDescarga(
        libroId: libro.id,
        tipo: tipo,
        urlActual: _urlArchivo(tipo),
      );

      if (!mounted) return;

      setState(() {
        _descargas[tipo] = descarga;
      });
    }
  }


  // DESCARGAR (o actualizar) UN ARCHIVO
  Future<void> descargarArchivo(TipoArchivo tipo) async {
    final url = _urlArchivo(tipo);

    if (url == null) return;

    if (ConnectivityService.modoSinConexion.value) {
      _mostrarMensaje(
        'Activa la conexión (ícono de wifi) para descargar',
        Colors.orange,
      );
      return;
    }

    setState(() {
      _progreso[tipo] = 0;
    });

    try {
      final rutaLocal = await _descargaService.descargarArchivo(
        libroId: libro.id,
        tipo: tipo,
        url: url,
        onProgreso: (progreso) {
          if (!mounted) return;

          setState(() {
            _progreso[tipo] = progreso;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _descargas[tipo] = Descarga(
          rutaLocal: rutaLocal,
          desactualizada: false,
        );
      });

      _mostrarMensaje(
        tipo == TipoArchivo.pdf
            ? 'PDF disponible sin conexión'
            : 'Audiolibro disponible sin conexión',
        Colors.green,
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        e.toString().replaceFirst('Exception: ', ''),
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _progreso.remove(tipo);
        });
      }
    }
  }


  // ELIMINAR LA DESCARGA (libera espacio en el celular)
  Future<void> eliminarDescarga(TipoArchivo tipo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar descarga'),
        content: Text(
          tipo == TipoArchivo.pdf
              ? '¿Eliminar el PDF descargado? '
                  'Podrás leerlo en línea o descargarlo otra vez.'
              : '¿Eliminar el audiolibro descargado? '
                  'Podrás escucharlo en línea o descargarlo otra vez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await _descargaService.eliminarDescarga(
      libroId: libro.id,
      tipo: tipo,
    );

    if (!mounted) return;

    setState(() {
      _descargas[tipo] = null;
    });

    _mostrarMensaje('Descarga eliminada', Colors.green);
  }


  // LEER EL PDF O ESCUCHAR EL AUDIO
  // Orden de preferencia:
  // 1. Archivo descargado en el celular.
  // 2. URL de Cloudinary (si hay internet).
  // 3. Copia incluida en la app (si no hay internet).
  Future<void> abrirArchivo(TipoArchivo tipo) async {
    final descarga = _descargas[tipo];
    var ruta = descarga?.rutaLocal ?? _urlArchivo(tipo);

    if (ruta == null) return;

    if (ruta.startsWith('http')) {
      final sinInternet = ConnectivityService.modoSinConexion.value ||
          !await ConnectivityService().tieneConexion();

      if (!mounted) return;

      if (sinInternet) {
        final rutaIncluida = _rutaIncluida(tipo);

        if (rutaIncluida == null) {
          _mostrarMensaje(
            'Este archivo no está descargado. '
            'Descárgalo para usarlo sin conexión.',
            Colors.orange,
          );
          return;
        }

        ruta = rutaIncluida;
      }
    }

    final rutaFinal = ruta;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => tipo == TipoArchivo.pdf
            ? LectorPdfView(
                titulo: libro.titulo,
                rutaPdf: rutaFinal,
              )
            : ReproductorAudioView(
                titulo: libro.titulo,
                rutaAudio: rutaFinal,
              ),
      ),
    );
  }


  // Copia del archivo incluida en la app (mismo ISBN), si existe
  String? _rutaIncluida(TipoArchivo tipo) {
    final incluido = CatalogoInicial.buscarPorIsbn(libro.isbn);

    if (incluido == null) return null;

    return tipo == TipoArchivo.pdf
        ? incluido.rutaPdf
        : incluido.rutaAudio;
  }


  void _mostrarMensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,

      // Barra superior
      appBar: AppBar(
        title: const Text('Detalle del libro'),
        backgroundColor: AppColors.primario,
        foregroundColor: AppColors.tarjeta,
      ),

      // Contenido de la pantalla
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: AppColors.tarjeta,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,

                children: [
                  // Portada del libro
                  if (libro.tienePortada) ...[
                    Center(
                      child: PortadaLibroWidget(
                        rutaPortada: libro.rutaPortada,
                        ancho: 160,
                        alto: 240,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Título del libro
                  Text(
                    libro.titulo,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Información del libro
                  Text('Autor: ${libro.nombreAutor}'),
                  const SizedBox(height: 8),

                  Text('ISBN: ${libro.isbn}'),
                  const SizedBox(height: 8),

                  Text('Año: ${libro.anioPublicacion}'),
                  const SizedBox(height: 8),

                  Text('Stock: ${libro.stock}'),

                  const SizedBox(height: 25),

                  // PDF del libro
                  if (libro.tienePdf) ...[
                    _botonAbrir(
                      tipo: TipoArchivo.pdf,
                      icono: Icons.picture_as_pdf,
                      texto: 'Leer PDF',
                    ),
                    _controlDescarga(TipoArchivo.pdf),
                    const SizedBox(height: 16),
                  ],

                  // Audiolibro
                  if (libro.tieneAudio) ...[
                    _botonAbrir(
                      tipo: TipoArchivo.audio,
                      icono: Icons.headphones,
                      texto: 'Escuchar audiolibro',
                    ),
                    _controlDescarga(TipoArchivo.audio),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // Botón para leer el PDF o escuchar el audio
  Widget _botonAbrir({
    required TipoArchivo tipo,
    required IconData icono,
    required String texto,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icono),
        label: Text(texto),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primario,
          foregroundColor: AppColors.tarjeta,
          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
        ),
        onPressed: () => abrirArchivo(tipo),
      ),
    );
  }


  // Estado de la descarga debajo de cada botón
  Widget _controlDescarga(TipoArchivo tipo) {
    // Los archivos demo ya están dentro de la app
    if (!_esDescargable(tipo)) {
      return const SizedBox.shrink();
    }

    final progreso = _progreso[tipo];
    final descarga = _descargas[tipo];

    // 1. Descargando
    if (progreso != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: progreso > 0 ? progreso : null,
            ),
            const SizedBox(height: 4),
            Text(
              progreso > 0
                  ? 'Descargando... ${(progreso * 100).toStringAsFixed(0)} %'
                  : 'Descargando...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textoSecundario,
              ),
            ),
          ],
        ),
      );
    }

    // 2. No descargado
    if (descarga == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.download),
          label: const Text('Descargar para usar sin conexión'),
          onPressed: () => descargarArchivo(tipo),
        ),
      );
    }

    // 3. Descargado (al día o con versión nueva en el servidor)
    return Row(
      children: [
        Icon(
          descarga.desactualizada
              ? Icons.update
              : Icons.offline_pin,
          size: 20,
          color: descarga.desactualizada
              ? Colors.orange
              : AppColors.exito,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            descarga.desactualizada
                ? 'Hay una versión nueva'
                : 'Disponible sin conexión',
            style: TextStyle(
              color: descarga.desactualizada
                  ? Colors.orange
                  : AppColors.exito,
            ),
          ),
        ),
        if (descarga.desactualizada)
          TextButton(
            onPressed: () => descargarArchivo(tipo),
            child: const Text('Actualizar'),
          ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: AppColors.error,
          ),
          tooltip: 'Eliminar descarga',
          onPressed: () => eliminarDescarga(tipo),
        ),
      ],
    );
  }
}
