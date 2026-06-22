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
            onSelected: (value) {
              if (value == 'perfil') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PerfilScreen(),
                  ),
                );
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
                    final cursos = snap.data?.docs ?? [];
                    final totalCursos = cursos.length;
                    final cursoIds = cursos.map((e) => e.id).toList();

                    if (cursoIds.isEmpty) {
                      return Row(
                        children: [
                          _buildStatBanner("0", "Cursos", Icons.class_),
                          const SizedBox(width: 20),
                          _buildStatBanner("0", "Estudiantes", Icons.people),
                          const SizedBox(width: 20),
                          _buildStatBanner("0", "Sesiones", Icons.mic),
                        ],
                      );
                    }

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('matriculas')
                          .where('activo', isEqualTo: true)
                          .get(),
                      builder: (context, matSnap) {
                        final matriculas = matSnap.data?.docs ?? [];

                        final matriculasDocente = matriculas.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return cursoIds.contains(data['curso_id']);
                        }).toList();

                        final estudiantesUnicos = matriculasDocente
                            .map((doc) => (doc.data()
                                as Map<String, dynamic>)['estudiante_uid'])
                            .where((uid) =>
                                uid != null && uid.toString().isNotEmpty)
                            .toSet();

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatBanner(
                              "$totalCursos",
                              "Cursos",
                              Icons.class_,
                            ),
                            _buildStatBanner(
                              "${estudiantesUnicos.length}",
                              "Estudiantes",
                              Icons.people,
                            ),
                          ],
                        );
                      },
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
                    nombre: data['tipo'] ??
                        data['paralelo'] ??
                        data['nombre'] ??
                        'Curso',
                    paralelo: data['tipo'] ??
                        data['paralelo'] ??
                        data['nombre'] ??
                        'Curso',
                    nivel: data['nivel'] ?? 'A1',
                    anio: data['anio'] ?? '',
                    codigo: data['codigo_acceso'] ?? '',
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
                      Text(nombre,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _color)),
                      Text(
                        "$anio Bachillerato",
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
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
