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
            const Text("Progreso de estudiantes",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text(nombreCurso,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Generar reporte",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Generando reporte... (próximamente)")));
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFB71C1C)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text("Sin estudiantes inscritos",
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              String estUid = (snapshot.data!.docs[index].data()
                      as Map<String, dynamic>)['estudiante_uid'] ??
                  '';
              return _ProgresoEstudianteCard(estudianteUid: estUid);
            },
          );
        },
      ),
    );
  }
}

class _ProgresoEstudianteCard extends StatelessWidget {
  final String estudianteUid;

  const _ProgresoEstudianteCard({required this.estudianteUid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(estudianteUid)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        var data = snap.data!.data() as Map<String, dynamic>? ?? {};
        String nombre = data['nombre'] ?? 'Estudiante';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : 'E',
                      style: const TextStyle(
                          color: Color(0xFF1A237E),
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1A237E))),
                        const Text("Sin sesiones registradas",
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Métricas de progreso
              Row(
                children: [
                  Expanded(
                      child: _buildMetrica(
                          "Gramática", 0.0, const Color(0xFF1A237E))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildMetrica(
                          "Speaking", 0.0, const Color(0xFFB71C1C))),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9A825).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFF9A825).withOpacity(0.3)),
                ),
                child: const Text(
                  "Necesita practicar más Speaking\nTienes un buen nivel A1",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetrica(String label, double valor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text("${(valor * 100).toInt()}%",
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: valor,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 7,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
