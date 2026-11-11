
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/libro.dart';
import '../models/tipo_archivo.dart';
import '../services/archivo_service.dart';
import '../widgets/portada_libro_widget.dart';
import '../widgets/selector_archivo_widget.dart';
import 'lector_pdf_view.dart';
import 'reproductor_audio_view.dart';

// Agregar, ver, reemplazar y eliminar la portada,
// el PDF y el audio de un libro.
// Cada acción se guarda inmediatamente en Cloudinary y MySQL.
class ArchivosLibroView extends StatefulWidget {
  final Libro libro;
  final String token;

  const ArchivosLibroView({
    super.key,
    required this.libro,
    required this.token,
  });

  @override
  State<ArchivosLibroView> createState() => _ArchivosLibroViewState();
}

class _ArchivosLibroViewState extends State<ArchivosLibroView> {
  final ArchivoService _archivoService = ArchivoService();

  // Rutas actuales de cada archivo (URL de Cloudinary o null)
  late final Map<TipoArchivo, String?> _rutas;

  // Archivo que se está subiendo o eliminando
  TipoArchivo? _procesando;

  // Para avisar a la pantalla anterior que recargue la lista
  bool _huboCambios = false;

  @override
  void initState() {
    super.initState();

    _rutas = {
      TipoArchivo.portada: widget.libro.rutaPortada,
      TipoArchivo.pdf: widget.libro.rutaPdf,
      TipoArchivo.audio: widget.libro.rutaAudio,
    };
  }

  bool _tieneArchivo(TipoArchivo tipo) =>
      _rutas[tipo]?.isNotEmpty ?? false;


  // AGREGAR O REEMPLAZAR
  Future<void> subirArchivo(TipoArchivo tipo) async {
    final archivo = await seleccionarArchivo(context, tipo);

    if (archivo == null || !mounted) return;

    setState(() {
      _procesando = tipo;
    });

    try {
      final url = await _archivoService.subirArchivo(
        libroId: widget.libro.id,
        tipo: tipo,
        archivo: archivo,
        token: widget.token,
      );

      if (!mounted) return;

      final reemplazado = _tieneArchivo(tipo);

      setState(() {
        _rutas[tipo] = url;
        _huboCambios = true;
      });

      _mostrarMensaje(
        reemplazado
            ? '${tipo.nombre} reemplazado correctamente'
            : '${tipo.nombre} agregado correctamente',
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
          _procesando = null;
        });
      }
    }
  }


  // ELIMINAR
  Future<void> eliminarArchivo(TipoArchivo tipo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar ${tipo.nombre.toLowerCase()}'),
        content: Text(
          '¿Estás seguro de eliminar ${tipo.nombre.toLowerCase()} '
          'de "${widget.libro.titulo}"? '
          'El archivo se borrará de la nube.',
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

    setState(() {
      _procesando = tipo;
    });

    try {
      await _archivoService.eliminarArchivo(
        libroId: widget.libro.id,
        tipo: tipo,
        token: widget.token,
      );

      if (!mounted) return;

      setState(() {
        _rutas[tipo] = null;
        _huboCambios = true;
      });

      _mostrarMensaje(
        '${tipo.nombre} eliminado correctamente',
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
          _procesando = null;
        });
      }
    }
  }


  // VER EL ARCHIVO
  void verArchivo(TipoArchivo tipo) {
    final ruta = _rutas[tipo];

    if (ruta == null) return;

    switch (tipo) {
      case TipoArchivo.portada:
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: PortadaLibroWidget(
                rutaPortada: ruta,
                ancho: 260,
                alto: 390,
              ),
            ),
          ),
        );
        break;

      case TipoArchivo.pdf:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LectorPdfView(
              titulo: widget.libro.titulo,
              rutaPdf: ruta,
            ),
          ),
        );
        break;

      case TipoArchivo.audio:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReproductorAudioView(
              titulo: widget.libro.titulo,
              rutaAudio: ruta,
            ),
          ),
        );
        break;
    }
  }


  void _mostrarMensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      // Al volver, avisar si hubo cambios
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _huboCambios);
      },

      child: Scaffold(
        backgroundColor: AppColors.fondo,

        appBar: AppBar(
          title: const Text('Archivos del libro'),
          backgroundColor: AppColors.primario,
          foregroundColor: AppColors.tarjeta,
        ),

        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Datos del libro
            Row(
              children: [
                PortadaLibroWidget(
                  rutaPortada: _rutas[TipoArchivo.portada],
                  ancho: 70,
                  alto: 105,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.libro.titulo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Autor: ${widget.libro.nombreAutor}'),
                      Text('ISBN: ${widget.libro.isbn}'),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            for (final tipo in TipoArchivo.values) _tarjetaArchivo(tipo),
          ],
        ),
      ),
    );
  }


  Widget _tarjetaArchivo(TipoArchivo tipo) {
    final tieneArchivo = _tieneArchivo(tipo);
    final procesandoEste = _procesando == tipo;
    final habilitado = _procesando == null;

    return Card(
      color: AppColors.tarjeta,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  tipo.icono,
                  size: 32,
                  color: tieneArchivo
                      ? AppColors.exito
                      : AppColors.textoSecundario,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipo.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tieneArchivo
                            ? 'Archivo guardado en la nube'
                            : 'Sin archivo · ${tipo.extensiones.join(', ')}'
                              ' · máx. ${tipo.tamanoMaximoMb} MB',
                        style: const TextStyle(
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (procesandoEste)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              )
            else
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                children: [
                  if (tieneArchivo)
                    TextButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('Ver'),
                      onPressed:
                          habilitado ? () => verArchivo(tipo) : null,
                    ),

                  TextButton.icon(
                    icon: Icon(
                      tieneArchivo ? Icons.sync : Icons.upload_file,
                    ),
                    label: Text(tieneArchivo ? 'Reemplazar' : 'Agregar'),
                    onPressed:
                        habilitado ? () => subirArchivo(tipo) : null,
                  ),

                  if (tieneArchivo)
                    TextButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Eliminar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      onPressed:
                          habilitado ? () => eliminarArchivo(tipo) : null,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
