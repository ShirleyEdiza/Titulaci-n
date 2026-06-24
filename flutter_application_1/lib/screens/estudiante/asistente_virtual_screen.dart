import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/transcripcion_service.dart';

import '../../widgets/virtual_assistant_avatar.dart';
import '../../repositories/audio_repository.dart';
import '../../services/ia_service.dart';
import '../../services/analisis_service.dart';
import '../../repositories/analisis_repository.dart';
import '../../services/pronunciacion_service.dart';
import '../../repositories/pronunciacion_repository.dart';

class AsistenteVirtualScreen extends StatefulWidget {
  final String cursoId;
  final String nombreCurso;

  const AsistenteVirtualScreen({
    super.key,
    required this.cursoId,
    required this.nombreCurso,
  });

  @override
  State<AsistenteVirtualScreen> createState() => _AsistenteVirtualScreenState();
}

class _AsistenteVirtualScreenState extends State<AsistenteVirtualScreen>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final AudioRecorder _recorder = AudioRecorder();
  final TranscripcionService _transcripcionService = TranscripcionService();

  String? audioActualPath;

  final AudioRepository _audioRepository = AudioRepository();
  final IAService _iaService = IAService();
  final AnalisisService _analisisService = AnalisisService();
  final AnalisisRepository _analisisRepository = AnalisisRepository();
  final PronunciacionService _pronunciacionService = PronunciacionService();
  final PronunciacionRepository _pronunciacionRepository =
      PronunciacionRepository();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool iniciado = false;
  bool escuchando = false;
  bool guardando = false;

  String textoUsuario = "";
  String respuestaAsistente = "";
  String estadoMicrofono = "Micrófono detenido";

  String idiomaActual = "en_US";
  String nombreIdioma = "English";
  String nombreUsuario = "estudiante";
  bool procesandoRespuesta = false;

  List<String> historialUsuario = [];
  List<String> historialAsistente = [];
  List<String> respuestasIds = [];
  String? interaccionId;

  @override
  void initState() {
    super.initState();
    _configurarVoz();
    _cargarNombreUsuario();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.94,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _cargarNombreUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data()?['nombre'] != null) {
        setState(() {
          nombreUsuario = doc.data()!['nombre'].toString().split(" ").first;
        });
        return;
      }

      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (!mounted) return;

      if (query.docs.isNotEmpty) {
        setState(() {
          nombreUsuario =
              query.docs.first.data()['nombre'].toString().split(" ").first;
        });
      }
    } catch (e) {
      debugPrint("Error cargando nombre: $e");
    }
  }

  Future<void> _configurarVoz() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> iniciar() async {
    if (iniciado || guardando) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? "sin_uid";

    interaccionId = await _audioRepository.crearInteraccion(
      estudianteUid: uid,
      cursoId: widget.cursoId,
    );

    if (!mounted) return;

    setState(() {
      iniciado = true;
      escuchando = true;
      procesandoRespuesta = false;
      textoUsuario = "";
      respuestaAsistente = "";
      historialUsuario.clear();
      historialAsistente.clear();
      respuestasIds.clear();
      estadoMicrofono = "Habla con el asistente";
    });

    await _iniciarEscuchaContinua();
  }

  Future<void> _iniciarEscuchaContinua() async {
    if (!mounted || !iniciado || guardando || procesandoRespuesta) return;

    final dir = await getTemporaryDirectory();
    audioActualPath =
        "${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a";

    if (!mounted) return;

    setState(() {
      escuchando = true;
      estadoMicrofono = "Habla ahora...";
    });

    if (await _recorder.hasPermission()) {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: audioActualPath!,
      );
    } else {
      setState(() {
        escuchando = false;
        estadoMicrofono = "Permiso de micrófono denegado";
      });
      return;
    }

    await Future.delayed(const Duration(seconds: 7));

    if (!mounted || !iniciado || guardando || procesandoRespuesta) return;

    await _procesarAudioGrabadoConWhisper();
  }

  Future<void> _procesarResultadoVoz(result) async {
    String textoDetectado = result.recognizedWords.trim();

    if (mounted) {
      setState(() {
        textoUsuario = textoDetectado;
      });
    }

    if (!result.finalResult) return;

    String? audioFinalPath;

    try {
      if (await _recorder.isRecording()) {
        audioFinalPath = await _recorder.stop();
      }
    } catch (e) {
      debugPrint("Error deteniendo grabación: $e");
    }

    if (audioFinalPath != null && audioFinalPath.isNotEmpty) {
      final textoWhisper =
          await _transcripcionService.transcribirAudio(audioFinalPath);

      if (textoWhisper.trim().isNotEmpty) {
        textoDetectado = textoWhisper.trim();
      }
    }

    if (textoDetectado.isEmpty) {
      if (!mounted) return;

      setState(() {
        escuchando = false;
        estadoMicrofono = "No se detectó voz";
      });

      if (iniciado) {
        await Future.delayed(const Duration(milliseconds: 700));

        if (!mounted) return;

        setState(() {
          escuchando = true;
          estadoMicrofono = "Habla con el asistente";
        });

        await _iniciarEscuchaContinua();
      }

      return;
    }

    await _procesarTextoFinal(textoDetectado);
  }

  Future<void> salirSinGuardar() async {
    iniciado = false;
    guardando = true;
    escuchando = false;
    procesandoRespuesta = false;

    await _speech.stop();
    await _tts.stop();

    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (e) {
      debugPrint("Error deteniendo grabación al salir: $e");
    }

    if (!mounted) return;

    setState(() {
      interaccionId = null;
      estadoMicrofono = "Micrófono detenido";
    });

    Navigator.pop(context);
  }

  Future<void> _procesarAudioGrabadoConWhisper() async {
    if (procesandoRespuesta || guardando || !iniciado) return;

    String? audioFinalPath;

    try {
      if (await _recorder.isRecording()) {
        audioFinalPath = await _recorder.stop();
      }
    } catch (e) {
      debugPrint("Error deteniendo grabación en Whisper: $e");
    }

    if (audioFinalPath == null || audioFinalPath.isEmpty) {
      if (!mounted) return;
      setState(() {
        escuchando = false;
        estadoMicrofono = "No se detectó audio. Intenta nuevamente.";
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      escuchando = false;
      procesandoRespuesta = true;
      estadoMicrofono = "Transcribiendo audio...";
    });

    final textoWhisper =
        await _transcripcionService.transcribirAudio(audioFinalPath);

    final textoDetectado = textoWhisper.trim();

    if (textoDetectado.isEmpty) {
      if (!mounted) return;
      setState(() {
        procesandoRespuesta = false;
        escuchando = true;
        estadoMicrofono = "No se pudo transcribir. Intenta nuevamente.";
      });

      await Future.delayed(const Duration(milliseconds: 700));
      await _iniciarEscuchaContinua();
      return;
    }

    await _procesarTextoFinal(textoDetectado);
  }

  Future<void> _procesarTextoFinal(String textoDetectado) async {
    if (!mounted) return;

    setState(() {
      textoUsuario = textoDetectado;
      escuchando = false;
      procesandoRespuesta = true;
      estadoMicrofono = "Procesando respuesta...";
    });

    await _speech.stop();

    final respuesta = await _iaService.enviarMensaje(
      textoDetectado,
      historialUsuario: historialUsuario,
      historialAsistente: historialAsistente,
    );

    final uid = FirebaseAuth.instance.currentUser?.uid ?? "sin_uid";

    final textoLower = textoDetectado.toLowerCase();

    final idiomaDetectado = textoLower.contains("hola") ||
            textoLower.contains("gracias") ||
            textoLower.contains("buenos") ||
            textoLower.contains("adiós") ||
            textoDetectado.contains(RegExp(r'[áéíóúñ¿¡]'))
        ? "es"
        : "en";

    if (interaccionId != null) {
      final respuestaId = await _audioRepository.guardarRespuesta(
        interaccionId: interaccionId!,
        estudianteUid: uid,
        cursoId: widget.cursoId,
        textoUsuario: textoDetectado,
        respuestaAsistente: respuesta,
        audioUrl: "",
        idiomaDetectado: idiomaDetectado,
      );

      respuestasIds.add(respuestaId);
    }

    historialUsuario.add(textoDetectado);
    historialAsistente.add(respuesta);

    if (!mounted) return;
    setState(() {
      respuestaAsistente = respuesta;
      estadoMicrofono = "Respuesta generada";
    });

    final tieneEspanol = RegExp(
      r'[áéíóúñ¿¡]|hola|gracias|español|entiendo|claro|pregunta',
      caseSensitive: false,
    ).hasMatch(respuesta);

    if (tieneEspanol) {
      await _tts.setLanguage("es-ES");
    } else {
      await _tts.setLanguage("en-US");
    }

    await _tts.speak(respuesta);

    if (!mounted) return;
    setState(() {
      procesandoRespuesta = false;
    });

    if (iniciado && !guardando) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        escuchando = true;
        estadoMicrofono = "Habla con el asistente";
      });
      await _iniciarEscuchaContinua();
    }
  }

  Future<void> terminar() async {
    if (!mounted) return;

    setState(() {
      guardando = true;
      escuchando = false;
      estadoMicrofono = "Finalizando interacción...";
    });

    try {
      await _speech.stop();
      await _tts.stop();

      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      if (historialUsuario.isNotEmpty &&
          respuestasIds.isNotEmpty &&
          interaccionId != null) {
        final textoCompleto = historialUsuario.join(". ");

        final resultado = await _analisisService.analizarTexto(
          textoCompleto,
        );

        final textoReferencia = resultado["texto_corregido"] ?? textoCompleto;

        final resultadoPronunciacion =
            await _pronunciacionService.analizarPronunciacion(
          textoReconocido: textoCompleto,
          textoReferencia: textoReferencia,
        );

        final puntuacionPronunciacion =
            (resultadoPronunciacion['puntuacion_pronunciacion'] ?? 0)
                .toDouble();

        await _analisisRepository.guardarAnalisis(
          respuestaId: respuestasIds.last,
          interaccionId: interaccionId!,
          estudianteUid: FirebaseAuth.instance.currentUser?.uid ?? "sin_uid",
          cursoId: widget.cursoId,
          textoOriginal: textoCompleto,
          resultado: resultado,
          totalRespuestas: respuestasIds.length,
          puntuacionPronunciacion: puntuacionPronunciacion,
        );

        await _analisisRepository.guardarFeedback(
          interaccionId: interaccionId!,
          estudianteUid: FirebaseAuth.instance.currentUser?.uid ?? "sin_uid",
          cursoId: widget.cursoId,
          comentario: resultado["comentario"] ?? "",
          sugerencias: resultado["sugerencias"] ?? [],
          puntosFuertes: resultado["puntos_fuertes"] ?? [],
        );

        await _pronunciacionRepository.guardarPronunciacion(
          interaccionId: interaccionId!,
          estudianteUid: FirebaseAuth.instance.currentUser?.uid ?? "sin_uid",
          cursoId: widget.cursoId,
          textoReconocido: textoCompleto,
          textoReferencia: textoReferencia,
          resultado: resultadoPronunciacion,
        );
      }

      if (interaccionId != null) {
        await _audioRepository.finalizarInteraccion(
          interaccionId: interaccionId!,
        );
      }

      setState(() {
        iniciado = false;
        escuchando = false;
        procesandoRespuesta = false;
        guardando = false;
        interaccionId = null;
        estadoMicrofono = "Interacción finalizada";
        respuestaAsistente = "";
        respuestasIds.clear();
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              "Retroalimentación generada",
              style: TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              "Tu interacción fue guardada correctamente. Puedes revisar tu retroalimentación escrita u oral.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();

                  Navigator.of(this.context).pop();
                },
                child: const Text("Cerrar"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();

                  Navigator.of(this.context).pop(
                    "ver_retro_escrita",
                  );
                },
                icon: const Icon(Icons.edit_note),
                label: const Text("Escrita"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();

                  Navigator.of(this.context).pop(
                    "ver_retro_oral",
                  );
                },
                icon: const Icon(Icons.record_voice_over),
                label: const Text("Oral"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        guardando = false;
        estadoMicrofono = "Error al finalizar";
      });

      _mostrarMensaje(
        "Error al finalizar: $e",
        Colors.red,
      );
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
  void dispose() {
    iniciado = false;
    guardando = true;
    escuchando = false;
    procesandoRespuesta = false;

    _speech.stop();
    _tts.stop();

    _recorder.isRecording().then((grabando) {
      if (grabando) {
        _recorder.stop();
      }
    }).catchError((e) {
      debugPrint("Error cerrando recorder: $e");
    });

    _pulseController.dispose();
    _recorder.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF253A9B),
              Color(0xFFEFF3FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  "Tu asistente virtual",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: escuchando ? _pulseAnimation.value : 1,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 235,
                            height: 235,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                              boxShadow: [
                                BoxShadow(
                                  color: escuchando
                                      ? const Color(0xFF64B5F6).withOpacity(0.8)
                                      : const Color(0xFF1A237E)
                                          .withOpacity(0.5),
                                  blurRadius: escuchando ? 55 : 35,
                                  spreadRadius: escuchando ? 8 : 3,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 205,
                            height: 205,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: escuchando
                                    ? const Color(0xFF64B5F6)
                                    : Colors.white.withOpacity(0.35),
                                width: 3,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 145,
                            height: 145,
                            child: const VirtualAssistantAvatar(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                Text(
                  "¡Pregunta lo que quieras, $nombreUsuario!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _botonCircular(
                      icon: Icons.close,
                      label: "Salir",
                      color: const Color(0xFF757575),
                      onTap: guardando ? null : salirSinGuardar,
                    ),
                    _botonCircular(
                      icon: Icons.mic,
                      label: "",
                      color: const Color(0xFF1A237E),
                      onTap: iniciado || guardando ? null : iniciar,
                    ),
                    _botonCircular(
                      icon: guardando ? Icons.hourglass_bottom : Icons.stop,
                      label: guardando ? "Guardando" : "Finalizar",
                      color: const Color(0xFFB71C1C),
                      onTap: iniciado && !guardando ? terminar : null,
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

  Widget _botonCircular({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final activo = onTap != null;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: activo ? color : Colors.grey.shade500,
              shape: BoxShape.circle,
              boxShadow: activo
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.45),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: activo ? const Color(0xFF1A237E) : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
