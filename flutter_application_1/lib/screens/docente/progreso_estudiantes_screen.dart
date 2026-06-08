import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgresoEstudiantesScreen extends StatelessWidget {
  final String cursoId;
  final String nombreCurso;
  final String? estudianteUidFiltro;

  const ProgresoEstudiantesScreen({
    super.key,
    required this.cursoId,
    required this.nombreCurso,
    this.estudianteUidFiltro,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Progreso de estudiantes",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              nombreCurso,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            tooltip: "Ver reporte",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReporteCursoScreen(
                    cursoId: cursoId,
                    nombreCurso: nombreCurso,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: estudianteUidFiltro != null
            ? FirebaseFirestore.instance
                .collection('matriculas')
                .where('curso_id', isEqualTo: cursoId)
                .where('estudiante_uid', isEqualTo: estudianteUidFiltro)
                .where('activo', isEqualTo: true)
                .snapshots()
            : FirebaseFirestore.instance
                .collection('matriculas')
                .where('curso_id', isEqualTo: cursoId)
                .where('activo', isEqualTo: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error al cargar estudiantes",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyState(
              icon: Icons.people_outline,
              titulo: "Sin estudiantes inscritos",
              subtitulo:
                  "Cuando existan estudiantes inscritos aparecerán aquí.",
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final estUid = data['estudiante_uid'] ?? '';

              return _ProgresoEstudianteCard(
                estudianteUid: estUid,
                cursoId: cursoId,
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String titulo,
    required String subtitulo,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgresoEstudianteCard extends StatelessWidget {
  final String estudianteUid;
  final String cursoId;

  const _ProgresoEstudianteCard({
    required this.estudianteUid,
    required this.cursoId,
  });

  Future<Map<String, dynamic>> _obtenerResumenEstudiante() async {
    int sesiones = 0;
    int respuestas = 0;

    int sumaGramatica = 0;
    int cantidadGramatica = 0;

    int sumaPronunciacion = 0;
    int cantidadPronunciacion = 0;

    String nivel = "A1";
    DateTime? ultimaPractica;

    final interaccionesSnap = await FirebaseFirestore.instance
        .collection('interacciones')
        .where('estudiante_uid', isEqualTo: estudianteUid)
        .where('curso_id', isEqualTo: cursoId)
        .limit(10)
        .get();

    sesiones = interaccionesSnap.docs.length;

    for (final interaccion in interaccionesSnap.docs) {
      final data = interaccion.data();
      final fecha = data['fecha_inicio'];

      if (fecha is Timestamp) {
        final f = fecha.toDate();
        if (ultimaPractica == null || f.isAfter(ultimaPractica!)) {
          ultimaPractica = f;
        }
      }

      final respuestasSnap = await FirebaseFirestore.instance
          .collection('respuestas')
          .where('interaccion_id', isEqualTo: interaccion.id)
          .limit(10)
          .get();

      respuestas += respuestasSnap.docs.length;
    }

    final analisisSnap = await FirebaseFirestore.instance
        .collection('analisis')
        .where('estudiante_uid', isEqualTo: estudianteUid)
        .where('curso_id', isEqualTo: cursoId)
        .limit(10)
        .get();

    for (final doc in analisisSnap.docs) {
      final data = doc.data();
      final puntuacion = data['puntuacion_gramatica'];

      if (puntuacion is num) {
        sumaGramatica += puntuacion.toInt();
        cantidadGramatica++;
      }

      if (data['nivel_detectado'] != null) {
        nivel = data['nivel_detectado'].toString();
      }
    }

    final pronunciacionSnap = await FirebaseFirestore.instance
        .collection('pronunciacion')
        .where('estudiante_uid', isEqualTo: estudianteUid)
        .where('curso_id', isEqualTo: cursoId)
        .limit(10)
        .get();

    for (final doc in pronunciacionSnap.docs) {
      final data = doc.data();
      final puntuacion = data['puntuacion_pronunciacion'];

      if (puntuacion is num) {
        sumaPronunciacion += puntuacion.toInt();
        cantidadPronunciacion++;
      }
    }

    final promedioGramatica = cantidadGramatica == 0
        ? null
        : (sumaGramatica / cantidadGramatica).round();

    final promedioPronunciacion = cantidadPronunciacion == 0
        ? null
        : (sumaPronunciacion / cantidadPronunciacion).round();

    return {
      'sesiones': sesiones,
      'respuestas': respuestas,
      'gramatica': promedioGramatica,
      'pronunciacion': promedioPronunciacion,
      'nivel': nivel,
      'ultima_practica': ultimaPractica,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(estudianteUid)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox();
        }

        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final nombre = data['nombre'] ?? 'Estudiante';
        final email = data['email'] ?? '';

        return FutureBuilder<Map<String, dynamic>>(
          future: _obtenerResumenEstudiante(),
          builder: (context, resumenSnap) {
            if (!resumenSnap.hasData) {
              return _loadingCard(nombre);
            }

            final resumen = resumenSnap.data!;
            final gramatica = resumen['gramatica'];
            final pronunciacion = resumen['pronunciacion'];
            final sesiones = resumen['sesiones'] ?? 0;
            final respuestas = resumen['respuestas'] ?? 0;
            final nivel = resumen['nivel'] ?? 'A1';
            final ultimaPractica = resumen['ultima_practica'];

            final fortaleza = _obtenerFortaleza(gramatica, pronunciacion);
            final recomendacion =
                _obtenerRecomendacion(gramatica, pronunciacion, sesiones);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 23,
                        backgroundColor:
                            const Color(0xFF1A237E).withOpacity(0.1),
                        child: Text(
                          nombre.toString().isNotEmpty
                              ? nombre.toString()[0].toUpperCase()
                              : 'E',
                          style: const TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            Text(
                              email.toString().isEmpty
                                  ? "$sesiones sesiones realizadas"
                                  : email.toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "$sesiones sesiones · $respuestas respuestas",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _nivelChip(nivel.toString()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricaNullable(
                          "Gramática",
                          gramatica,
                          const Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricaNullable(
                          "Pronunciación",
                          pronunciacion,
                          const Color(0xFFB71C1C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9A825).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF9A825).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      "Fortaleza: $fortaleza\n"
                      "Recomendación: $recomendacion\n"
                      "Última práctica: ${_fechaTexto(ultimaPractica)}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _loadingCard(String nombre) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFFB71C1C),
            strokeWidth: 2,
          ),
          const SizedBox(width: 12),
          Text(
            "Cargando progreso de $nombre...",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricaNullable(String label, dynamic valor, Color color) {
    if (valor == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Container(
            height: 7,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Pendiente",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      );
    }

    final numero = valor is num ? valor.toInt() : 0;
    final porcentaje = (numero / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: porcentaje,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 7,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _nivelChip(String nivel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        nivel,
        style: const TextStyle(
          color: Color(0xFF1A237E),
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  String _obtenerFortaleza(dynamic gramatica, dynamic pronunciacion) {
    if (gramatica == null && pronunciacion == null) {
      return "Sin datos suficientes";
    }

    final g = gramatica is num ? gramatica.toInt() : 0;
    final p = pronunciacion is num ? pronunciacion.toInt() : 0;

    if (g == p) return "Desempeño equilibrado";
    return g > p ? "Gramática" : "Pronunciación";
  }

  String _obtenerRecomendacion(
    dynamic gramatica,
    dynamic pronunciacion,
    int sesiones,
  ) {
    if (sesiones == 0) {
      return "El estudiante aún no registra sesiones.";
    }

    if (gramatica == null && pronunciacion == null) {
      return "Debe finalizar una interacción para generar resultados.";
    }

    final g = gramatica is num ? gramatica.toInt() : 0;
    final p = pronunciacion is num ? pronunciacion.toInt() : 0;

    if (g < 50 && p < 50) {
      return "Reforzar gramática y speaking.";
    }

    if (g < p) {
      return "Reforzar estructura gramatical.";
    }

    if (p < g) {
      return "Practicar pronunciación y fluidez oral.";
    }

    return "Mantener práctica constante.";
  }

  String _fechaTexto(dynamic fecha) {
    if (fecha is! DateTime) return "Sin registro";

    return "${fecha.day}/${fecha.month}/${fecha.year}";
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

class ReporteCursoScreen extends StatelessWidget {
  final String cursoId;
  final String nombreCurso;

  const ReporteCursoScreen({
    super.key,
    required this.cursoId,
    required this.nombreCurso,
  });

  Future<Map<String, dynamic>> _generarReporte() async {
    final matriculasSnap = await FirebaseFirestore.instance
        .collection('matriculas')
        .where('curso_id', isEqualTo: cursoId)
        .where('activo', isEqualTo: true)
        .get();

    int totalEstudiantes = matriculasSnap.docs.length;
    int totalSesiones = 0;

    int sumaGramatica = 0;
    int cantidadGramatica = 0;

    int sumaPronunciacion = 0;
    int cantidadPronunciacion = 0;

    String mejorEstudiante = "Sin datos";
    int mejorPromedio = -1;

    for (final mat in matriculasSnap.docs) {
      final data = mat.data();
      final estudianteUid = data['estudiante_uid'] ?? '';

      final usuarioDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(estudianteUid)
          .get();

      final nombre = (usuarioDoc.data()?['nombre'] ?? 'Estudiante').toString();

      final interaccionesSnap = await FirebaseFirestore.instance
          .collection('interacciones')
          .where('estudiante_uid', isEqualTo: estudianteUid)
          .where('curso_id', isEqualTo: cursoId)
          .limit(10)
          .get();

      totalSesiones += interaccionesSnap.docs.length;

      final analisisSnap = await FirebaseFirestore.instance
          .collection('analisis')
          .where('estudiante_uid', isEqualTo: estudianteUid)
          .where('curso_id', isEqualTo: cursoId)
          .limit(10)
          .get();

      int sumaGEst = 0;
      int cantGEst = 0;

      for (final doc in analisisSnap.docs) {
        final p = doc.data()['puntuacion_gramatica'];
        if (p is num) {
          sumaGramatica += p.toInt();
          cantidadGramatica++;

          sumaGEst += p.toInt();
          cantGEst++;
        }
      }

      final pronunciacionSnap = await FirebaseFirestore.instance
          .collection('pronunciacion')
          .where('estudiante_uid', isEqualTo: estudianteUid)
          .where('curso_id', isEqualTo: cursoId)
          .limit(10)
          .get();

      int sumaPEst = 0;
      int cantPEst = 0;

      for (final doc in pronunciacionSnap.docs) {
        final p = doc.data()['puntuacion_pronunciacion'];
        if (p is num) {
          sumaPronunciacion += p.toInt();
          cantidadPronunciacion++;

          sumaPEst += p.toInt();
          cantPEst++;
        }
      }

      int promedioEstudiante = 0;

      if (cantGEst > 0 || cantPEst > 0) {
        final promG = cantGEst == 0 ? 0 : (sumaGEst / cantGEst).round();
        final promP = cantPEst == 0 ? 0 : (sumaPEst / cantPEst).round();
        promedioEstudiante = ((promG + promP) / 2).round();
      }

      if (promedioEstudiante > mejorPromedio) {
        mejorPromedio = promedioEstudiante;
        mejorEstudiante = nombre;
      }
    }

    final promedioGramatica = cantidadGramatica == 0
        ? 0
        : (sumaGramatica / cantidadGramatica).round();

    final promedioPronunciacion = cantidadPronunciacion == 0
        ? 0
        : (sumaPronunciacion / cantidadPronunciacion).round();

    return {
      'total_estudiantes': totalEstudiantes,
      'total_sesiones': totalSesiones,
      'promedio_gramatica': promedioGramatica,
      'promedio_pronunciacion': promedioPronunciacion,
      'mejor_estudiante': mejorEstudiante,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text("Reporte del curso"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _generarReporte(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
            );
          }

          final reporte = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreCurso,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Reporte general de rendimiento",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _reporteCard(
                        "${reporte['total_estudiantes']}",
                        "Estudiantes",
                        Icons.people,
                        const Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _reporteCard(
                        "${reporte['total_sesiones']}",
                        "Sesiones",
                        Icons.mic,
                        const Color(0xFFB71C1C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _barraReporte(
                  "Promedio de gramática",
                  reporte['promedio_gramatica'],
                  const Color(0xFF1A237E),
                ),
                const SizedBox(height: 14),
                _barraReporte(
                  "Promedio de pronunciación",
                  reporte['promedio_pronunciacion'],
                  const Color(0xFFB71C1C),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Color(0xFFF9A825),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Mejor rendimiento:\n${reporte['mejor_estudiante']}",
                          style: const TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: _cardDecoration(),
                  child: const Text(
                    "Este reporte permite al docente analizar el rendimiento general del curso y tomar decisiones pedagógicas para reforzar las áreas con menor desempeño.",
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _reporteCard(String valor, String label, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icono, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _barraReporte(String label, int valor, Color color) {
    final v = (valor / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 9,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "$valor%",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
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
