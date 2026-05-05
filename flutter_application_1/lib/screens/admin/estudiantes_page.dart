import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';

class EstudiantesPage extends StatelessWidget {
  const EstudiantesPage({super.key});

  final List<String> anios = const ['Primero', 'Segundo', 'Tercero'];

  Color _colorPorAnio(String anio) {
    if (anio == 'Primero') return const Color(0xFF1A237E);
    if (anio == 'Segundo') return const Color(0xFFB71C1C);
    return const Color(0xFF4A148C);
  }

  Future<void> _eliminarDelCurso(
      BuildContext context, String matriculaId) async {
    await FirebaseFirestore.instance
        .collection('matriculas')
        .doc(matriculaId)
        .update({'activo': false});

    if (context.mounted) {
      CustomSnackbar.success(context, "Estudiante eliminado del curso");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cursos')
          .where('activo', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Error al cargar cursos",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
          );
        }

        final cursos = snapshot.data?.docs ?? [];

        if (cursos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.class_, size: 70, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text(
                  "No hay cursos creados",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const Text(
                  "Primero crea cursos para ver estudiantes",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: anios.map((anio) {
            final cursosDelAnio = cursos.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['anio'] == anio;
            }).toList();

            return _SeccionAnioEstudiantes(
              titulo: anio == 'Primero'
                  ? '1ro Bachillerato'
                  : anio == 'Segundo'
                      ? '2do Bachillerato'
                      : '3ro Bachillerato',
              color: _colorPorAnio(anio),
              cursos: cursosDelAnio,
              onEliminar: _eliminarDelCurso,
            );
          }).toList(),
        );
      },
    );
  }
}

class _SeccionAnioEstudiantes extends StatelessWidget {
  final String titulo;
  final Color color;
  final List<QueryDocumentSnapshot> cursos;
  final Future<void> Function(BuildContext, String) onEliminar;

  const _SeccionAnioEstudiantes({
    required this.titulo,
    required this.color,
    required this.cursos,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      title: Text(
        titulo,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      children: cursos.isEmpty
          ? [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  "Aún no hay cursos en este año",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ]
          : cursos.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return _CursoEstudiantesCard(
                cursoId: doc.id,
                nombre: data['nombre'] ?? '',
                tipo: data['tipo'] ?? '',
                nivel: data['nivel'] ?? '',
                color: color,
                onEliminar: onEliminar,
              );
            }).toList(),
    );
  }
}

class _CursoEstudiantesCard extends StatelessWidget {
  final String cursoId;
  final String nombre;
  final String tipo;
  final String nivel;
  final Color color;
  final Future<void> Function(BuildContext, String) onEliminar;

  const _CursoEstudiantesCard({
    required this.cursoId,
    required this.nombre,
    required this.tipo,
    required this.nivel,
    required this.color,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.people, color: color),
        ),
        title: Text(
          tipo.isNotEmpty ? tipo : nombre,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "Nivel: $nivel",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('matriculas')
                .where('curso_id', isEqualTo: cursoId)
                .where('activo', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: Color(0xFFB71C1C),
                  ),
                );
              }

              final matriculas = snapshot.data?.docs ?? [];

              if (matriculas.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Aún sin estudiantes",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                );
              }

              return Column(
                children: matriculas.map((matriculaDoc) {
                  final matricula = matriculaDoc.data() as Map<String, dynamic>;
                  final estudianteUid = matricula['estudiante_uid'] ?? '';

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(estudianteUid)
                        .get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) {
                        return const SizedBox();
                      }

                      final userData =
                          userSnap.data!.data() as Map<String, dynamic>?;

                      final nombre = userData?['nombre'] ?? 'Estudiante';
                      final email = userData?['email'] ?? '';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFFB71C1C).withOpacity(0.1),
                          child: Text(
                            nombre.isNotEmpty ? nombre[0].toUpperCase() : 'E',
                            style: const TextStyle(
                              color: Color(0xFFB71C1C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        subtitle: Text(
                          email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.person_remove,
                            color: Color(0xFFB71C1C),
                          ),
                          onPressed: () => onEliminar(context, matriculaDoc.id),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
