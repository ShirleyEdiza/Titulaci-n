import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';

class RetroalimentacionOralScreen extends StatefulWidget {
  final String cursoId;

  const RetroalimentacionOralScreen({
    super.key,
    required this.cursoId,
  });

  @override
  State<RetroalimentacionOralScreen> createState() =>
      _RetroalimentacionOralScreenState();
}

class _RetroalimentacionOralScreenState
    extends State<RetroalimentacionOralScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _configurarTts();
  }

  Future<void> _configurarTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
  }

  Future<void> _reproducir(String palabra) async {
    await _tts.stop();
    await _tts.setLanguage("en-US");
    await _tts.speak(palabra);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text("No hay usuario autenticado"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pronunciacion')
          .where('estudiante_uid', isEqualTo: uid)
          .where('curso_id', isEqualTo: widget.cursoId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("Error al cargar la retroalimentación oral"),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                "Aún no tienes retroalimentación oral.\nRealiza una interacción y presiona Finalizar.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ),
          );
        }

        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;

          final fechaA = dataA['fecha_pronunciacion'];
          final fechaB = dataB['fecha_pronunciacion'];

          if (fechaA is Timestamp && fechaB is Timestamp) {
            return fechaB.compareTo(fechaA);
          }

          return 0;
        });

        final ultima = docs.first.data() as Map<String, dynamic>;
        final anteriores = docs.skip(1).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Última retroalimentación oral",
              style: TextStyle(
                color: Color(0xFFB71C1C),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _PronunciacionCard(
              data: ultima,
              destacada: true,
              onPlay: _reproducir,
            ),
            const SizedBox(height: 14),
            if (anteriores.isNotEmpty)
              const Text(
                "Historial anterior",
                style: TextStyle(
                  color: Color(0xFFB71C1C),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 8),
            ...anteriores.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return _PronunciacionExpansionCard(
                data: data,
                onPlay: _reproducir,
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class _PronunciacionExpansionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String) onPlay;

  const _PronunciacionExpansionCard({
    required this.data,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final texto = data['texto_reconocido'] ?? '';
    final puntuacion = data['puntuacion_pronunciacion'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFB71C1C).withOpacity(0.15),
        ),
      ),
      child: ExpansionTile(
        iconColor: const Color(0xFFB71C1C),
        collapsedIconColor: const Color(0xFFB71C1C),
        title: Text(
          texto.toString().length > 35
              ? "${texto.toString().substring(0, 35)}..."
              : texto.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFB71C1C),
          ),
        ),
        subtitle: Text("Puntuación ${puntuacion.toStringAsFixed(0)}"),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _PronunciacionCard(
              data: data,
              destacada: false,
              onPlay: onPlay,
            ),
          ),
        ],
      ),
    );
  }
}

class _PronunciacionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool destacada;
  final Function(String) onPlay;

  const _PronunciacionCard({
    required this.data,
    required this.destacada,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final textoReconocido = data['texto_reconocido'] ?? '';
    final textoReferencia = data['texto_referencia'] ?? '';
    final puntuacion = data['puntuacion_pronunciacion'] ?? 0;
    final palabras = List.from(data['palabras_observadas'] ?? []);

    return Container(
      margin: EdgeInsets.only(bottom: destacada ? 18 : 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: destacada
              ? const Color(0xFFB71C1C).withOpacity(0.35)
              : const Color(0xFFB71C1C).withOpacity(0.15),
          width: destacada ? 1.5 : 1,
        ),
        boxShadow: destacada
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(puntuacion),
          const SizedBox(height: 16),
          _sectionTitle("Frase reconocida"),
          _box(textoReconocido),
          const SizedBox(height: 12),
          _sectionTitle("Frase de referencia"),
          _box(
            textoReferencia,
            color: const Color(0xFFFFEBEE),
          ),
          const SizedBox(height: 14),
          _sectionTitle("Palabras a practicar"),
          const SizedBox(height: 8),
          palabras.isEmpty
              ? const Text(
                  "No se detectaron palabras específicas para practicar.",
                  style: TextStyle(color: Colors.green),
                )
              : Column(
                  children: palabras.map((item) {
                    final palabra = item['palabra'] ?? '';
                    final pronunciacion = item['pronunciacion_correcta'] ?? '';
                    final explicacion = item['explicacion'] ?? '';

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFB71C1C).withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            palabra.toString(),
                            style: const TextStyle(
                              color: Color(0xFFB71C1C),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Pronunciación sugerida: $pronunciacion",
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            explicacion.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () => onPlay(palabra.toString()),
                              icon: const Icon(Icons.volume_up, size: 18),
                              label: const Text("Escuchar"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB71C1C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _header(dynamic puntuacion) {
    final valor = puntuacion is num ? puntuacion.toDouble() : 0.0;

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFB71C1C),
          child: Text(
            valor.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            "Análisis de pronunciación",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB71C1C),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFB71C1C),
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  Widget _box(String text, {Color color = const Color(0xFFF5F5F5)}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text.isEmpty ? "Sin información" : text,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
