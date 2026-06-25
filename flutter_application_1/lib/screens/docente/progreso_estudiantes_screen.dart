import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
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
  String filtroBusqueda = "";

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

    final estudiantesIds = matriculasSnap.docs
        .map((d) => d.data()['estudiante_uid']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    final resultados = await Future.wait(
      estudiantesIds.map((estudianteUid) async {
        final usuarioDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(estudianteUid)
            .get();

        final usuario = usuarioDoc.data() ?? {};
        final resumen = await _obtenerResumenEstudiante(estudianteUid);

        return {
          'uid': estudianteUid,
          'nombre': usuario['nombre'] ?? 'Estudiante',
          'email': usuario['email'] ?? '',
          ...resumen,
        };
      }),
    );

    resultados.sort((a, b) => a['nombre']
        .toString()
        .toLowerCase()
        .compareTo(b['nombre'].toString().toLowerCase()));

    if (!mounted) return;

    setState(() {
      estudiantesResumen = resultados;
      cargando = false;
    });
  }

  Future<Map<String, dynamic>> _obtenerResumenEstudiante(
      String estudianteUid) async {
    int sumaGramatica = 0;
    int cantidadGramatica = 0;
    int sumaPronunciacion = 0;
    int cantidadPronunciacion = 0;
    String nivel = "A1";

    final resultados = await Future.wait([
      FirebaseFirestore.instance
          .collection('analisis')
          .where('estudiante_uid', isEqualTo: estudianteUid)
          .where('curso_id', isEqualTo: widget.cursoId)
          .limit(10)
          .get(),
      FirebaseFirestore.instance
          .collection('pronunciacion')
          .where('estudiante_uid', isEqualTo: estudianteUid)
          .where('curso_id', isEqualTo: widget.cursoId)
          .limit(10)
          .get(),
    ]);

    final analisisSnap = resultados[0] as QuerySnapshot<Map<String, dynamic>>;
    final pronunciacionSnap =
        resultados[1] as QuerySnapshot<Map<String, dynamic>>;

    final sesiones = analisisSnap.docs.length;

    final respuestas = analisisSnap.docs.fold<int>(0, (sum, doc) {
      final total = doc.data()['total_respuestas'];
      return sum + (total is num ? total.toInt() : 0);
    });

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

    for (final doc in pronunciacionSnap.docs) {
      final p = doc.data()['puntuacion_pronunciacion'];

      if (p is num) {
        sumaPronunciacion += p.toInt();
        cantidadPronunciacion++;
      }
    }

    return {
      'sesiones': sesiones,
      'respuestas': respuestas,
      'gramatica': cantidadGramatica == 0
          ? null
          : (sumaGramatica / cantidadGramatica).round(),
      'pronunciacion': cantidadPronunciacion == 0
          ? null
          : (sumaPronunciacion / cantidadPronunciacion).round(),
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
    final filtrados = estudiantesResumen.where((e) {
      final nombre = e['nombre'].toString().toLowerCase();
      final email = e['email'].toString().toLowerCase();
      final filtro = filtroBusqueda.toLowerCase();
      return nombre.contains(filtro) || email.contains(filtro);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) {
              setState(() {
                filtroBusqueda = value;
              });
            },
            decoration: InputDecoration(
              hintText: "Buscar estudiante...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: filtrados.length,
              itemBuilder: (context, index) {
                final e = filtrados[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: _cardDecoration(),
                  child: ExpansionTile(
                    title: Text(
                      e['nombre'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    subtitle: Text(
                      e['email'].toString(),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: _nivelChip(e['nivel'].toString()),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${e['sesiones']} sesiones · ${e['respuestas']} respuestas",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            _barra("Gramática", e['gramatica'],
                                const Color(0xFF1A237E)),
                            const SizedBox(height: 10),
                            _barra("Pronunciación", e['pronunciacion'],
                                const Color(0xFFB71C1C)),
                            const SizedBox(height: 12),
                            Text(
                              "Recomendación: ${_recomendacion(e)}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReporteTab() {
    final filtrados = estudiantesResumen.where((e) {
      final nombre = e['nombre'].toString().toLowerCase();
      final email = e['email'].toString().toLowerCase();
      final filtro = filtroBusqueda.toLowerCase();
      return nombre.contains(filtro) || email.contains(filtro);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
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
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) {
                  setState(() {
                    filtroBusqueda = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Buscar estudiante...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: filtrados.length,
              itemBuilder: (context, index) {
                final e = filtrados[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: _cardDecoration(),
                  child: ListTile(
                    title: Text(
                      e['nombre'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
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
              },
            ),
          ),
        ),
      ],
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
    final fecha = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _pdfHeader("REPORTE GENERAL DEL CURSO"),
          pw.SizedBox(height: 16),
          _infoBox([
            ["Curso", widget.nombreCurso],
            [
              "Fecha de generación",
              "${fecha.day}/${fecha.month}/${fecha.year}"
            ],
            ["Total estudiantes", estudiantesResumen.length.toString()],
            ["Promedio gramática", "${_promedio('gramatica')}%"],
            ["Promedio pronunciación", "${_promedio('pronunciacion')}%"],
            ["Mejor rendimiento", _mejorEstudiante()],
          ]),
          pw.SizedBox(height: 18),
          _sectionTitlePdf("Resultados por estudiante"),
          pw.TableHelper.fromTextArray(
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.indigo900),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headers: [
              "Estudiante",
              "Sesiones",
              "Gramática",
              "Pronunciación",
              "Nivel"
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
          pw.SizedBox(height: 18),
          _footerPdf(),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _generarPdfEstudiante(Map<String, dynamic> e) async {
    final pdf = pw.Document();
    final fecha = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _pdfHeader("REPORTE INDIVIDUAL DEL ESTUDIANTE"),
          pw.SizedBox(height: 16),
          _infoBox([
            ["Estudiante", e['nombre'].toString()],
            ["Correo", e['email'].toString()],
            ["Curso", widget.nombreCurso],
            [
              "Fecha de generación",
              "${fecha.day}/${fecha.month}/${fecha.year}"
            ],
            ["Nivel detectado", e['nivel'].toString()],
            ["Sesiones realizadas", e['sesiones'].toString()],
            ["Respuestas registradas", e['respuestas'].toString()],
          ]),
          pw.SizedBox(height: 18),
          _sectionTitlePdf("Desempeño"),
          _scoreRowPdf("Gramática", e['gramatica'], PdfColors.indigo900),
          pw.SizedBox(height: 10),
          _scoreRowPdf("Pronunciación", e['pronunciacion'], PdfColors.red900),
          pw.SizedBox(height: 18),
          _sectionTitlePdf("Recomendación"),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Text(
              _recomendacion(e),
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.SizedBox(height: 18),
          _footerPdf(),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfHeader(String titulo) {
    return pw.Column(
      children: [
        pw.Text(
          "UNIDAD EDUCATIVA INTERCULTURAL BILINGÜE SURUPUCYU",
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          "Aplicación móvil para el fortalecimiento de la destreza Speaking",
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 2, color: PdfColors.indigo900),
        pw.SizedBox(height: 10),
        pw.Text(
          titulo,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.red900,
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionTitlePdf(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.indigo900,
      ),
    );
  }

  pw.Widget _infoBox(List<List<String>> rows) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(1.4),
          1: const pw.FlexColumnWidth(2.4),
        },
        children: rows.map((r) {
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Text(
                  r[0],
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Text(r[1], style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _scoreRowPdf(String label, dynamic valor, PdfColor color) {
    final numero = valor is num ? valor.toInt() : 0;
    final porcentaje = numero.clamp(0, 100);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(valor == null ? "Pendiente" : "$porcentaje%"),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Container(
          height: 10,
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: porcentaje * 4.5,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _footerPdf() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.Text(
          "Reporte generado automáticamente por el sistema de asistencia virtual para Speaking.",
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
