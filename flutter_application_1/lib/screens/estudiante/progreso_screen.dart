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
          .collection('analisis')
          .where('estudiante_uid', isEqualTo: estudianteUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error al cargar progreso",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
          );
        }

        final analisisDocs = snapshot.data?.docs ?? [];

        if (analisisDocs.isEmpty) {
          return _emptyState();
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: _calcularResumen(analisisDocs),
          builder: (context, resumenSnap) {
            if (!resumenSnap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
              );
            }

            final resumen = resumenSnap.data!;

            final totalSesiones = resumen['total_sesiones'] ?? 0;
            final totalRespuestas = resumen['total_respuestas'] ?? 0;
            final promedioGramatica = resumen['promedio_gramatica'] ?? 0;
            final promedioPronunciacion =
                resumen['promedio_pronunciacion'] ?? 0;
            final historial =
                resumen['historial'] as List<Map<String, dynamic>>;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mi Progreso",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Resumen de tu desempeño en las prácticas de speaking.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          totalSesiones.toString(),
                          "Sesiones",
                          Icons.mic,
                          const Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          totalRespuestas.toString(),
                          "Respuestas",
                          Icons.chat_bubble_outline,
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
                          "$promedioGramatica%",
                          "Gramática",
                          Icons.spellcheck,
                          const Color(0xFFF9A825),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          "$promedioPronunciacion%",
                          "Pronunciación",
                          Icons.record_voice_over,
                          const Color(0xFF4A148C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _diagnosticoProgreso(
                    promedioGramatica: promedioGramatica,
                    promedioPronunciacion: promedioPronunciacion,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Historial de interacciones",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Últimas sesiones registradas.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ...historial.map((item) => _historialResumenCard(item)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _calcularResumen(
    List<QueryDocumentSnapshot> analisisDocs,
  ) async {
    int totalRespuestas = 0;
    int sumaGramatica = 0;
    int cantidadGramatica = 0;
    int sumaPronunciacion = 0;
    int cantidadPronunciacion = 0;

    List<Map<String, dynamic>> historial = [];

    for (final analisisDoc in analisisDocs) {
      final analisis = analisisDoc.data() as Map<String, dynamic>;

      final interaccionId = analisis['interaccion_id'] ?? '';
      final fecha = analisis['fecha_analisis'];
      final textoOriginal = analisis['texto_original'] ?? 'Sesión de práctica';

      int? gramaticaSesion;
      int? pronunciacionSesion;
      int respuestasSesion = 0;

      final pGram = analisis['puntuacion_gramatica'];
      if (pGram is num && pGram.toInt() > 0) {
        gramaticaSesion = pGram.toInt();
        sumaGramatica += gramaticaSesion;
        cantidadGramatica++;
      }

      if (interaccionId.toString().isNotEmpty) {
        final respuestasSnap = await FirebaseFirestore.instance
            .collection('respuestas')
            .where('interaccion_id', isEqualTo: interaccionId)
            .get();

        respuestasSesion = respuestasSnap.docs.length;
        totalRespuestas += respuestasSesion;

        final pronunciacionSnap = await FirebaseFirestore.instance
            .collection('pronunciacion')
            .where('interaccion_id', isEqualTo: interaccionId)
            .limit(1)
            .get();

        if (pronunciacionSnap.docs.isNotEmpty) {
          final pData = pronunciacionSnap.docs.first.data();
          final pPron = pData['puntuacion_pronunciacion'];

          if (pPron is num && pPron.toInt() > 0) {
            pronunciacionSesion = pPron.toInt();
            sumaPronunciacion += pronunciacionSesion;
            cantidadPronunciacion++;
          }
        }
      }

      historial.add({
        'fecha_inicio': fecha,
        'texto': textoOriginal,
        'respuestas': respuestasSesion,
        'gramatica': gramaticaSesion,
        'pronunciacion': pronunciacionSesion,
      });
    }

    historial.sort((a, b) {
      final fa = a['fecha_inicio'];
      final fb = b['fecha_inicio'];

      if (fa is Timestamp && fb is Timestamp) {
        return fb.compareTo(fa);
      }
      return 0;
    });

    final promedioGramatica = cantidadGramatica == 0
        ? 0
        : (sumaGramatica / cantidadGramatica).round();

    final promedioPronunciacion = cantidadPronunciacion == 0
        ? 0
        : (sumaPronunciacion / cantidadPronunciacion).round();

    return {
      'total_sesiones': analisisDocs.length,
      'total_respuestas': totalRespuestas,
      'promedio_gramatica': promedioGramatica,
      'promedio_pronunciacion': promedioPronunciacion,
      'historial': historial,
    };
  }

  Widget _diagnosticoProgreso({
    required int promedioGramatica,
    required int promedioPronunciacion,
  }) {
    String fortaleza = "Sin datos suficientes";
    String mejora = "Realizar más prácticas";

    if (promedioGramatica > promedioPronunciacion) {
      fortaleza = "Gramática";
      mejora = "Pronunciación";
    } else if (promedioPronunciacion > promedioGramatica) {
      fortaleza = "Pronunciación";
      mejora = "Gramática";
    } else if (promedioGramatica > 0 && promedioPronunciacion > 0) {
      fortaleza = "Desempeño equilibrado";
      mejora = "Mantener práctica constante";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Diagnóstico del progreso",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          _diagnosticoItem(
            Icons.emoji_events,
            "Fortaleza principal",
            fortaleza,
            const Color(0xFFF9A825),
          ),
          const SizedBox(height: 12),
          _diagnosticoItem(
            Icons.trending_up,
            "Área a mejorar",
            mejora,
            const Color(0xFFB71C1C),
          ),
          const SizedBox(height: 12),
          _diagnosticoItem(
            Icons.school,
            "Estado",
            "En progreso",
            const Color(0xFF1A237E),
          ),
        ],
      ),
    );
  }

  Widget _diagnosticoItem(
    IconData icono,
    String titulo,
    String valor,
    Color color,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icono, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                valor,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resumenHabilidades({
    required int promedioGramatica,
    required int promedioPronunciacion,
  }) {
    return Container(
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
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          _habilidad(
            "Gramática",
            promedioGramatica / 100,
            const Color(0xFF1A237E),
          ),
          const SizedBox(height: 14),
          _habilidad(
            "Pronunciación",
            promedioPronunciacion / 100,
            const Color(0xFFB71C1C),
          ),
        ],
      ),
    );
  }

  Widget _historialResumenCard(Map<String, dynamic> item) {
    final fecha = item['fecha_inicio'];
    String fechaTexto = "Sin fecha";

    if (fecha is Timestamp) {
      final f = fecha.toDate();
      fechaTexto =
          "${f.day}/${f.month}/${f.year} - ${f.hour}:${f.minute.toString().padLeft(2, '0')}";
    }

    final gramatica = item['gramatica'];
    final pronunciacion = item['pronunciacion'];
    final respuestas = item['respuestas'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF1A237E),
                radius: 18,
                child: Icon(Icons.history, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Sesión de práctica",
                  style: const TextStyle(
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                "$respuestas resp.",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            fechaTexto,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 14),
          _miniBarraNullable("Gramática", gramatica, const Color(0xFF1A237E)),
          const SizedBox(height: 10),
          _miniBarraNullable(
              "Pronunciación", pronunciacion, const Color(0xFFB71C1C)),
        ],
      ),
    );
  }

  Widget _miniBarra(String label, int valor, Color color) {
    final v = (valor / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
            Text(
              "$valor%",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: v,
          minHeight: 7,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }

  Widget _miniBarraNullable(String label, dynamic valor, Color color) {
    if (valor == null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          Text(
            label == "Gramática"
                ? "Sin evaluación escrita"
                : "Sin evaluación oral",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }

    final numero = valor is num ? valor.toInt() : 0;
    final v = (numero / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
            Text(
              "$numero%",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: v,
          minHeight: 7,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(8),
        ),
      ],
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
            Icon(Icons.bar_chart, size: 54, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              "Sin progreso registrado",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
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
