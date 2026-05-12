import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/virtual_assistant_avatar.dart';
import '../../services/audio_service.dart';
import '../../repositories/audio_repository.dart';
import '../../services/ia_service.dart';

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

class _AsistenteVirtualScreenState extends State<AsistenteVirtualScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  final AudioService _audioService = AudioService();
  final AudioRepository _audioRepository = AudioRepository();
  final IAService _iaService = IAService();
  bool iniciado = false;
  bool escuchando = false;
  bool guardando = false;

  String textoUsuario = "";
  String respuestaAsistente =
      "Press start and speak in English with the assistant.";
  String estadoMicrofono = "Micrófono detenido";
  String idiomaActual = "en_US";
  String nombreIdioma = "English";

  String? rutaAudio;

  @override
  void initState() {
    super.initState();
    _configurarVoz();
  }

  Future<void> _configurarVoz() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  Future<void> iniciar() async {
    final disponible = await _speech.initialize(
      onStatus: (status) {
        debugPrint("STATUS SPEECH: $status");
      },
      onError: (error) {
        debugPrint("ERROR SPEECH: ${error.errorMsg}");

        if (error.errorMsg == 'error_speech_timeout' ||
            error.errorMsg == 'error_no_match') {
          setState(() {
            escuchando = false;
            estadoMicrofono = "No se detectó voz. Presiona continuar.";
          });
          return;
        }

        _mostrarMensaje(
          "Error de micrófono: ${error.errorMsg}",
          Colors.red,
        );
      },
    );

    if (!disponible) {
      _mostrarMensaje(
        "No se pudo activar el reconocimiento de voz",
        Colors.red,
      );
      return;
    }

    setState(() {
      iniciado = true;
      escuchando = true;
      textoUsuario = "";
      respuestaAsistente = "Listening...";
      estadoMicrofono = idiomaActual == "en_US"
          ? "Habla ahora en inglés"
          : "Habla ahora en español";
    });

    await _speech.listen(
      localeId: idiomaActual,
      listenMode: stt.ListenMode.dictation,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 8),
      partialResults: true,
      cancelOnError: false,
      onResult: (result) async {
        setState(() {
          textoUsuario = result.recognizedWords;
        });

        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          setState(() {
            respuestaAsistente = "Thinking...";
            estadoMicrofono = "Procesando respuesta...";
            escuchando = false;
          });

          final respuesta = await _iaService.enviarMensaje(
            result.recognizedWords,
          );

          setState(() {
            respuestaAsistente = respuesta;
            estadoMicrofono = "Respuesta generada";
          });

          await _tts.speak(respuesta);
        }
      },
    );
  }

  Future<void> pausar() async {
    await _speech.stop();

    setState(() {
      escuchando = false;
      estadoMicrofono = "Interacción pausada";
    });
  }

  Future<void> continuar() async {
    if (!iniciado) return;

    setState(() {
      textoUsuario = "";
      respuestaAsistente = "Listening...";
      escuchando = true;
      estadoMicrofono = idiomaActual == "en_US"
          ? "Habla ahora en inglés"
          : "Habla ahora en español";
    });

    await _speech.stop();

    await Future.delayed(const Duration(milliseconds: 500));

    await _speech.listen(
      localeId: idiomaActual,
      listenMode: stt.ListenMode.dictation,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 8),
      partialResults: true,
      cancelOnError: false,
      onResult: (result) async {
        setState(() {
          textoUsuario = result.recognizedWords;
        });

        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          setState(() {
            respuestaAsistente = "Thinking...";
            estadoMicrofono = "Procesando respuesta...";
            escuchando = false;
          });

          final respuesta = await _iaService.enviarMensaje(
            result.recognizedWords,
          );

          setState(() {
            respuestaAsistente = respuesta;
            estadoMicrofono = "Respuesta generada";
          });

          await _tts.speak(respuesta);
        }
      },
    );
  }

  Future<void> terminar() async {
    setState(() {
      guardando = true;
      estadoMicrofono = "Finalizando interacción...";
    });

    try {
      await _speech.stop();
      await _tts.stop();

      final uid = FirebaseAuth.instance.currentUser?.uid ?? "sin_uid";

      await _audioRepository.guardarRespuesta(
        estudianteUid: uid,
        textoUsuario:
            textoUsuario.isEmpty ? "Sin texto detectado" : textoUsuario,
        respuestaAsistente: respuestaAsistente,
        audioUrl: "",
      );

      setState(() {
        iniciado = false;
        escuchando = false;
        guardando = false;
        estadoMicrofono = "Interacción finalizada";
        respuestaAsistente = "Interaction finished.";
      });

      _mostrarMensaje(
        "Interacción finalizada correctamente",
        Colors.green,
      );
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

  void _mostrarMensaje(
    String mensaje,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = !iniciado
        ? "Presiona iniciar para comenzar"
        : escuchando
            ? "Habla en inglés, el asistente te escucha"
            : estadoMicrofono;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Asistente virtual",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.nombreCurso,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const VirtualAssistantAvatar(),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      0.06,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Practice your speaking",
                    style: TextStyle(
                      color: Color(0xFF1A237E),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    estado,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: escuchando ? Colors.red : Colors.grey,
                      fontSize: 13,
                      fontWeight:
                          escuchando ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text("🇺🇸 English"),
                        selected: idiomaActual == "en_US",
                        onSelected: escuchando
                            ? null
                            : (selected) {
                                setState(() {
                                  idiomaActual = "en_US";
                                  nombreIdioma = "English";
                                });
                              },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text("🇪🇸 Español"),
                        selected: idiomaActual == "es_ES",
                        onSelected: escuchando
                            ? null
                            : (selected) {
                                setState(() {
                                  idiomaActual = "es_ES";
                                  nombreIdioma = "Español";
                                });
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Idioma de escucha: $nombreIdioma",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Icon(
                    escuchando ? Icons.mic : Icons.mic_none,
                    size: 55,
                    color: escuchando ? Colors.red : const Color(0xFF1A237E),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF1A237E,
                      ).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                    child: Text(
                      "Tú dijiste: ${textoUsuario.isEmpty ? '...' : textoUsuario}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      "Asistente: $respuestaAsistente",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: iniciado || guardando ? null : iniciar,
                    icon: const Icon(
                      Icons.play_arrow,
                    ),
                    label: const Text("Iniciar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: iniciado && !guardando
                        ? escuchando
                            ? pausar
                            : continuar
                        : null,
                    icon: Icon(
                      escuchando ? Icons.pause : Icons.play_circle,
                    ),
                    label: Text(
                      escuchando ? "Pausar" : "Continuar",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9A825),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: iniciado && !guardando ? terminar : null,
              icon: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.stop),
              label: Text(
                guardando ? "Guardando..." : "Terminar interacción",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
