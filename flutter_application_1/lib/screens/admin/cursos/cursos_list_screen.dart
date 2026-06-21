import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../repositories/admin_repository.dart';
import 'curso_create_screen.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';

class CursosListScreen extends StatelessWidget {
  CursosListScreen({super.key});

  final repo = AdminRepository();

  final List<String> anios = const ['Primero', 'Segundo', 'Tercero'];

  Color _colorPorAnio(String anio) {
    if (anio == 'Primero') return const Color(0xFF1A237E);
    if (anio == 'Segundo') return const Color(0xFFB71C1C);
    return const Color(0xFF4A148C);
  }

  Future<void> _confirmarEliminar(
      BuildContext context, String id, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Eliminar curso',
          style: TextStyle(
            color: Color(0xFFB71C1C),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "¿Está seguro de eliminar el curso '$nombre'?\n\nEsta acción ocultará el curso y sus estudiantes ya no lo verán activo.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await repo.eliminarCurso(id);
      if (context.mounted) {
        CustomSnackbar.success(context, 'Curso eliminado correctamente');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFB71C1C),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo curso', style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CursoCreateScreen()),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: repo.obtenerCursos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error al cargar cursos',
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: anios.map((anio) {
              final cursosDelAnio = cursos.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['anio'] == anio;
              }).toList();

              return _SeccionCursos(
                titulo: anio == 'Primero'
                    ? '1ro Bachillerato'
                    : anio == 'Segundo'
                        ? '2do Bachillerato'
                        : '3ro Bachillerato',
                color: _colorPorAnio(anio),
                cursos: cursosDelAnio,
                onEditar: (id, data) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CursoCreateScreen(
                        cursoId: id,
                        cursoData: data,
                      ),
                    ),
                  );
                },
                onEliminar: (id, nombre) =>
                    _confirmarEliminar(context, id, nombre),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _SeccionCursos extends StatelessWidget {
  final String titulo;
  final Color color;
  final List<QueryDocumentSnapshot> cursos;
  final void Function(String, Map<String, dynamic>) onEditar;
  final void Function(String, String) onEliminar;

  const _SeccionCursos({
    required this.titulo,
    required this.color,
    required this.cursos,
    required this.onEditar,
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
                  'Aún no hay cursos en este año',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ]
          : cursos.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return _CursoAdminCard(
                id: doc.id,
                nombre: data['nombre'] ?? '',
                tipo: data['tipo'] ?? '',
                codigo: data['codigo_acceso'] ?? '',
                nivel: data['nivel'] ?? '',
                color: color,
                onEditar: () => onEditar(doc.id, data),
                onEliminar: () =>
                    onEliminar(doc.id, data['tipo'] ?? data['nombre'] ?? ''),
              );
            }).toList(),
    );
  }
}

class _CursoAdminCard extends StatelessWidget {
  final String id;
  final String nombre;
  final String tipo;
  final String codigo;
  final String nivel;
  final Color color;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _CursoAdminCard({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.codigo,
    required this.nivel,
    required this.color,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final titulo = tipo.isNotEmpty ? tipo : nombre;

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
          )
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
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.class_, color: color),
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
                      color: color,
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
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'editar') onEditar();
                if (value == 'eliminar') onEliminar();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Color(0xFF1A237E), size: 18),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Color(0xFFB71C1C), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Eliminar',
                        style: TextStyle(color: Color(0xFFB71C1C)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
