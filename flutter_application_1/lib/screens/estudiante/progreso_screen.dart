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
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error al cargar progreso: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
          );
        }

        final analisisDocs = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final gramatica = data['puntuacion_gramatica'];
          final finalizado = data['finalizado'];

          return finalizado == true || (gramatica is num && gramatica > 0);
        }).toList();

        if (analisisDocs.isEmpty) {
          return _emptyState();
        }

        final resumen = _calcularResumen(analisisDocs);
        final totalSesiones = resumen['total_sesiones'] ?? 0;
        final totalRespuestas = resumen['total_respuestas'] ?? 0;
        final promedioGramatica = resumen['promedio_gramatica'] ?? 0;
        final promedioPronunciacion =
            resumen['promedio_pronunciacion'] ?? 0;
        final historial =
            resumen['historial'] as List<Map<String, dynamic>>;

        return Padding(
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
                "Selecciona una fecha para ver las sesiones registradas.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Expanded(
  child: Scrollbar(
    thumbVisibility: true,
    radius: const Radius.circular(12),
    thickness: 5,
    child: ListView(
      children: _agruparHistorialPorFecha(historial).entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10, right: 8),
          decoration: _cardDecoration(),
          child: ExpansionTile(
            title: Text(
              entry.key,
              style: const TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text("${entry.value.length} sesiones finalizadas"),
            children: entry.value
                .map((item) => _historialResumenCard(item))
                .toList(),
          ),
        );
      }).toList(),
    ),
  ),
),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _calcularResumen(
    List<QueryDocumentSnapshot> analisisDocs,
  ) {
    int totalRespuestas = 0;
    int sumaGramatica = 0;
    int cantidadGramatica = 0;
    int sumaPronunciacion = 0;
    int cantidadPronunciacion = 0;

    List<Map<String, dynamic>> historial = [];

    for (final analisisDoc in analisisDocs) {
      final analisis = analisisDoc.data() as Map<String, dynamic>;

      final fecha = analisis['fecha_analisis'];
      final pGram = analisis['puntuacion_gramatica'];
      final pPron = analisis['puntuacion_pronunciacion'];
      final respuestas = analisis['total_respuestas'];

      final gramaticaSesion = pGram is num ? pGram.toInt() : 0;
      final pronunciacionSesion = pPron is num ? pPron.toInt() : 0;
      final respuestasSesion = respuestas is num ? respuestas.toInt() : 0;

      if (gramaticaSesion > 0) {
        sumaGramatica += gramaticaSesion;
        cantidadGramatica++;
      }

      if (pronunciacionSesion > 0) {
        sumaPronunciacion += pronunciacionSesion;
        cantidadPronunciacion++;
      }

      totalRespuestas += respuestasSesion;

      historial.add({
        'fecha_inicio': fecha,
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

  Map<String, List<Map<String, dynamic>>> _agruparHistorialPorFecha(
    List<Map<String, dynamic>> historial,
  ) {
    final Map<String, List<Map<String, dynamic>>> grupos = {};

    for (final item in historial) {
      final fecha = item['fecha_inicio'];
      String clave = "Sin fecha";

      if (fecha is Timestamp) {
        final f = fecha.toDate();
        clave = "${f.day}/${f.month}/${f.year}";
      }

      grupos.putIfAbsent(clave, () => []);
      grupos[clave]!.add(item);
    }

    return grupos;
  }

  Widget _historialResumenCard(Map<String, dynamic> item) {
    final fecha = item['fecha_inicio'];
    String fechaTexto = "Sin hora";

    if (fecha is Timestamp) {
      final f = fecha.toDate();
      fechaTexto = "${f.hour}:${f.minute.toString().padLeft(2, '0')}";
    }

    final gramatica = item['gramatica'];
    final pronunciacion = item['pronunciacion'];
    final respuestas = item['respuestas'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF1A237E),
                radius: 16,
                child: Icon(Icons.history, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Sesión finalizada",
                  style: TextStyle(
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                "$fechaTexto · $respuestas resp.",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _miniPorcentaje("Gramática", gramatica, const Color(0xFF1A237E)),
          const SizedBox(height: 10),
          _miniPorcentaje(
            "Pronunciación",
            pronunciacion,
            const Color(0xFFB71C1C),
          ),
        ],
      ),
    );
  }

  Widget _miniPorcentaje(String label, dynamic valor, Color color) {
    final numero = valor is num ? valor.toInt() : 0;
    final v = (numero / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
            Text(
              "$numero%",
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
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

 Widget _emptyState() {
  return Padding(
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