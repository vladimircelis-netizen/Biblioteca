
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_colors.dart';
import '../models/tipo_archivo.dart';
import 'portada_libro_widget.dart';

// De dónde se obtiene la portada
enum _OrigenPortada { camara, galeria, archivo }

// Abrir el selector de archivos del dispositivo.
// Para la portada también se puede usar la cámara o la galería.
// Valida la extensión y el tamaño máximo antes de devolver el archivo.
Future<PlatformFile?> seleccionarArchivo(
  BuildContext context,
  TipoArchivo tipo,
) async {
  PlatformFile? archivo;

  if (tipo == TipoArchivo.portada) {
    final origen = await _elegirOrigenPortada(context);

    if (origen == null || !context.mounted) return null;

    if (origen == _OrigenPortada.camara) {
      archivo = await _obtenerFoto(context, ImageSource.camera);
    } else if (origen == _OrigenPortada.galeria) {
      archivo = await _obtenerFoto(context, ImageSource.gallery);
    } else {
      archivo = await _buscarArchivo(tipo);
    }
  } else {
    archivo = await _buscarArchivo(tipo);
  }

  if (archivo == null || !context.mounted) return null;

  // Validar la extensión
  final extension = (archivo.extension ?? '').toLowerCase();

  if (!tipo.extensiones.contains(extension)) {
    _mostrarError(
      context,
      'Formato no permitido. Usa: ${tipo.extensiones.join(', ')}',
    );
    return null;
  }

  // Validar el tamaño
  final tamano = await archivo.length() ?? 0;

  if (!context.mounted) return null;

  if (tamano > tipo.tamanoMaximoBytes) {
    _mostrarError(
      context,
      '${tipo.nombre} no puede superar los ${tipo.tamanoMaximoMb} MB',
    );
    return null;
  }

  return archivo;
}

// Buscar el archivo en el almacenamiento del celular
Future<PlatformFile?> _buscarArchivo(TipoArchivo tipo) {
  return FilePicker.pickFile(
    dialogTitle: 'Seleccionar ${tipo.nombre.toLowerCase()}',
    type: FileType.custom,
    allowedExtensions: tipo.extensiones,
  );
}


// Menú para elegir de dónde sacar la portada
Future<_OrigenPortada?> _elegirOrigenPortada(BuildContext context) {
  return showModalBottomSheet<_OrigenPortada>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Portada del libro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.photo_camera,
              color: AppColors.primario,
            ),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(context, _OrigenPortada.camara),
          ),
          ListTile(
            leading: const Icon(
              Icons.photo_library,
              color: AppColors.primario,
            ),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(context, _OrigenPortada.galeria),
          ),
          ListTile(
            leading: const Icon(
              Icons.folder_open,
              color: AppColors.primario,
            ),
            title: const Text('Buscar archivo'),
            onTap: () => Navigator.pop(context, _OrigenPortada.archivo),
          ),
        ],
      ),
    ),
  );
}


// Tomar una foto con la cámara o elegirla de la galería.
// La imagen se reduce y se guarda como JPG para no superar
// el tamaño máximo de la portada (5 MB) y subir más rápido.
Future<PlatformFile?> _obtenerFoto(
  BuildContext context,
  ImageSource origen,
) async {
  try {
    final foto = await ImagePicker().pickImage(
      source: origen,
      maxWidth: 1200,
      maxHeight: 1800,
      imageQuality: 85,
    );

    if (foto == null) return null;

    return _FotoPortada(foto);
  } on PlatformException catch (e) {
    debugPrint('Error con la cámara o la galería: $e');

    if (context.mounted) {
      _mostrarError(
        context,
        origen == ImageSource.camera
            ? 'No se pudo abrir la cámara. Revisa el permiso de cámara.'
            : 'No se pudo abrir la galería.',
      );
    }

    return null;
  }
}


// Foto de la cámara o la galería presentada como PlatformFile,
// el mismo tipo que devuelve el selector de archivos.
// Así el resto de la app (vista previa y subida a Cloudinary)
// funciona igual sin importar de dónde vino la imagen.
final class _FotoPortada extends PlatformFile {
  final XFile foto;

  _FotoPortada(this.foto);

