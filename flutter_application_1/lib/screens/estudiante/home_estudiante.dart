import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import 'ingreso_codigo_screen.dart';
import 'participantes_screen.dart';
import 'asistente_virtual_screen.dart';
import 'retroalimentacion_screen.dart';
import 'retroalimentacion_oral_screen.dart';
import 'progreso_screen.dart';

class HomeEstudiante extends StatefulWidget {
  const HomeEstudiante({super.key});

  @override
  State<HomeEstudiante> createState() => _HomeEstudianteState();
}

class _HomeEstudianteState extends State<HomeEstudiante> {
  String nombreUsuario = "";
  String uid = "";
  int _selectedIndex = 0;
  int _retroSeleccionada = 0; // 0 escrita, 1 oral

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
              (doc.data() as Map<String, dynamic>)['nombre'] ?? 'Estudiante';
        });
      }
    } catch (e) {
      debugPrint('Error cargando nombre: $e');
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
                const Text("Estudiante",
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout, size: 20),
              onPressed: _logout,
              tooltip: "Cerrar sesión"),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildCursosTab()
          : _selectedIndex == 1
              ? ProgresoScreen(estudianteUid: uid)
              : _buildRetroalimentacionTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: const Color(0xFFB71C1C),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.class_), label: "Mis Cursos"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Progreso"),
          BottomNavigationBarItem(
              icon: Icon(Icons.feedback), label: "Retroalimentación"),
        ],
      ),
    );
  }

  // ── TAB 1: CURSOS ──────────────────────────────────────────
  Widget _buildCursosTab() {
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("¡Practica tu Speaking!",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      SizedBox(height: 4),
                      Text("Únete a tus cursos con el código de clase",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.mic, color: Colors.white54, size: 40),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Botón incorporarse a una clase
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _mostrarDialogoUnirse(context),
              icon: const Icon(Icons.add, color: Color(0xFF1A237E)),
              label: const Text("+ Incorporarse a una clase",
                  style: TextStyle(
                      color: Color(0xFF1A237E),
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text("Mis Cursos",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E))),

          const SizedBox(height: 12),

          // Lista de cursos inscritos
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('matriculas')
                .where('estudiante_uid', isEqualTo: uid)
                .where('activo', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFB71C1C)));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.school_outlined,
                  titulo: "Aún no tienes cursos",
                  subtitulo:
                      "Presiona '+ Incorporarse a una clase' e ingresa el código de tu docente",
                );
              }

              return Column(
                children: snapshot.data!.docs.map((matriculaDoc) {
                  String cursoId = (matriculaDoc.data()
                          as Map<String, dynamic>)['curso_id'] ??
                      '';
                  return _CursoInscritoCard(
                      cursoId: cursoId, estudianteUid: uid);
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 20),

          // Asistente virtual
          _buildAsistenteVirtualCard(),
        ],
      ),
    );
  }

  void _mostrarDialogoUnirse(BuildContext context) {
    final codigoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Incorporarse a una clase",
            style: TextStyle(
                color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Ingresa el código proporcionado por tu docente",
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codigoCtrl,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Color(0xFF1A237E)),
              decoration: InputDecoration(
                hintText: "Ej: MSY-6RU",
                hintStyle: const TextStyle(
                    color: Colors.grey, fontSize: 18, letterSpacing: 3),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFB71C1C), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (codigoCtrl.text.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IngresoCodigoScreen(
                      codigoInicial: codigoCtrl.text.trim(),
                    ),
                  ),
                );
              }
            },
            child: const Text("Unirse"),
          ),
        ],
      ),
    );
  }

  Widget _buildAsistenteVirtualCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matriculas')
          .where('estudiante_uid', isEqualTo: uid)
          .where('activo', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Asistente Virtual bloqueado",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      Text(
                        "Ingresa a un curso con tu código de clase para activarlo.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final matricula =
            snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final cursoId = matricula['curso_id'] ?? '';

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('cursos')
              .doc(cursoId)
              .get(),
          builder: (context, cursoSnap) {
            if (!cursoSnap.hasData || !cursoSnap.data!.exists) {
              return const SizedBox();
            }

            final cursoData =
                cursoSnap.data!.data() as Map<String, dynamic>? ?? {};

            final nombreCurso =
                "${cursoData['anio'] ?? ''} - ${cursoData['tipo'] ?? cursoData['nombre'] ?? ''}";

            return Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9A825).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Color(0xFFF9A825),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Asistente Virtual",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        Text(
                          "Practica speaking con preguntas guiadas",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final resultado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AsistenteVirtualScreen(
                            cursoId: cursoId,
                            nombreCurso: nombreCurso,
                          ),
                        ),
                      );

                      if (resultado == "ver_retro_escrita") {
                        setState(() {
                          _selectedIndex = 2;
                          _retroSeleccionada = 0;
                        });
                      }

                      if (resultado == "ver_retro_oral") {
                        setState(() {
                          _selectedIndex = 2;
                          _retroSeleccionada = 1;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9A825),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    child: const Text(
                      "Iniciar",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── TAB 2: PROGRESO ────────────────────────────────────────
  Widget _buildProgresoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Mi Progreso",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E))),
          const SizedBox(height: 16),

          // Tarjetas de estadísticas
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      "0", "Sesiones", Icons.mic, const Color(0xFF1A237E))),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard("0 min", "Practicados", Icons.timer,
                      const Color(0xFFB71C1C))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard("0%", "Pronunciación",
                      Icons.record_voice_over, const Color(0xFF4A148C))),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard("0%", "Gramática", Icons.spellcheck,
                      const Color(0xFFF9A825))),
            ],
          ),

          const SizedBox(height: 24),

          // Gráfico de progreso placeholder
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                const Text("Progreso semanal",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                const SizedBox(height: 20),
                SizedBox(
                  height: 150,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar("L", 0.2, const Color(0xFF1A237E)),
                      _buildBar("M", 0.5, const Color(0xFFB71C1C)),
                      _buildBar("Mi", 0.3, const Color(0xFF1A237E)),
                      _buildBar("J", 0.7, const Color(0xFFB71C1C)),
                      _buildBar("V", 0.4, const Color(0xFF1A237E)),
                      _buildBar("S", 0.1, const Color(0xFFB71C1C)),
                      _buildBar("D", 0.0, Colors.grey.shade300),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Retroalimentación reciente
          Container(
            width: double.infinity,
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
                const Text("Resumen de habilidades",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                const SizedBox(height: 16),
                _buildHabilidad("Gramática", 0.65, const Color(0xFF1A237E)),
                const SizedBox(height: 12),
                _buildHabilidad("Pronunciación", 0.80, const Color(0xFFB71C1C)),
                const SizedBox(height: 12),
                _buildHabilidad("Fluidez", 0.50, const Color(0xFF4A148C)),
                const SizedBox(height: 12),
                _buildHabilidad("Vocabulario", 0.70, const Color(0xFFF9A825)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double altura, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 120 * altura,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildHabilidad(String nombre, double valor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(nombre,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            Text("${(valor * 100).toInt()}%",
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: valor,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  // ── TAB 3: RETROALIMENTACIÓN ───────────────────────────────
  Widget _buildRetroalimentacionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Retroalimentación",
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
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _retroSeleccionada = 0;
                    });
                  },
                  icon: const Icon(Icons.edit_note),
                  label: const Text("Escrita"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _retroSeleccionada == 0
                        ? const Color(0xFF1A237E)
                        : Colors.grey.shade300,
                    foregroundColor:
                        _retroSeleccionada == 0 ? Colors.white : Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _retroSeleccionada = 1;
                    });
                  },
                  icon: const Icon(Icons.record_voice_over),
                  label: const Text("Oral"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _retroSeleccionada == 1
                        ? const Color(0xFFB71C1C)
                        : Colors.grey.shade300,
                    foregroundColor:
                        _retroSeleccionada == 1 ? Colors.white : Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_retroSeleccionada == 0)
            _buildRetroEscrita()
          else
            _buildRetroOral(),
        ],
      ),
    );
  }

  Widget _buildRetroEscrita() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: Color(0xFF1A237E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Retroalimentación escrita",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Retroalimentación gramatical de tu interacción con el asistente virtual.",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 500,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('matriculas')
                  .where('estudiante_uid', isEqualTo: uid)
                  .where('activo', isEqualTo: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.article_outlined,
                    titulo: "Sin sesiones aún",
                    subtitulo:
                        "Completa una conversación con el asistente para ver tu retroalimentación.",
                  );
                }

                final matricula =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;

                final cursoId = matricula['curso_id'] ?? '';

                return RetroalimentacionScreen(
                  cursoId: cursoId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetroOral() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.record_voice_over,
                  color: Color(0xFFB71C1C),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Retroalimentación oral",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFFB71C1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Retroalimentación sobre pronunciación y palabras a practicar.",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 500,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('matriculas')
                  .where('estudiante_uid', isEqualTo: uid)
                  .where('activo', isEqualTo: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.mic_none,
                    titulo: "Sin sesiones aún",
                    subtitulo:
                        "Completa una conversación para ver tu retroalimentación oral.",
                  );
                }

                final matricula =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;

                final cursoId = matricula['curso_id'] ?? '';

                return RetroalimentacionOralScreen(
                  cursoId: cursoId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String valor, String label, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 26),
          const SizedBox(height: 8),
          Text(valor,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String titulo,
    required String subtitulo,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 50, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(subtitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─── CARD CURSO INSCRITO ──────────────────────────────────────
class _CursoInscritoCard extends StatelessWidget {
  final String cursoId;
  final String estudianteUid;

  const _CursoInscritoCard(
      {required this.cursoId, required this.estudianteUid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('cursos').doc(cursoId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        if (!snapshot.data!.exists) return const SizedBox();

        var data = snapshot.data!.data() as Map<String, dynamic>;
        String nombre = data['nombre'] ?? '';
        String paralelo = data['paralelo'] ?? '';
        String nivel = data['nivel'] ?? 'A1';
        String anio = data['anio'] ?? '';

        Color color = anio == 'Primero'
            ? const Color(0xFF1A237E)
            : anio == 'Segundo'
                ? const Color(0xFFB71C1C)
                : const Color(0xFF4A148C);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ParticipantesScreen(
                  cursoId: cursoId,
                  nombreCurso: nombre,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.class_, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paralelo.isNotEmpty ? paralelo : nombre,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color),
                      ),
                      Text(nombre,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text("Nivel $nivel",
                            style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text("Inscrito",
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
