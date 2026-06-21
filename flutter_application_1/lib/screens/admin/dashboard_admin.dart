import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardAdmin extends StatelessWidget {
  const DashboardAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, usuariosSnap) {
        if (!usuariosSnap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
          );
        }

        final usuarios = usuariosSnap.data!.docs;

        final docentes = usuarios.where((e) {
          final data = e.data() as Map<String, dynamic>;
          return data['rol'] == 'docente' && data['activo'] == true;
        }).length;

        final estudiantes = usuarios.where((e) {
          final data = e.data() as Map<String, dynamic>;
          return data['rol'] == 'estudiante' && data['activo'] == true;
        }).length;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('cursos')
              .where('activo', isEqualTo: true)
              .snapshots(),
          builder: (context, cursosSnap) {
            final cursosDocs = cursosSnap.data?.docs ?? [];

            final cursosUnicos = <String>{};

            for (final doc in cursosDocs) {
              final data = doc.data() as Map<String, dynamic>;

              final anio = (data['anio'] ?? '').toString().trim().toLowerCase();
              final nivel =
                  (data['nivel'] ?? '').toString().trim().toLowerCase();
              final nombre =
                  (data['nombre'] ?? '').toString().trim().toLowerCase();
              final paralelo = (data['paralelo'] ?? data['tipo'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();

              if (anio.isEmpty || nivel.isEmpty) continue;

              final clave = "$anio-$nombre-$paralelo-$nivel";
              cursosUnicos.add(clave);
            }

            final cursos = cursosUnicos.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _welcomeCard(),
                  const SizedBox(height: 18),
                  const Text(
                    "Resumen general",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _statCard(
                        titulo: "Cursos activos",
                        valor: cursos,
                        icono: Icons.class_,
                        color: const Color(0xFF1A237E),
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        titulo: "Docentes",
                        valor: docentes,
                        icono: Icons.school,
                        color: const Color(0xFFB71C1C),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statCard(
                        titulo: "Estudiantes",
                        valor: estudiantes,
                        icono: Icons.people,
                        color: const Color(0xFF4A148C),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Módulos disponibles",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _moduleCard(
                    icono: Icons.class_,
                    titulo: "Gestión de cursos",
                    descripcion: "Crear, editar y administrar cursos activos.",
                  ),
                  _moduleCard(
                    icono: Icons.school,
                    titulo: "Gestión de docentes",
                    descripcion: "Registrar, consultar y asignar docentes.",
                  ),
                  _moduleCard(
                    icono: Icons.people,
                    titulo: "Gestión de estudiantes",
                    descripcion:
                        "Asignar, mover o retirar estudiantes de cursos.",
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _welcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A237E),
            Color(0xFF283593),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Panel de administración",
            style: TextStyle(
              color: Color(0xFFF9A825),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Gestiona cursos, docentes y estudiantes de SpeakApp.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String titulo,
    required int valor,
    required IconData icono,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icono, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              "$valor",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard({
    required IconData icono,
    required String titulo,
    required String descripcion,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF1A237E).withOpacity(0.10),
            child: Icon(icono, color: const Color(0xFF1A237E)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descripcion,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
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
          blurRadius: 10,
          offset: const Offset(0, 4),
          color: Colors.black.withOpacity(0.06),
        ),
      ],
    );
  }
}
