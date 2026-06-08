import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ProgresoEstudiantesScreen extends StatefulWidget {
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
  State<ProgresoEstudiantesScreen> createState() =>
      _ProgresoEstudiantesScreenState();
}

class _ProgresoEstudiantesScreenState extends State<ProgresoEstudiantesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> estudiantesResumen = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => cargando = true);

    final matriculasSnap = widget.estudianteUidFiltro != null
        ? await FirebaseFirestore.instance
            .collection('matriculas')
            .where('curso_id', isEqualTo: widget.cursoId)
            .where('estudiante_uid', isEqualTo: widget.estudianteUidFiltro)
            .where('activo', isEqualTo: true)
            .get()
        : await FirebaseFirestore.instance
            .collection('matriculas')
            .where('curso_id', isEqualTo: widget.cursoId)
            .where('activo', isEqualTo: true)
            .get();

    List<Map<String, dynamic>> datos = [];

    for (final mat in matriculasSnap.docs) {
      final estudianteUid = mat.data()['estudiante_uid'] ?? '';

      final usuarioDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(estudianteUid)
          .get();

      final usuario = usuarioDoc.data() ?? {};
      final resumen = await _obtenerResumenEstudiante(estudianteUid);

      datos.add({
        'uid': estudianteUid,
        'nombre': usuario['nombre'] ?? 'Estudiante',
        'email': usuario['email'] ?? '',
        ...resumen,
      });
    }

    if (!mounted) return;

    setState(() {
      estudiantesResumen = datos;
      cargando = false;
    });
  }

  Future<Map<String, dynamic>> _obtenerResumenEstudiante(
      String estudianteUid) async {
    int sesiones = 0;
    int respuestas = 0;
    int sumaGramatica = 0;
    int cantidadGramatica = 0;
    int sumaPronunciacion = 0;
    int cantidadPronunciacion = 0;
    String nivel = "A1";

    final interaccionesSnap = await FirebaseFirestore.instance
        .collection('interacciones')
        .where('estudiante_uid', isEqualTo: estudianteUid)
        .where('curso_id', isEqualTo: widget.cursoId)
        .limit(10)
        .get();

    sesiones = interaccionesSnap.docs.length;

    for (final interaccion in interaccionesSnap.docs) {
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
        .where('curso_id', isEqualTo: widget.cursoId)
        .limit(10)
        .get();

    for (final doc in analisisSnap.docs) {
      final data = doc.data();
      final p = data['puntuacion_gramatica'];

      if (p is num) {
        sumaGramatica += p.toInt();
        cantidadGramatica++;
      }

      if (data['nivel_detectado'] != null) {
        nivel = data['nivel_detectado'].toString();
      }
    }

    final pronunciacionSnap = await FirebaseFirestore.instance
        .collection('pronunciacion')
        .where('estudiante_uid', isEqualTo: estudianteUid)
        .where('curso_id', isEqualTo: widget.cursoId)
        .limit(10)
        .get();

    for (final doc in pronunciacionSnap.docs) {
      final p = doc.data()['puntuacion_pronunciacion'];

      if (p is num) {
        sumaPronunciacion += p.toInt();
        cantidadPronunciacion++;
      }
    }

    final gramatica = cantidadGramatica == 0
        ? null
        : (sumaGramatica / cantidadGramatica).round();

    final pronunciacion = cantidadPronunciacion == 0
        ? null
        : (sumaPronunciacion / cantidadPronunciacion).round();

    return {
      'sesiones': sesiones,
      'respuestas': respuestas,
      'gramatica': gramatica,
      'pronunciacion': pronunciacion,
      'nivel': nivel,
    };
  }

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
              "Monitoreo docente",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.nombreCurso,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "General"),
            Tab(text: "Estudiantes"),
            Tab(text: "Reporte"),
          ],
        ),
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
            )
          : estudiantesResumen.isEmpty
              ? _emptyState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGeneralTab(),
                    _buildEstudiantesTab(),
                    _buildReporteTab(),
                  ],
                ),
    );
  }

  Widget _buildGeneralTab() {
    final totalEstudiantes = estudiantesResumen.length;
    final totalSesiones = estudiantesResumen.fold<int>(
      0,
      (sum, e) => sum + ((e['sesiones'] ?? 0) as int),
    );

    final promedioGramatica = _promedio('gramatica');
    final promedioPronunciacion = _promedio('pronunciacion');
    final mejor = _mejorEstudiante();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Resumen general del curso",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  "$totalEstudiantes",
                  "Estudiantes",
                  Icons.people,
                  const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  "$totalSesiones",
                  "Sesiones",
                  Icons.mic,
                  const Color(0xFFB71C1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _barra(
            "Promedio de gramática",
            promedioGramatica,
            const Color(0xFF1A237E),
          ),
          const SizedBox(height: 12),
          _barra(
            "Promedio de pronunciación",
            promedioPronunciacion,
            const Color(0xFFB71C1C),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                const Icon(Icons.emoji_events,
                    color: Color(0xFFF9A825), size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Mejor rendimiento:\n$mejor",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstudiantesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: estudiantesResumen.length,
      itemBuilder: (context, index) {
        final e = estudiantesResumen[index];

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
                    backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
                    child: Text(
                      e['nombre'].toString().isNotEmpty
                          ? e['nombre'].toString()[0].toUpperCase()
                          : 'E',
                      style: const TextStyle(
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e['nombre'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ),
                  _nivelChip(e['nivel'].toString()),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                e['email'].toString(),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                "${e['sesiones']} sesiones · ${e['respuestas']} respuestas",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              _barra("Gramática", e['gramatica'], const Color(0xFF1A237E)),
              const SizedBox(height: 10),
              _barra(
                "Pronunciación",
                e['pronunciacion'],
                const Color(0xFFB71C1C),
              ),
              const SizedBox(height: 12),
              Text(
                "Recomendación: ${_recomendacion(e)}",
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReporteTab() {
    final promedioGramatica = _promedio('gramatica');
    final promedioPronunciacion = _promedio('pronunciacion');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Reportes",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Genera reportes generales o individuales.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () async {
              final pdf = await _generarPdfGeneral();
              await Printing.layoutPdf(onLayout: (_) async => pdf);
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("Generar PDF general del curso"),
          ),
          const SizedBox(height: 16),
          _barra(
            "Promedio general gramática",
            promedioGramatica,
            const Color(0xFF1A237E),
          ),
          const SizedBox(height: 12),
          _barra(
            "Promedio general pronunciación",
            promedioPronunciacion,
            const Color(0xFFB71C1C),
          ),
          const SizedBox(height: 20),
          const Text(
            "Reporte por estudiante",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          ...estudiantesResumen.map((e) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: _cardDecoration(),
              child: ListTile(
                title: Text(e['nombre'].toString()),
                subtitle: Text(
                  "Gramática: ${e['gramatica'] ?? 'Pendiente'}% · Pronunciación: ${e['pronunciacion'] ?? 'Pendiente'}%",
                ),
                trailing: const Icon(
                  Icons.picture_as_pdf,
                  color: Color(0xFFB71C1C),
                ),
                onTap: () async {
                  final pdf = await _generarPdfEstudiante(e);
                  await Printing.layoutPdf(onLayout: (_) async => pdf);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  int _promedio(String campo) {
    final valores = estudiantesResumen
        .where((e) => e[campo] != null)
        .map((e) => e[campo] as int)
        .toList();

    if (valores.isEmpty) return 0;

    return (valores.reduce((a, b) => a + b) / valores.length).round();
  }

  String _mejorEstudiante() {
    if (estudiantesResumen.isEmpty) return "Sin datos";

    Map<String, dynamic>? mejor;
    int mejorProm = -1;

    for (final e in estudiantesResumen) {
      final g = e['gramatica'] ?? 0;
      final p = e['pronunciacion'] ?? 0;
      final prom = ((g + p) / 2).round();

      if (prom > mejorProm) {
        mejorProm = prom;
        mejor = e;
      }
    }

    return mejor?['nombre'] ?? "Sin datos";
  }

  String _recomendacion(Map<String, dynamic> e) {
    final g = e['gramatica'];
    final p = e['pronunciacion'];

    if (e['sesiones'] == 0) {
      return "El estudiante debe realizar más prácticas.";
    }

    if (g == null && p == null) {
      return "Debe finalizar una práctica para generar resultados.";
    }

    final gramatica = g ?? 0;
    final pronunciacion = p ?? 0;

    if (gramatica < pronunciacion) {
      return "Reforzar estructura gramatical.";
    }

    if (pronunciacion < gramatica) {
      return "Practicar pronunciación y fluidez oral.";
    }

    return "Mantener práctica constante.";
  }

  Widget _statCard(String valor, String label, IconData icono, Color color) {
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
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _barra(String label, dynamic valor, Color color) {
    if (valor == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Text(
          "$label: Pendiente",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    final numero = valor is num ? valor.toInt() : 0;
    final v = (numero / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
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
                "$numero%",
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
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

  Widget _emptyState() {
    return const Center(
      child: Text(
        "Sin datos disponibles.",
        style: TextStyle(color: Colors.grey),
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

  Future<Uint8List> _generarPdfGeneral() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Reporte general del curso",
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text("Curso: ${widget.nombreCurso}"),
              pw.SizedBox(height: 16),
              pw.Text("Total estudiantes: ${estudiantesResumen.length}"),
              pw.Text("Promedio gramática: ${_promedio('gramatica')}%"),
              pw.Text(
                "Promedio pronunciación: ${_promedio('pronunciacion')}%",
              ),
              pw.Text("Mejor rendimiento: ${_mejorEstudiante()}"),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: [
                  "Estudiante",
                  "Sesiones",
                  "Gramática",
                  "Pronunciación",
                  "Nivel",
                ],
                data: estudiantesResumen.map((e) {
                  return [
                    e['nombre'].toString(),
                    e['sesiones'].toString(),
                    e['gramatica'] == null ? "Pendiente" : "${e['gramatica']}%",
                    e['pronunciacion'] == null
                        ? "Pendiente"
                        : "${e['pronunciacion']}%",
                    e['nivel'].toString(),
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _generarPdfEstudiante(Map<String, dynamic> e) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Reporte individual del estudiante",
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text("Curso: ${widget.nombreCurso}"),
              pw.Text("Estudiante: ${e['nombre']}"),
              pw.Text("Email: ${e['email']}"),
              pw.SizedBox(height: 16),
              pw.Text("Sesiones realizadas: ${e['sesiones']}"),
              pw.Text("Respuestas registradas: ${e['respuestas']}"),
              pw.Text(
                "Gramática: ${e['gramatica'] == null ? 'Pendiente' : '${e['gramatica']}%'}",
              ),
              pw.Text(
                "Pronunciación: ${e['pronunciacion'] == null ? 'Pendiente' : '${e['pronunciacion']}%'}",
              ),
              pw.Text("Nivel detectado: ${e['nivel']}"),
              pw.SizedBox(height: 16),
              pw.Text("Recomendación: ${_recomendacion(e)}"),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
