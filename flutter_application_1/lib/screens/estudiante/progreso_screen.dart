import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgresoScreen extends StatelessWidget {
  final String estudianteUid;

  const ProgresoScreen({
    super.key,
    required this.estudianteUid,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interacciones')
          .where('estudiante_uid', isEqualTo: estudianteUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState();
        }

        final interacciones = snapshot.data!.docs;

        return FutureBuilder<Map<String, dynamic>>(
          future: _calcularResumen(interacciones),
          builder: (context, resumenSnap) {
            if (!resumenSnap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
              );
            }

            final resumen = resumenSnap.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mi Progreso",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Resumen de tus sesiones e historial de práctica.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          resumen['total_sesiones'].toString(),
                          "Sesiones",
                          Icons.mic,
                          const Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          resumen['total_respuestas'].toString(),
                          "Respuestas",
                          Icons.question_answer,
                          const Color(0xFFB71C1C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          "${resumen['promedio_pronunciacion']}%",
                          "Pronunciación",
                          Icons.record_voice_over,
                          const Color(0xFF4A148C),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          "${resumen['promedio_gramatica']}%",
                          "Gramática",
                          Icons.spellcheck,
                          const Color(0xFFF9A825),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Resumen de habilidades",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _habilidad(
                          "Gramática",
                          resumen['promedio_gramatica'] / 100,
                          const Color(0xFF1A237E),
                        ),
                        const SizedBox(height: 12),
                        _habilidad(
                          "Pronunciación",
                          resumen['promedio_pronunciacion'] / 100,
                          const Color(0xFFB71C1C),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Historial de interacciones",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...interacciones.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return _historialCard(
                      interaccionId: doc.id,
                      data: data,
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _calcularResumen(
    List<QueryDocumentSnapshot> interacciones,
  ) async {
    int totalSesiones = interacciones.length;
    int totalRespuestas = 0;

    int sumaGramatica = 0;
    int cantidadGramatica = 0;

    int sumaPronunciacion = 0;
    int cantidadPronunciacion = 0;

    for (final interaccion in interacciones) {
      final interaccionId = interaccion.id;

      final respuestasSnap = await FirebaseFirestore.instance
          .collection('respuestas')
          .where('interaccion_id', isEqualTo: interaccionId)
          .get();

      totalRespuestas += respuestasSnap.docs.length;

      final analisisSnap = await FirebaseFirestore.instance
          .collection('analisis')
          .where('interaccion_id', isEqualTo: interaccionId)
          .get();

      for (final doc in analisisSnap.docs) {
        final data = doc.data();
        final puntuacion = data['puntuacion_gramatica'];

        if (puntuacion is num) {
          sumaGramatica += puntuacion.toInt();
          cantidadGramatica++;
        }
      }

      final pronunciacionSnap = await FirebaseFirestore.instance
          .collection('pronunciacion')
          .where('interaccion_id', isEqualTo: interaccionId)
          .get();

      for (final doc in pronunciacionSnap.docs) {
        final data = doc.data();
        final puntuacion = data['puntuacion_pronunciacion'];

        if (puntuacion is num) {
          sumaPronunciacion += puntuacion.toInt();
          cantidadPronunciacion++;
        }
      }
    }

    final promedioGramatica = cantidadGramatica == 0
        ? 0
        : (sumaGramatica / cantidadGramatica).round();

    final promedioPronunciacion = cantidadPronunciacion == 0
        ? 0
        : (sumaPronunciacion / cantidadPronunciacion).round();

    return {
      'total_sesiones': totalSesiones,
      'total_respuestas': totalRespuestas,
      'promedio_gramatica': promedioGramatica,
      'promedio_pronunciacion': promedioPronunciacion,
    };
  }

  Widget _historialCard({
    required String interaccionId,
    required Map<String, dynamic> data,
  }) {
    final fecha = data['fecha_inicio'];

    String fechaTexto = "Sin fecha";

    if (fecha is Timestamp) {
      final f = fecha.toDate();
      fechaTexto =
          "${f.day}/${f.month}/${f.year} - ${f.hour}:${f.minute.toString().padLeft(2, '0')}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(),
      child: ExpansionTile(
        iconColor: const Color(0xFF1A237E),
        collapsedIconColor: const Color(0xFF1A237E),
        title: const Text(
          "Sesión de práctica",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        subtitle: Text(
          fechaTexto,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: [
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('respuestas')
                .where('interaccion_id', isEqualTo: interaccionId)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                );
              }

              final respuestas = snapshot.data!.docs;

              if (respuestas.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "No hay respuestas registradas.",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Column(
                children: respuestas.map((doc) {
                  final respuesta = doc.data() as Map<String, dynamic>;

                  final textoUsuario = respuesta['texto_usuario'] ?? '';
                  final respuestaAsistente =
                      respuesta['respuesta_asistente'] ?? '';

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Estudiante",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(textoUsuario.toString()),
                        const SizedBox(height: 10),
                        const Text(
                          "Asistente",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB71C1C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(respuestaAsistente.toString()),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String valor,
    String label,
    IconData icono,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icono, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _habilidad(String nombre, double valor, Color color) {
    final valorSeguro = valor.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              nombre,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            Text(
              "${(valorSeguro * 100).toInt()}%",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: valorSeguro,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: 54,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            const Text(
              "Sin progreso registrado",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Completa una conversación con el asistente virtual para visualizar tu historial y resultados.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
