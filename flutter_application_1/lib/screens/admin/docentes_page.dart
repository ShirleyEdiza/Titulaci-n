import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';
import '../../services/admin_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class DocentesPage extends StatelessWidget {
  const DocentesPage({super.key});

  final List<String> anios = const ['Primero', 'Segundo', 'Tercero'];

  Color _colorPorAnio(String anio) {
    if (anio == 'Primero') return const Color(0xFF1A237E);
    if (anio == 'Segundo') return const Color(0xFFB71C1C);
    return const Color(0xFF4A148C);
  }

  Future<void> _crearDocente(BuildContext context) async {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final password = AdminService().generarPassword();

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Registrar docente",
          style: TextStyle(
            color: Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                  labelText: "Nombre del docente",
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Correo electrónico",
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Campo requerido";
                  if (!v.contains("@")) return "Correo inválido";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Clave temporal: $password",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              try {
                final secondaryApp = await Firebase.initializeApp(
                  name: 'SecondaryApp${DateTime.now().millisecondsSinceEpoch}',
                  options: Firebase.app().options,
                );

                final secondaryAuth =
                    FirebaseAuth.instanceFor(app: secondaryApp);

                final cred = await secondaryAuth.createUserWithEmailAndPassword(
                  email: emailCtrl.text.trim(),
                  password: password,
                );

                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(cred.user!.uid)
                    .set({
                  'nombre': nombreCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'rol': 'docente',
                  'activo': true,
                  'fecha_registro': FieldValue.serverTimestamp(),
                  'debe_cambiar_password': true,
                });

                await secondaryAuth.signOut();
                await secondaryApp.delete();

                if (context.mounted) {
                  Navigator.pop(ctx);
                  CustomSnackbar.success(
                    context,
                    "Docente creado correctamente\nClave temporal: $password",
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  CustomSnackbar.error(context, "Error al crear docente");
                }
              }
            },
            child: const Text("Crear"),
          ),
        ],
      ),
    );
  }

  Future<void> _asignarDocente(
    BuildContext context,
    String cursoId,
    String nombreCurso,
  ) async {
    final docentesSnap = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('rol', isEqualTo: 'docente')
        .where('activo', isEqualTo: true)
        .get();

    if (!context.mounted) return;

    if (docentesSnap.docs.isEmpty) {
      CustomSnackbar.warning(
        context,
        "No hay docentes registrados",
      );
      return;
    }

    String? docenteSeleccionado;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Asignar docente a $nombreCurso",
          style: const TextStyle(
            color: Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return DropdownButtonFormField<String>(
              value: docenteSeleccionado,
              hint: const Text("Selecciona un docente"),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.school, color: Color(0xFFB71C1C)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: docentesSnap.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(data['nombre'] ?? 'Docente'),
                );
              }).toList(),
              onChanged: (v) {
                setStateDialog(() => docenteSeleccionado = v);
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (docenteSeleccionado == null) {
                CustomSnackbar.warning(context, "Selecciona un docente");
                return;
              }

              await FirebaseFirestore.instance
                  .collection('cursos')
                  .doc(cursoId)
                  .update({
                'docente_uid': docenteSeleccionado,
              });

              if (context.mounted) {
                Navigator.pop(ctx);
                CustomSnackbar.success(
                  context,
                  "Docente asignado correctamente",
                );
              }
            },
            child: const Text("Asignar"),
          ),
        ],
      ),
    );
  }

  Future<void> _quitarDocente(BuildContext context, String cursoId) async {
    await FirebaseFirestore.instance.collection('cursos').doc(cursoId).update({
      'docente_uid': '',
    });

    if (context.mounted) {
      CustomSnackbar.success(context, "Docente removido del curso");
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
                  "Crea cursos antes de asignar docentes",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _crearDocente(context),
                icon: const Icon(Icons.person_add),
                label: const Text("Registrar nuevo docente"),
              ),
            ),
            const SizedBox(height: 16),
            ...anios.map((anio) {
              final cursosDelAnio = cursos.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['anio'] == anio;
              }).toList();

              return _SeccionAnioDocentes(
                titulo: anio == 'Primero'
                    ? '1ro Bachillerato'
                    : anio == 'Segundo'
                        ? '2do Bachillerato'
                        : '3ro Bachillerato',
                color: _colorPorAnio(anio),
                cursos: cursosDelAnio,
                onAsignar: _asignarDocente,
                onQuitar: _quitarDocente,
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class _SeccionAnioDocentes extends StatelessWidget {
  final String titulo;
  final Color color;
  final List<QueryDocumentSnapshot> cursos;
  final Future<void> Function(BuildContext, String, String) onAsignar;
  final Future<void> Function(BuildContext, String) onQuitar;

  const _SeccionAnioDocentes({
    required this.titulo,
    required this.color,
    required this.cursos,
    required this.onAsignar,
    required this.onQuitar,
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

              return _CursoDocenteCard(
                cursoId: doc.id,
                nombre: data['nombre'] ?? '',
                tipo: data['tipo'] ?? '',
                nivel: data['nivel'] ?? '',
                docenteUid: data['docente_uid'] ?? '',
                color: color,
                onAsignar: onAsignar,
                onQuitar: onQuitar,
              );
            }).toList(),
    );
  }
}

class _CursoDocenteCard extends StatelessWidget {
  final String cursoId;
  final String nombre;
  final String tipo;
  final String nivel;
  final String docenteUid;
  final Color color;
  final Future<void> Function(BuildContext, String, String) onAsignar;
  final Future<void> Function(BuildContext, String) onQuitar;

  const _CursoDocenteCard({
    required this.cursoId,
    required this.nombre,
    required this.tipo,
    required this.nivel,
    required this.docenteUid,
    required this.color,
    required this.onAsignar,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final tituloCurso = tipo.isNotEmpty ? tipo : nombre;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.school, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: docenteUid.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tituloCurso,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        "Nivel: $nivel",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Text(
                        "Sin docente asignado",
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ],
                  )
                : FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(docenteUid)
                        .get(),
                    builder: (context, snap) {
                      final data = snap.data?.data() as Map<String, dynamic>?;

                      final nombreDocente = data?['nombre'] ?? 'Docente';
                      final email = data?['email'] ?? '';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tituloCurso,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            "Nivel: $nivel",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            "Docente: $nombreDocente",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.green),
                          ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          PopupMenuButton<String>(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'asignar') {
                onAsignar(context, cursoId, tituloCurso);
              }

              if (value == 'quitar') {
                onQuitar(context, cursoId);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'asignar',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: color, size: 18),
                    const SizedBox(width: 8),
                    Text(docenteUid.isEmpty ? "Asignar" : "Cambiar"),
                  ],
                ),
              ),
              if (docenteUid.isNotEmpty)
                const PopupMenuItem(
                  value: 'quitar',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove,
                          color: Color(0xFFB71C1C), size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Quitar",
                        style: TextStyle(color: Color(0xFFB71C1C)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