  @override
  String get name {
    // Asegurar que el nombre tenga extensión (la API valida el tipo)
    return foto.name.contains('.') ? foto.name : '${foto.name}.jpg';
  }

  @override
  Uri get uri => Uri.file(foto.path);

  @override
  XFile get xFile => foto;

  @override
  int? lengthSync() => null;

  @override
  Future<int?> length() async => await foto.length();

  @override
  Future<Uint8List> readAsBytes() => foto.readAsBytes();

  @override
  Stream<Uint8List> readAsByteStream() => foto.openRead();
}


void _mostrarError(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensaje),
      backgroundColor: AppColors.error,
    ),
  );
}


// Tarjeta para elegir la portada, el PDF o el audio de un libro
// en los formularios de registrar y editar.
class SelectorArchivoWidget extends StatelessWidget {
  final TipoArchivo tipo;

  // Archivo que ya está guardado en Cloudinary (al editar)
  final String? rutaActual;

  // Archivo nuevo elegido en el dispositivo
  final PlatformFile? archivoSeleccionado;

  // El archivo actual se eliminará al guardar
  final bool marcadoParaEliminar;

  final bool habilitado;
  final VoidCallback onSeleccionar;
  final VoidCallback onQuitarSeleccion;

  // Solo se muestra si hay un archivo actual
  final VoidCallback? onEliminarActual;

  const SelectorArchivoWidget({
    super.key,
    required this.tipo,
    required this.archivoSeleccionado,
    required this.onSeleccionar,
    required this.onQuitarSeleccion,
    this.rutaActual,
    this.marcadoParaEliminar = false,
    this.habilitado = true,
    this.onEliminarActual,
  });

  bool get _tieneActual => rutaActual?.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.tarjeta,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: _vistaPrevia(),
        title: Text(tipo.nombre),
        subtitle: Text(
          _descripcion(),
          style: TextStyle(
            color: marcadoParaEliminar && archivoSeleccionado == null
                ? AppColors.error
                : AppColors.textoSecundario,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quitar el archivo elegido o deshacer la eliminación
            if (archivoSeleccionado != null || marcadoParaEliminar)
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Deshacer',
                onPressed: habilitado ? onQuitarSeleccion : null,
              ),

            // Elegir un archivo nuevo
            IconButton(
              icon: Icon(
                Icons.upload_file,
                color: habilitado ? AppColors.primario : null,
              ),
              tooltip: _tieneActual ? 'Reemplazar' : 'Seleccionar',
              onPressed: habilitado ? onSeleccionar : null,
            ),

            // Eliminar el archivo guardado
            if (_tieneActual &&
                onEliminarActual != null &&
                archivoSeleccionado == null &&
                !marcadoParaEliminar)
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: habilitado ? AppColors.error : null,
                ),
                tooltip: 'Eliminar archivo',
                onPressed: habilitado ? onEliminarActual : null,
              ),
          ],
        ),
      ),
    );
  }

  String _descripcion() {
    final archivo = archivoSeleccionado;

    if (archivo != null) {
      return _tieneActual
          ? 'Reemplazar por: ${archivo.name}'
          : 'Nuevo: ${archivo.name}';
    }

    if (marcadoParaEliminar) {
      return 'Se eliminará al guardar';
    }

    if (_tieneActual) {
      return 'Archivo guardado en la nube';
    }

    return 'Sin archivo (máx. ${tipo.tamanoMaximoMb} MB)';
  }

  Widget _vistaPrevia() {
    final archivo = archivoSeleccionado;

    // Vista previa de la imagen elegida en el dispositivo
    if (tipo == TipoArchivo.portada &&
        archivo != null &&
        archivo.path != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(archivo.path!),
          width: 40,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(tipo.icono, color: AppColors.primario);
          },
        ),
      );
    }

    // Vista previa de la portada guardada en Cloudinary
    if (tipo == TipoArchivo.portada &&
        _tieneActual &&
        !marcadoParaEliminar) {
      return PortadaLibroWidget(
        rutaPortada: rutaActual,
        ancho: 40,
        alto: 56,
      );
    }

    final tieneArchivo =
        archivo != null || (_tieneActual && !marcadoParaEliminar);

    return Icon(
      tipo.icono,
      color: tieneArchivo ? AppColors.exito : AppColors.textoSecundario,
      size: 32,
    );
  }
}
