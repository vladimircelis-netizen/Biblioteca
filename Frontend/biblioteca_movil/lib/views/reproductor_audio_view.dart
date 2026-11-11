
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../config/app_colors.dart';

class ReproductorAudioView extends StatefulWidget {
  final String titulo;
  final String rutaAudio;

  const ReproductorAudioView({
    super.key,
    required this.titulo,
    required this.rutaAudio,
  });

  @override
  State<ReproductorAudioView> createState() =>
      _ReproductorAudioViewState();
}

class _ReproductorAudioViewState
    extends State<ReproductorAudioView> {

  final AudioPlayer _reproductor = AudioPlayer();

  bool cargando = true;
  String? errorAudio;

  @override
  void initState() {
    super.initState();
    cargarAudio();
  }

  Future<void> cargarAudio() async {
    try {
      // URL de Cloudinary, assets de la app (demo)
      // o archivo descargado en el celular
      if (widget.rutaAudio.startsWith('http')) {
        await _reproductor.setUrl(widget.rutaAudio);
      } else if (widget.rutaAudio.startsWith('assets/')) {
        await _reproductor.setAsset(widget.rutaAudio);
      } else {
        await _reproductor.setFilePath(widget.rutaAudio);
      }

      if (!mounted) return;

      setState(() {
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        errorAudio = 'No se pudo cargar el audio';
      });
    }
  }

  String formatearTiempo(Duration tiempo) {
    final minutos = tiempo.inMinutes.remainder(60);
    final segundos = tiempo.inSeconds.remainder(60);
    final horas = tiempo.inHours;

    final mm = minutos.toString().padLeft(2, '0');
    final ss = segundos.toString().padLeft(2, '0');

    if (horas > 0) {
      return '$horas:$mm:$ss';
    }

    return '$mm:$ss';
  }

  Future<void> moverAudio(int segundos) async {
    final posicion = _reproductor.position;
    final duracion = _reproductor.duration ?? Duration.zero;

    var nuevaPosicion =
        posicion + Duration(seconds: segundos);

    if (nuevaPosicion < Duration.zero) {
      nuevaPosicion = Duration.zero;
    }

    if (nuevaPosicion > duracion) {
      nuevaPosicion = duracion;
    }

    await _reproductor.seek(nuevaPosicion);
  }

  @override
  void dispose() {
    _reproductor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,

      appBar: AppBar(
        title: const Text('Audiolibro'),
        backgroundColor: AppColors.primario,
        foregroundColor: AppColors.tarjeta,
      ),

      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.headphones,
                  size: 100,
                ),

                const SizedBox(height: 25),

                Text(
                  widget.titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                if (cargando)
                  const CircularProgressIndicator()
                else if (errorAudio != null)
                  Text(errorAudio!)
                else ...[

                  // Barra de progreso
                  StreamBuilder<Duration>(
                    stream: _reproductor.positionStream,
                    builder: (context, snapshot) {
                      final posicion =
                          snapshot.data ?? Duration.zero;

                      final duracion =
                          _reproductor.duration ?? Duration.zero;

                      final maximo =
                          duracion.inMilliseconds.toDouble();

                      final valor = posicion.inMilliseconds
                          .toDouble()
                          .clamp(0.0, maximo > 0 ? maximo : 1.0);

                      return Column(
                        children: [
                          Slider(
                            min: 0,
                            max: maximo > 0 ? maximo : 1,
                            value: valor,
                            activeColor: AppColors.primario,
                            onChanged: maximo > 0
                                ? (valor) {
                                    _reproductor.seek(
                                      Duration(
                                        milliseconds: valor.toInt(),
                                      ),
                                    );
                                  }
                                : null,
                          ),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(formatearTiempo(posicion)),
                              Text(formatearTiempo(duracion)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Controles de reproducción
                  StreamBuilder<PlayerState>(
                    stream: _reproductor.playerStateStream,
                    builder: (context, snapshot) {
                      final reproduciendo =
                          snapshot.data?.playing ?? false;

                      final completado =
                          snapshot.data?.processingState ==
                          ProcessingState.completed;

                      return Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10),
                            iconSize: 45,
                            color: AppColors.primario,
                            onPressed: () => moverAudio(-10),
                          ),

                          const SizedBox(width: 15),

                          IconButton(
                            iconSize: 75,
                            color: AppColors.primario,
                            icon: Icon(
                              reproduciendo && !completado
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                            ),
                            onPressed: () async {
                              if (reproduciendo && !completado) {
                                await _reproductor.pause();
                              } else {
                                if (completado) {
                                  await _reproductor.seek(
                                    Duration.zero,
                                  );
                                }

                                await _reproductor.play();
                              }
                            },
                          ),

                          const SizedBox(width: 15),

                          IconButton(
                            icon: const Icon(Icons.forward_10),
                            iconSize: 45,
                            color: AppColors.primario,
                            onPressed: () => moverAudio(10),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Reproductor de audiolibros',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
