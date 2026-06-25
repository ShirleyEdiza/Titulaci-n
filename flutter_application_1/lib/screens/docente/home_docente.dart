import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import 'progreso_estudiantes_screen.dart';
import '../perfil/perfil_screen.dart';

class HomeDocente extends StatefulWidget {
  const HomeDocente({super.key});

  @override
  State<HomeDocente> createState() => _HomeDocenteState();
}

class _HomeDocenteState extends State<HomeDocente> {
  String nombreUsuario = "";
  String uid = "";
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
    _cargarNombre();
  }

  Future<void> _cargarNombre() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      if (mounted && doc.exists) {
        setState(() {
          nombreUsuario =
              (doc.data() as Map<String, dynamic>)['nombre'] ?? 'Docente';
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.person, color: Color(0xFF1A237E), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombreUsuario,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const Text("Docente",
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'perfil') {
                final actualizado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PerfilScreen(),
                  ),
                );

                if (actualizado == true) {
                  await _cargarNombre();
                }
              } else if (value == 'salir') {
                _logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'perfil',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Color(0xFF1A237E)),
                    SizedBox(width: 8),
                    Text("Mi perfil"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'salir',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFFB71C1C)),
                    SizedBox(width: 8),
                    Text("Cerrar sesión"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildPanelTab(),
    );
  }

  // ── TAB 1: PANEL PRINCIPAL ─────────────────────────────────
  Widget _buildPanelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFFB71C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Panel Docente",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                const Text("Monitorea el progreso de tus estudiantes",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 16),
                // Stats rápidas
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('cursos')
                      .where('docente_uid', isEqualTo: uid)
                      .where('activo', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snap) {
                    int totalCursos = snap.data?.docs.length ?? 0;
                    return Row(
                      children: [
                        _buildStatBanner(
                            "$totalCursos", "Cursos", Icons.class_),
                        const SizedBox(width: 20),
                        _EstudiantesTotalBanner(docenteUid: uid),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text("Mis Cursos",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E))),

          const SizedBox(height: 12),

          // Lista de cursos del docente
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('cursos')
                .where('docente_uid', isEqualTo: uid)
                .where('activo', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFB71C1C)));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.class_outlined,
                  titulo: "Sin cursos asignados",
                  subtitulo: "El administrador te asignará cursos próximamente",
                );
              }

              final cursos = snapshot.data!.docs;

              final anios = ['Primero', 'Segundo', 'Tercero'];

              return Column(
                children: anios.map((anio) {
                  final cursosDelAnio = cursos.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['anio'] == anio;
                  }).toList();

                  if (cursosDelAnio.isEmpty) return const SizedBox();

                  final color = anio == 'Primero'
                      ? const Color(0xFF1A237E)
                      : anio == 'Segundo'
                          ? const Color(0xFFB71C1C)
                          : const Color(0xFF4A148C);

                  final titulo = anio == 'Primero'
                      ? '1ro Bachillerato'
                      : anio == 'Segundo'
                          ? '2do Bachillerato'
                          : '3ro Bachillerato';

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
                    children: cursosDelAnio.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      return _CursoDocenteCard(
                        cursoId: doc.id,
                        nombre: data['nombre'] ?? '',
                        tipo: data['tipo'] ?? '',
                        nivel: data['nivel'] ?? 'A1',
                        anio: data['anio'] ?? '',
                        codigo: data['codigo_acceso'] ?? '',
                      );
                    }).toList(),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatBanner(String valor, String label, IconData icono) {
    return Column(
      children: [
        Text(valor,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _EstudiantesTotalBanner({required String docenteUid}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cursos')
          .where('docente_uid', isEqualTo: docenteUid)
          .where('activo', isEqualTo: true)
          .snapshots(),
      builder: (context, cursosSnap) {
        if (!cursosSnap.hasData) {
          return _buildStatBanner("0", "Estudiantes", Icons.people);
        }

        final cursosIds = cursosSnap.data!.docs.map((doc) => doc.id).toList();

        if (cursosIds.isEmpty) {
          return _buildStatBanner("0", "Estudiantes", Icons.people);
        }

        return FutureBuilder<int>(
          future: _contarEstudiantesDocente(cursosIds),
          builder: (context, snap) {
            return _buildStatBanner(
              "${snap.data ?? 0}",
              "Estudiantes",
              Icons.people,
            );
          },
        );
      },
    );
  }

  Future<int> _contarEstudiantesDocente(List<String> cursosIds) async {
    final Set<String> estudiantesUnicos = {};

    for (final cursoId in cursosIds) {
      final snap = await FirebaseFirestore.instance
          .collection('matriculas')
          .where('curso_id', isEqualTo: cursoId)
          .where('activo', isEqualTo: true)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        final estudianteUid = data['estudiante_uid'] ?? '';
        if (estudianteUid.toString().isNotEmpty) {
          estudiantesUnicos.add(estudianteUid);
        }
      }
    }

    return estudiantesUnicos.length;
  }

  Widget _buildAccionCard(
      String label, IconData icono, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icono, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── TAB 2: ESTUDIANTES ─────────────────────────────────────
  Widget _buildEstudiantesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cursos')
          .where('docente_uid', isEqualTo: uid)
          .where('activo', isEqualTo: true)
          .snapshots(),
      builder: (context, cursosSnap) {
        if (cursosSnap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFB71C1C)));
        }

        if (!cursosSnap.hasData || cursosSnap.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            titulo: "Sin cursos asignados",
            subtitulo:
                "Cuando tengas cursos asignados verás tus estudiantes aquí",
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: cursosSnap.data!.docs.map((cursoDoc) {
            var cursoData = cursoDoc.data() as Map<String, dynamic>;
            return _EstudiantesPorCurso(
              cursoId: cursoDoc.id,
              nombreCurso: cursoData['nombre'] ?? '',
              paralelo: cursoData['paralelo'] ?? '',
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String titulo,
    required String subtitulo,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 16)),
          const SizedBox(height: 6),
          Text(subtitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─── CARD CURSO DEL DOCENTE ───────────────────────────────────
class _CursoDocenteCard extends StatelessWidget {
  final String cursoId, nombre, tipo, nivel, anio, codigo;

  const _CursoDocenteCard({
    required this.cursoId,
    required this.nombre,
    required this.tipo,
    required this.nivel,
    required this.anio,
    required this.codigo,
  });

  Color get _color {
    if (anio == 'Primero') return const Color(0xFF1A237E);
    if (anio == 'Segundo') return const Color(0xFFB71C1C);
    return const Color(0xFF4A148C);
  }

  @override
  Widget build(BuildContext context) {
    final titulo = tipo.isNotEmpty ? tipo : nombre;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProgresoEstudiantesScreen(
              cursoId: cursoId,
              nombreCurso: nombre,
            ),
          ),
        );
      },
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bookmark, color: _color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nivel: $nivel',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'Código: $codigo',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.more_vert,
                color: Colors.black87,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ESTUDIANTES POR CURSO ────────────────────────────────────
class _EstudiantesPorCurso extends StatelessWidget {
  final String cursoId, nombreCurso, paralelo;

  const _EstudiantesPorCurso({
    required this.cursoId,
    required this.nombreCurso,
    required this.paralelo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            paralelo.isNotEmpty ? paralelo : nombreCurso,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E)),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('matriculas')
              .where('curso_id', isEqualTo: cursoId)
              .where('activo', isEqualTo: true)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("Sin estudiantes inscritos",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              );
            }

            return Column(
              children: snap.data!.docs.map((doc) {
                String estudianteUid =
                    (doc.data() as Map<String, dynamic>)['estudiante_uid'] ??
                        '';
                return _EstudianteDocenteCard(
                  estudianteUid: estudianteUid,
                  cursoId: cursoId,
                  nombreCurso: nombreCurso,
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _EstudianteDocenteCard extends StatelessWidget {
  final String estudianteUid, cursoId, nombreCurso;

  const _EstudianteDocenteCard({
    required this.estudianteUid,
    required this.cursoId,
    required this.nombreCurso,
  });

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
        String email = data['email'] ?? '';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProgresoEstudiantesScreen(
                  cursoId: cursoId,
                  nombreCurso: nombreCurso,
                  estudianteUidFiltro: estudianteUid,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
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
                  backgroundColor: const Color(0xFFB71C1C).withOpacity(0.1),
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : 'E',
                    style: const TextStyle(
                        color: Color(0xFFB71C1C),
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
                              fontSize: 14,
                              color: Color(0xFF1A237E))),
                      Text(email,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Gramática",
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const Text("--",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E))),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}
