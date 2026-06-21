import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';

class EstudiantesPage extends StatefulWidget {
  const EstudiantesPage({super.key});

  @override
  State<EstudiantesPage> createState() => _EstudiantesPageState();
}

class _EstudiantesPageState extends State<EstudiantesPage> {
  final List<String> anios = const ['Primero', 'Segundo', 'Tercero'];

  Color _colorPorAnio(String anio) {
    if (anio == 'Primero') return const Color(0xFF1A237E);
    if (anio == 'Segundo') return const Color(0xFFB71C1C);
    return const Color(0xFF4A148C);
  }

  Future<void> _agregarEstudiante(
    BuildContext context,
    String cursoId,
    String nombreCurso,
  ) async {
    final estudiantes = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('rol', isEqualTo: 'estudiante')
        .where('activo', isEqualTo: true)
        .get();

    final matriculasActivas = await FirebaseFirestore.instance
        .collection('matriculas')
        .where('activo', isEqualTo: true)
        .get();

    final estudiantesYaAsignados = matriculasActivas.docs
        .map((doc) => doc.data()['estudiante_uid'])
        .toSet();
    final estudiantesDisponibles = estudiantes.docs.where((doc) {
      return !estudiantesYaAsignados.contains(doc.id);
    }).toList();

    estudiantesDisponibles.sort((a, b) {
      final dataA = a.data();
      final dataB = b.data();

      final nombreA = (dataA['nombre'] ?? '').toString().toLowerCase();
      final nombreB = (dataB['nombre'] ?? '').toString().toLowerCase();

      return nombreA.compareTo(nombreB);
    });

    if (!context.mounted) return;

    if (estudiantesDisponibles.isEmpty) {
      CustomSnackbar.warning(
        context,
        "No hay estudiantes disponibles para agregar",
      );
      return;
    }

    String filtro = "";
    String? estudianteSeleccionado;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final estudiantesFiltrados = estudiantesDisponibles.where((doc) {
            final data = doc.data();
            final nombre = (data['nombre'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            final busqueda = filtro.toLowerCase().trim();

            return nombre.contains(busqueda) || email.contains(busqueda);
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Agregar estudiante",
              style: const TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nombreCurso,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Buscar por nombre o correo",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFB71C1C),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setStateDialog(() {
                        filtro = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 320,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.25),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: estudiantesFiltrados.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              "No se encontraron estudiantes",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: estudiantesFiltrados.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: Colors.grey.withOpacity(0.2),
                            ),
                            itemBuilder: (context, index) {
                              final doc = estudiantesFiltrados[index];
                              final data = doc.data();

                              final nombre = data['nombre'] ?? 'Estudiante';
                              final email = data['email'] ?? '';
                              final seleccionado =
                                  estudianteSeleccionado == doc.id;

                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  backgroundColor: seleccionado
                                      ? const Color(0xFFB71C1C)
                                      : const Color(0xFFB71C1C)
                                          .withOpacity(0.12),
                                  child: Text(
                                    nombre.toString().isNotEmpty
                                        ? nombre.toString()[0].toUpperCase()
                                        : "E",
                                    style: TextStyle(
                                      color: seleccionado
                                          ? Colors.white
                                          : const Color(0xFFB71C1C),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  nombre.toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A237E),
                                  ),
                                ),
                                subtitle: Text(
                                  email.toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: seleccionado
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                    : null,
                                onTap: () {
                                  setStateDialog(() {
                                    estudianteSeleccionado = doc.id;
                                  });
                                },
                              );
                            },
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
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (estudianteSeleccionado == null) {
                    CustomSnackbar.warning(
                      context,
                      "Selecciona un estudiante",
                    );
                    return;
                  }

                  await FirebaseFirestore.instance
                      .collection('matriculas')
                      .add({
                    'estudiante_uid': estudianteSeleccionado,
                    'curso_id': cursoId,
                    'activo': true,
                    'fecha_ingreso': FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    CustomSnackbar.success(
                      context,
                      "Estudiante agregado correctamente",
                    );
                  }
                },
                icon: const Icon(Icons.person_add),
                label: const Text("Agregar"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _moverEstudiante(
    BuildContext context,
    String matriculaId,
    String estudianteUid,
    String cursoActualId,
  ) async {
    final cursos = await FirebaseFirestore.instance
        .collection('cursos')
        .where('activo', isEqualTo: true)
        .get();

    if (!context.mounted) return;

    final cursosDisponibles = cursos.docs.where((doc) {
      return doc.id != cursoActualId;
    }).toList();

    if (cursosDisponibles.isEmpty) {
      CustomSnackbar.warning(context, "No hay otro curso disponible");
      return;
    }

    String? cursoDestino;

    final movido = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Mover estudiante",
          style: TextStyle(
            color: Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return DropdownButtonFormField<String>(
              value: cursoDestino,
              isExpanded: true,
              hint: const Text("Selecciona curso destino"),
              decoration: InputDecoration(
                prefixIcon:
                    const Icon(Icons.swap_horiz, color: Color(0xFFB71C1C)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: cursosDisponibles.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                final nombreCurso = (data['tipo'] ??
                        data['paralelo'] ??
                        data['nombre'] ??
                        'Curso')
                    .toString();

                final textoCurso =
                    "${data['anio'] ?? ''} - $nombreCurso - Nivel ${data['nivel'] ?? ''}";

                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(
                    textoCurso,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (v) {
                setStateDialog(() => cursoDestino = v);
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (cursoDestino == null) {
                CustomSnackbar.warning(context, "Selecciona un curso destino");
                return;
              }

              final existeDestino = await FirebaseFirestore.instance
                  .collection('matriculas')
                  .where('estudiante_uid', isEqualTo: estudianteUid)
                  .where('curso_id', isEqualTo: cursoDestino)
                  .where('activo', isEqualTo: true)
                  .get();

              if (existeDestino.docs.isNotEmpty) {
                if (context.mounted) {
                  CustomSnackbar.warning(
                    context,
                    "El estudiante ya está en el curso destino",
                  );
                }
                return;
              }

              await FirebaseFirestore.instance
                  .collection('matriculas')
                  .doc(matriculaId)
                  .update({'activo': false});

              await FirebaseFirestore.instance.collection('matriculas').add({
                'estudiante_uid': estudianteUid,
                'curso_id': cursoDestino,
                'activo': true,
                'fecha_ingreso': FieldValue.serverTimestamp(),
              });

              if (ctx.mounted) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text("Mover"),
          ),
        ],
      ),
    );

    if (movido == true && context.mounted) {
      CustomSnackbar.success(
        context,
        "Estudiante movido correctamente",
      );
    }
  }

  Future<void> _eliminarDelCurso(
    BuildContext context,
    String matriculaId,
    String nombre,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Eliminar del curso",
          style: TextStyle(
            color: Color(0xFFB71C1C),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "¿Está seguro de eliminar a '$nombre' de este curso?\n\nNo se eliminará su cuenta, solo su matrícula.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance
          .collection('matriculas')
          .doc(matriculaId)
          .update({'activo': false});

      if (context.mounted) {
        CustomSnackbar.success(context, "Estudiante eliminado del curso");
      }
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

        final cursosFiltrados = snapshot.data?.docs ?? [];

        if (cursosFiltrados.isEmpty) {
          return const Center(
            child: Text(
              "Primero crea cursos para gestionar estudiantes",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: anios.map((anio) {
                  final cursosDelAnio = cursosFiltrados.where((doc) {
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
                    onAgregar: _agregarEstudiante,
                    onMover: (_, matriculaId, estudianteUid, cursoId) =>
                        _moverEstudiante(
                            context, matriculaId, estudianteUid, cursoId),
                    onEliminar: _eliminarDelCurso,
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SeccionAnioEstudiantes extends StatelessWidget {
  final String titulo;
  final Color color;
  final List<QueryDocumentSnapshot> cursos;
  final Future<void> Function(BuildContext, String, String) onAgregar;
  final Future<void> Function(BuildContext, String, String, String) onMover;
  final Future<void> Function(BuildContext, String, String) onEliminar;

  const _SeccionAnioEstudiantes({
    required this.titulo,
    required this.color,
    required this.cursos,
    required this.onAgregar,
    required this.onMover,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      title: Text(
        titulo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
                nombreCurso: (data['tipo'] ??
                        data['paralelo'] ??
                        data['nombre'] ??
                        'Curso')
                    .toString(),
                nivel: data['nivel'] ?? 'A1',
                color: color,
                onAgregar: onAgregar,
                onMover: onMover,
                onEliminar: onEliminar,
              );
            }).toList(),
    );
  }
}

class _CursoEstudiantesCard extends StatelessWidget {
  final String cursoId;
  final String nombreCurso;
  final String nivel;
  final Color color;
  final Future<void> Function(BuildContext, String, String) onAgregar;
  final Future<void> Function(BuildContext, String, String, String) onMover;
  final Future<void> Function(BuildContext, String, String) onEliminar;

  const _CursoEstudiantesCard({
    required this.cursoId,
    required this.nombreCurso,
    required this.nivel,
    required this.color,
    required this.onAgregar,
    required this.onMover,
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
        tilePadding: const EdgeInsets.only(left: 12, right: 4),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.people, color: color),
        ),
        title: Text(
          nombreCurso,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "Nivel: $nivel",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: IconButton(
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.person_add, color: Color(0xFFB71C1C)),
          onPressed: () => onAgregar(context, cursoId, nombreCurso),
        ),
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('matriculas')
                .where('curso_id', isEqualTo: cursoId)
                .where('activo', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
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
                  final data = matriculaDoc.data() as Map<String, dynamic>;
                  final estudianteUid = data['estudiante_uid'] ?? '';

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(estudianteUid)
                        .get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) return const SizedBox();

                      final user =
                          userSnap.data!.data() as Map<String, dynamic>?;

                      final nombre = user?['nombre'] ?? 'Estudiante';
                      final email = user?['email'] ?? '';

                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.only(left: 12, right: 4),
                        leading: CircleAvatar(
                          radius: 20,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: SizedBox(
                          width: 36,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.grey,
                            ),
                            onSelected: (value) {
                              if (value == 'mover') {
                                onMover(
                                  context,
                                  matriculaDoc.id,
                                  estudianteUid,
                                  cursoId,
                                );
                              }

                              if (value == 'eliminar') {
                                onEliminar(
                                  context,
                                  matriculaDoc.id,
                                  nombre,
                                );
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'mover',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.swap_horiz,
                                      color: Color(0xFF1A237E),
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text("Mover"),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'eliminar',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_remove,
                                      color: Color(0xFFB71C1C),
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Eliminar",
                                      style: TextStyle(
                                        color: Color(0xFFB71C1C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
