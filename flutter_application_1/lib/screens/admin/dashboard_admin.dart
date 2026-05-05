import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardAdmin extends StatelessWidget {
  const DashboardAdmin({super.key});

  Widget _card(String titulo, int valor, IconData icono) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black.withOpacity(0.05),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icono, size: 30, color: const Color(0xFF1A237E)),
            const SizedBox(height: 10),
            Text("$valor",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(titulo, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        int docentes = snapshot.data!.docs
            .where((e) => (e.data() as Map)['rol'] == 'docente')
            .length;

        int estudiantes = snapshot.data!.docs
            .where((e) => (e.data() as Map)['rol'] == 'estudiante')
            .length;

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  _card("Docentes", docentes, Icons.school),
                  _card("Estudiantes", estudiantes, Icons.people),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
