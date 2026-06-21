import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import 'docentes_page.dart';
import 'estudiantes_page.dart';
import 'cursos/cursos_list_screen.dart';
import 'dashboard_admin.dart';
import '../perfil/perfil_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  String nombreAdmin = "Administrador";

  @override
  void initState() {
    super.initState();
    _cargarNombreAdmin();
  }

  Future<void> _cargarNombreAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    if (!mounted) return;

    setState(() {
      nombreAdmin =
          doc.data()?['nombre'] ?? user.displayName ?? "Administrador";
    });
  }

  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardAdmin(),
    CursosListScreen(),
    DocentesPage(),
    EstudiantesPage(),
  ];

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nombreAdmin,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF9A825))),
            Text("Panel de Administración",
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'perfil') {
                final actualizado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PerfilScreen()),
                );

                if (actualizado == true) {
                  await _cargarNombreAdmin();
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
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: const Color(0xFFB71C1C),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.class_), label: "Cursos"),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "Docentes"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: "Estudiantes"),
        ],
      ),
    );
  }
}
