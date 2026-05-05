import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParticipantesScreen extends StatelessWidget {
  final String cursoId;
  final String nombreCurso;

  const ParticipantesScreen({
    super.key,
    required this.cursoId,
    required this.nombreCurso,
  });

  @override
  Widget build(BuildContext context) {
    String miUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Participantes",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF9A825))),
            Text(nombreCurso,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Docente del curso
            const Text("Docente",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E))),
            const SizedBox(height: 10),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cursos')
                  .doc(cursoId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                String docenteUid = data['docente_uid'] ?? '';

                if (docenteUid.isEmpty) {
                  return _InfoCard(
                    icon: Icons.person_off,
                    titulo: "Sin docente asignado",
                    subtitulo: "El administrador asignará un docente pronto",
                    color: Colors.grey,
                  );
                }

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(docenteUid)
                      .get(),
                  builder: (context, docenteSnap) {
                    if (!docenteSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var docenteData =
                        docenteSnap.data!.data() as Map<String, dynamic>? ?? {};
                    return _ParticipanteCard(
                      nombre: docenteData['nombre'] ?? 'Docente',
                      email: docenteData['email'] ?? '',
                      esDocente: true,
                      esMio: false,
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // Estudiantes del curso
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('matriculas')
                  .where('curso_id', isEqualTo: cursoId)
                  .where('activo', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                int total = snapshot.data!.docs.length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Estudiantes ($total)",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E))),
                    const SizedBox(height: 10),
                    if (snapshot.data!.docs.isEmpty)
                      _InfoCard(
                        icon: Icons.people_outline,
                        titulo: "Sin compañeros aún",
                        subtitulo: "Sé el primero en unirte",
                        color: Colors.grey,
                      )
                    else
                      ...snapshot.data!.docs.map((doc) {
                        String estUid = (doc.data()
                                as Map<String, dynamic>)['estudiante_uid'] ??
                            '';
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(estUid)
                              .get(),
                          builder: (context, estSnap) {
                            if (!estSnap.hasData) return const SizedBox();
                            var estData =
                                estSnap.data!.data() as Map<String, dynamic>? ??
                                    {};
                            return _ParticipanteCard(
                              nombre: estData['nombre'] ?? 'Estudiante',
                              email: estData['email'] ?? '',
                              esDocente: false,
                              esMio: estUid == miUid,
                            );
                          },
                        );
                      }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipanteCard extends StatelessWidget {
  final String nombre, email;
  final bool esDocente, esMio;

  const _ParticipanteCard({
    required this.nombre,
    required this.email,
    required this.esDocente,
    required this.esMio,
  });

  @override
  Widget build(BuildContext context) {
    Color color = esDocente
        ? const Color(0xFF1A237E)
        : esMio
            ? const Color(0xFFB71C1C)
            : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: esMio
            ? Border.all(color: const Color(0xFFB71C1C).withOpacity(0.4))
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.12),
            child: Text(
              nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(nombre,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: color)),
                    ),
                    if (esMio)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB71C1C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text("Tú",
                            style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFB71C1C),
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                Text(
                  esDocente ? "Docente de Inglés" : email,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Icon(
            esDocente ? Icons.school : Icons.person,
            color: color.withOpacity(0.5),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String titulo, subtitulo;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              Text(subtitulo,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
