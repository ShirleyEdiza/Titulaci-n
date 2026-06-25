import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RetroalimentacionScreen extends StatefulWidget {
  final String cursoId;

  const RetroalimentacionScreen({
    super.key,
    required this.cursoId,
  });

  @override
  State<RetroalimentacionScreen> createState() =>
      _RetroalimentacionScreenState();
}

class _RetroalimentacionScreenState extends State<RetroalimentacionScreen> {
  bool mostrarActual = true;
  bool mostrarAnteriores = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text("No hay usuario autenticado"));
    }

    return Container(
      color: const Color(0xFFF5F6FA),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('analisis')
            .where('estudiante_uid', isEqualTo: uid)
            .where('curso_id', isEqualTo: widget.cursoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error al cargar la retroalimentación"),
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
                  "Aún no tienes retroalimentación escrita.\nRealiza una interacción con el asistente y presiona Finalizar.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            );
          }

          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;

            final fechaA = dataA['fecha_analisis'];
            final fechaB = dataB['fecha_analisis'];

            if (fechaA is Timestamp && fechaB is Timestamp) {
              return fechaB.compareTo(fechaA);
            }
            return 0;
          });

          final ultima = docs.first.data() as Map<String, dynamic>;
          final anteriores = docs.skip(1).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: _cardDecoration(),
                  child: ExpansionTile(
                    key: ValueKey("actual_$mostrarActual"),
                    initiallyExpanded: mostrarActual,
                    onExpansionChanged: (value) {
                      setState(() {
                        mostrarActual = value;
                        if (value) mostrarAnteriores = false;
                      });
                    },
                    iconColor: const Color(0xFF1A237E),
                    collapsedIconColor: const Color(0xFF1A237E),
                    title: const Text(
                      "Retroalimentación actual",
                      style: TextStyle(
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text("Análisis gramatical más reciente"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: _FeedbackCard(
                          analisis: ultima,
                          destacada: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: _cardDecoration(),
                  child: anteriores.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            "No hay retroalimentaciones anteriores.",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ExpansionTile(
                          key: ValueKey("anteriores_$mostrarAnteriores"),
                          initiallyExpanded: mostrarAnteriores,
                          onExpansionChanged: (value) {
                            setState(() {
                              mostrarAnteriores = value;
                              if (value) mostrarActual = false;
                            });
                          },
                          iconColor: const Color(0xFF1A237E),
                          collapsedIconColor: const Color(0xFF1A237E),
                          title: const Text(
                            "Retroalimentaciones anteriores",
                            style: TextStyle(
                              color: Color(0xFF1A237E),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.58,
                              child: Scrollbar(
                                thumbVisibility: true,
                                radius: const Radius.circular(12),
                                thickness: 5,
                                child: ListView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  itemCount: anteriores.length,
                                  itemBuilder: (context, index) {
                                    final data = anteriores[index].data()
                                        as Map<String, dynamic>;

                                    return _FeedbackExpansionCard(
                                      analisis: data,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
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

class _FeedbackExpansionCard extends StatelessWidget {
  final Map<String, dynamic> analisis;

  const _FeedbackExpansionCard({
    required this.analisis,
  });

  @override
  Widget build(BuildContext context) {
    final textoOriginal = analisis['texto_original'] ?? '';
    final nivel = analisis['nivel_detectado'] ?? 'A1';
    final puntuacion = analisis['puntuacion_gramatica'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1A237E).withOpacity(0.12),
        ),
      ),
      child: ExpansionTile(
        iconColor: const Color(0xFF1A237E),
        collapsedIconColor: const Color(0xFF1A237E),
        title: Text(
          textoOriginal.toString().length > 35
              ? "${textoOriginal.toString().substring(0, 35)}..."
              : textoOriginal.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        subtitle:
            Text("Nivel $nivel • Puntuación ${puntuacion.toStringAsFixed(0)}"),
        children: [
          _FeedbackCard(
            analisis: analisis,
            destacada: false,
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final Map<String, dynamic> analisis;
  final bool destacada;

  const _FeedbackCard({
    required this.analisis,
    this.destacada = false,
  });

  @override
  Widget build(BuildContext context) {
    final textoOriginal = analisis['texto_original'] ?? '';
    final textoCorregido = analisis['texto_corregido'] ?? '';
    final nivel = analisis['nivel_detectado'] ?? 'A1';
    final puntuacion = analisis['puntuacion_gramatica'] ?? 0;
    final errores = List.from(analisis['errores_detectados'] ?? []);

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: destacada
              ? const Color(0xFFB71C1C).withOpacity(0.35)
              : const Color(0xFF1A237E).withOpacity(0.15),
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
          _header(puntuacion, nivel),
          const SizedBox(height: 16),
          _sectionTitle("Texto original"),
          _box(textoOriginal),
          const SizedBox(height: 12),
          _sectionTitle("Texto corregido"),
          _box(
            textoCorregido,
            color: const Color(0xFFE8F5E9),
          ),
          const SizedBox(height: 12),
          _sectionTitle("Errores detectados"),
          errores.isEmpty
              ? const Text(
                  "No se detectaron errores importantes.",
                  style: TextStyle(color: Colors.green),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errores
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text("• $e"),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _header(dynamic puntuacion, String nivel) {
    final valor = puntuacion is num ? puntuacion.toDouble() : 0.0;

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF1A237E),
          child: Text(
            valor.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Análisis gramatical",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              Text(
                "Nivel detectado: $nivel",
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF1A237E),
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
