import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PanelCursoScreen extends StatelessWidget {
  final String cursoId;
  final String nombreCurso;
  final String estudianteUid;

  const PanelCursoScreen({
    super.key,
    required this.cursoId,
    required this.nombreCurso,
    required this.estudianteUid,
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
            Text(nombreCurso,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const Text("Panel del curso",
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFFB71C1C)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombreCurso,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text("Inglés - SpeakApp",
                      style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Docente del curso
            const Text("Docente",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E))),
            const SizedBox(height: 10),
            _DocenteDelCurso(cursoId: cursoId),

            const SizedBox(height: 20),

            // Participantes
            _ParticipantesDelCurso(
                cursoId: cursoId, estudianteUid: estudianteUid),

            const SizedBox(height: 20),

            // Botón iniciar práctica (próximo sprint)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Próximamente: Asistente virtual"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.mic),
                label: const Text("Iniciar práctica de Speaking",
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocenteDelCurso extends StatelessWidget {
  final String cursoId;

  const _DocenteDelCurso({required this.cursoId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cursos')
          .doc(cursoId)
          .snapshots(),
      builder: (context, cursoSnap) {
        if (!cursoSnap.hasData) return const SizedBox();
        var data = cursoSnap.data!.data() as Map<String, dynamic>;
        String docenteUid = data['docente_uid'] ?? '';

        if (docenteUid.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.person, color: Colors.grey),
                SizedBox(width: 10),
                Text("Sin docente asignado",
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(docenteUid)
              .get(),
          builder: (context, docenteSnap) {
            if (!docenteSnap.hasData) return const SizedBox();
            var docenteData = docenteSnap.data!.data() as Map<String, dynamic>?;
            if (docenteData == null) return const SizedBox();

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF1A237E).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
                    child: Text(
                      (docenteData['nombre'] ?? 'D')[0].toUpperCase(),
                      style: const TextStyle(
                          color: Color(0xFF1A237E),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(docenteData['nombre'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E))),
                        const Text("Docente de Inglés",
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text("Docente",
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ParticipantesDelCurso extends StatelessWidget {
  final String cursoId;
  final String estudianteUid;

  const _ParticipantesDelCurso(
      {required this.cursoId, required this.estudianteUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matriculas')
          .where('curso_id', isEqualTo: cursoId)
          .where('activo', isEqualTo: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();

        List<String> uids = snap.data!.docs
            .map((d) =>
                (d.data() as Map<String, dynamic>)['estudiante_uid'] as String)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("Participantes",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E))),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text("${uids.length}",
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB71C1C),
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (uids.isEmpty)
              const Text("No hay estudiantes inscritos",
                  style: TextStyle(color: Colors.grey))
            else
              ...uids.map((uid) => _EstudianteItem(
                    uid: uid,
                    esYo: uid == estudianteUid,
                  )),
          ],
        );
      },
    );
  }
}

class _EstudianteItem extends StatelessWidget {
  final String uid;
  final bool esYo;

  const _EstudianteItem({required this.uid, required this.esYo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('usuarios').doc(uid).get(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        var data = snap.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: esYo
                ? Border.all(color: const Color(0xFFB71C1C).withOpacity(0.4))
                : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: esYo
                    ? const Color(0xFFB71C1C).withOpacity(0.1)
                    : const Color(0xFF1A237E).withOpacity(0.1),
                child: Text(
                  (data['nombre'] ?? 'E')[0].toUpperCase(),
                  style: TextStyle(
                      color: esYo
                          ? const Color(0xFFB71C1C)
                          : const Color(0xFF1A237E),
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data['nombre'] ?? '',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF1A237E)),
                ),
              ),
              if (esYo)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text("Tú",
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB71C1C),
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        );
      },
    );
  }
}
