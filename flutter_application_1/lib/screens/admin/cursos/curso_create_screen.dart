import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../repositories/admin_repository.dart';
import '../../../services/admin_service.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';

class CursoCreateScreen extends StatefulWidget {
  final String? cursoId;
  final Map<String, dynamic>? cursoData;

  const CursoCreateScreen({
    super.key,
    this.cursoId,
    this.cursoData,
  });

  @override
  State<CursoCreateScreen> createState() => _CursoCreateScreenState();
}

class _CursoCreateScreenState extends State<CursoCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();

  String anio = 'Primero';
  String tipo = 'Ciencias';
  String nivelIngles = 'A1';

  final repo = AdminRepository();
  final service = AdminService();

  bool get editando => widget.cursoId != null;

  @override
  void initState() {
    super.initState();

    if (widget.cursoData != null) {
      _nombreCtrl.text = widget.cursoData!['nombre'] ?? '';
      anio = widget.cursoData!['anio'] ?? 'Primero';
      tipo = widget.cursoData!['tipo'] ?? 'Ciencias';
      nivelIngles = widget.cursoData!['nivel'] ?? 'A1';
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final data = {
        'nombre': _nombreCtrl.text.trim(),
        'anio': anio,
        'tipo': tipo,
        'nivel': nivelIngles,
        'activo': true,
      };

      if (editando) {
        await repo.actualizarCurso(widget.cursoId!, data);
        if (mounted) {
          CustomSnackbar.success(context, 'Curso actualizado correctamente');
          Navigator.pop(context);
        }
      } else {
        await repo.crearCurso({
          ...data,
          'codigo_acceso': service.generarCodigo(),
          'docente_uid': '',
          'creado_en': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          CustomSnackbar.success(context, 'Curso creado correctamente');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.error(context, 'Error al guardar curso');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Text(editando ? 'Editar curso' : 'Crear curso'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nombre del curso',
                    hintText: 'Ej: Inglés',
                    prefixIcon:
                        const Icon(Icons.class_, color: Color(0xFFB71C1C)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: anio,
                  decoration: InputDecoration(
                    labelText: 'Año',
                    prefixIcon:
                        const Icon(Icons.school, color: Color(0xFFB71C1C)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Primero', child: Text('Primero')),
                    DropdownMenuItem(value: 'Segundo', child: Text('Segundo')),
                    DropdownMenuItem(value: 'Tercero', child: Text('Tercero')),
                  ],
                  onChanged: (v) => setState(() => anio = v!),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: tipo,
                  decoration: InputDecoration(
                    labelText: 'Curso',
                    prefixIcon:
                        const Icon(Icons.category, color: Color(0xFFB71C1C)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Ciencias', child: Text('Ciencias')),
                    DropdownMenuItem(
                        value: 'Técnico - Producción agropecuaria',
                        child: Text('Técnico - Producción agropecuaria')),
                  ],
                  onChanged: (v) => setState(() => tipo = v!),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: nivelIngles,
                  decoration: InputDecoration(
                    labelText: 'Nivel de inglés',
                    prefixIcon:
                        const Icon(Icons.bar_chart, color: Color(0xFFB71C1C)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'A1', child: Text('A1')),
                    DropdownMenuItem(value: 'A2', child: Text('A2')),
                    DropdownMenuItem(value: 'B1', child: Text('B1')),
                  ],
                  onChanged: (v) => setState(() => nivelIngles = v!),
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _guardar,
                  icon: Icon(editando ? Icons.save : Icons.add),
                  label: Text(editando ? 'Guardar cambios' : 'Crear curso'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
