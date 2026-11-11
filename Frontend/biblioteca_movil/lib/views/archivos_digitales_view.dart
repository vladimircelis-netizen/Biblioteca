
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../controllers/libro_controller.dart';
import '../models/libro.dart';
import '../models/tipo_archivo.dart';
import '../widgets/portada_libro_widget.dart';
import 'archivos_libro_view.dart';

class ArchivosDigitalesView extends StatefulWidget {
  final String token;

  const ArchivosDigitalesView({
    super.key,
    required this.token,
  });

  @override
  State<ArchivosDigitalesView> createState() =>
      _ArchivosDigitalesViewState();
}

class _ArchivosDigitalesViewState
    extends State<ArchivosDigitalesView> {

  final LibroController _controller = LibroController();

  late Future<List<Libro>> _libros;

  // true: solo libros sin portada, PDF o audio
  bool _soloIncompletos = true;

  String textoBusqueda = '';

  @override
  void initState() {
    super.initState();
    _libros = _controller.listarLibrosServidor();
  }

  // Actualizar la lista de libros
  void actualizarLibros() {
    setState(() {
      _libros = _controller.listarLibrosServidor();
    });
  }

  Future<void> abrirArchivosLibro(Libro libro) async {
    final huboCambios = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ArchivosLibroView(
          libro: libro,
          token: widget.token,
        ),
      ),
    );

    if (!mounted) return;

    if (huboCambios == true) {
      actualizarLibros();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,

      appBar: AppBar(
        title: const Text('Archivos digitales'),
        backgroundColor: AppColors.primario,
        foregroundColor: AppColors.tarjeta,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar libros',
            onPressed: actualizarLibros,
          ),
        ],
      ),

      body: Column(
        children: [
          // Buscar por título
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar libro por título...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.tarjeta,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (valor) {
                setState(() {
                  textoBusqueda = valor;
                });
              },
            ),
          ),

          // Filtro: incompletos / todos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Incompletos'),
                  selected: _soloIncompletos,
                  onSelected: (_) {
                    setState(() {
                      _soloIncompletos = true;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: !_soloIncompletos,
                  onSelected: (_) {
                    setState(() {
                      _soloIncompletos = false;
                    });
                  },
                ),
              ],
            ),
          ),

          // Lista de libros
          Expanded(
            child: FutureBuilder<List<Libro>>(
              future: _libros,
              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Esta pantalla necesita la API (no usa SQLite)
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            size: 60,
                            color: AppColors.textoSecundario,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No se pudo conectar con el servidor.\n'
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: actualizarLibros,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final libros = snapshot.data ?? [];

                final librosFiltrados = libros.where((libro) {
                  if (_soloIncompletos && libro.archivosCompletos) {
                    return false;
                  }

                  return libro.titulo.toLowerCase().contains(
                    textoBusqueda.toLowerCase().trim(),
                  );
                }).toList();

                if (librosFiltrados.isEmpty) {
                  return Center(
                    child: Text(
                      _soloIncompletos && textoBusqueda.isEmpty
                          ? 'Todos los libros tienen sus archivos completos'
                          : 'No se encontraron libros',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: librosFiltrados.length,
                  itemBuilder: (context, index) {

                    final libro = librosFiltrados[index];

                    return Card(
                      color: AppColors.tarjeta,
                      margin: const EdgeInsets.only(bottom: 12),

                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),

                        leading: PortadaLibroWidget(
                          rutaPortada: libro.rutaPortada,
                          ancho: 45,
                          alto: 65,
                        ),

                        title: Text(libro.titulo),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Autor: ${libro.nombreAutor}'),
                            const SizedBox(height: 6),

                            // Estado de cada archivo
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _estadoArchivo(
                                  TipoArchivo.portada,
                                  'Portada',
                                  libro.tienePortada,
                                ),
                                _estadoArchivo(
                                  TipoArchivo.pdf,
                                  'PDF',
                                  libro.tienePdf,
                                ),
                                _estadoArchivo(
                                  TipoArchivo.audio,
                                  'Audio',
                                  libro.tieneAudio,
                                ),
                              ],
                            ),
                          ],
                        ),

                        trailing: const Icon(Icons.chevron_right),

                        onTap: () => abrirArchivosLibro(libro),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Etiqueta verde (tiene el archivo) o gris (le falta)
  Widget _estadoArchivo(
    TipoArchivo tipo,
    String texto,
    bool tieneArchivo,
  ) {
    final color =
        tieneArchivo ? AppColors.exito : AppColors.textoSecundario;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tieneArchivo ? Icons.check : Icons.close,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}
