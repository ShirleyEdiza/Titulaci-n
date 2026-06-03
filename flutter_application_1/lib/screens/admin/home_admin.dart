import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';
import '../auth/login_screen.dart';
import 'docentes_page.dart';
import 'estudiantes_page.dart';
import 'cursos/cursos_list_screen.dart';
import 'dashboard_admin.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SpeakApp - Admin",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF9A825))),
            Text("Panel de Administración",
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
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
