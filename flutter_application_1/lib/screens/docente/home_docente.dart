import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import 'progreso_estudiantes_screen.dart';

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
          IconButton(
              icon: const Icon(Icons.logout, size: 20), onPressed: _logout),
        ],
      ),
      body: _selectedIndex == 0 ? _buildPanelTab() : _buildEstudiantesTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: const Color(0xFFB71C1C),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Panel"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: "Estudiantes"),
        ],
      ),
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
                        _buildStatBanner("0", "Estudiantes", Icons.people),
                        const SizedBox(width: 20),
                        _buildStatBanner("0", "Sesiones hoy", Icons.today),
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

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return _CursoDocenteCard(
                    cursoId: doc.id,
                    nombre: data['nombre'] ?? '',
                    paralelo: data['paralelo'] ?? '',
                    nivel: data['nivel'] ?? 'A1',
                    anio: data['anio'] ?? '',
                    codigo: data['codigo_acceso'] ?? '',
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 20),

          // Acciones rápidas
          const Text("Acciones rápidas",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E))),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildAccionCard(
                  "Ver Progreso",
                  Icons.bar_chart,
                  const Color(0xFF1A237E),
                  () => setState(() => _selectedIndex = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAccionCard(
                  "Generar Reporte",
                  Icons.picture_as_pdf,
                  const Color(0xFFB71C1C),
                  () => setState(() => _selectedIndex = 1),
                ),
              ),
            ],
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
  final String cursoId, nombre, paralelo, nivel, anio, codigo;

  const _CursoDocenteCard({
    required this.cursoId,
    required this.nombre,
    required this.paralelo,
    required this.nivel,
    required this.anio,
    required this.codigo,
  });

  Color get _color => anio == 'Primero'
      ? const Color(0xFF1A237E)
      : anio == 'Segundo'
          ? const Color(0xFFB71C1C)
          : const Color(0xFF4A148C);

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
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.class_, color: _color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(paralelo.isNotEmpty ? paralelo : nombre,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _color)),
                      Text(nombre,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text("Nivel $nivel",
                      style: TextStyle(
                          fontSize: 11,
                          color: _color,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Estudiantes inscritos
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('matriculas')
                      .where('curso_id', isEqualTo: cursoId)
                      .where('activo', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snap) {
                    int total = snap.data?.docs.length ?? 0;
                    return Row(
                      children: [
                        Icon(Icons.people,
                            size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text("$total estudiantes",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    );
                  },
                ),
                // Ver progreso
                TextButton.icon(
                  onPressed: () {
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
                  icon: const Icon(Icons.bar_chart,
                      size: 16, color: Color(0xFFB71C1C)),
                  label: const Text("Ver progreso",
                      style: TextStyle(
                          color: Color(0xFFB71C1C),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
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
