import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';

class IngresoCodigoScreen extends StatefulWidget {
  final String? codigoInicial;

  const IngresoCodigoScreen({super.key, this.codigoInicial});

  @override
  State<IngresoCodigoScreen> createState() => _IngresoCodigoScreenState();
}

class _IngresoCodigoScreenState extends State<IngresoCodigoScreen> {
  late TextEditingController codigoController;
  bool loading = false;
  int intentosFallidos = 0;
  static const int maxIntentos = 3;

  @override
  void initState() {
    super.initState();
    codigoController = TextEditingController(text: widget.codigoInicial ?? '');
  }

  @override
  void dispose() {
    codigoController.dispose();
    super.dispose();
  }

  String _formatearCodigo(String texto) {
    texto = texto.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (texto.length > 3) {
      return '${texto.substring(0, 3)}-${texto.substring(3, texto.length.clamp(3, 6))}';
    }
    return texto;
  }

  Future<void> ingresarCurso() async {
    if (intentosFallidos >= maxIntentos) {
      CustomSnackbar.error(
          context, "Demasiados intentos fallidos. Contacta a tu docente.");
      return;
    }

    String codigoLimpio =
        codigoController.text.trim().toUpperCase().replaceAll('-', '');

    if (codigoLimpio.isEmpty) {
      CustomSnackbar.warning(context, "Ingresa el código del curso");
      return;
    }

    if (codigoLimpio.length < 6) {
      CustomSnackbar.error(context, "El código debe tener el formato XXX-XXX");
      return;
    }

    setState(() => loading = true);

    try {
      String estudianteUid = FirebaseAuth.instance.currentUser!.uid;

      // Buscar curso por código
      QuerySnapshot cursoSnap = await FirebaseFirestore.instance
          .collection('cursos')
          .where('codigo_acceso', isEqualTo: codigoController.text.trim())
          .where('activo', isEqualTo: true)
          .get();

      // Si no encuentra con guión, busca sin guión
      if (cursoSnap.docs.isEmpty) {
        String codigoFormateado =
            '${codigoLimpio.substring(0, 3)}-${codigoLimpio.substring(3)}';
        cursoSnap = await FirebaseFirestore.instance
            .collection('cursos')
            .where('codigo_acceso', isEqualTo: codigoFormateado)
            .where('activo', isEqualTo: true)
            .get();
      }

      if (cursoSnap.docs.isEmpty) {
        setState(() {
          intentosFallidos++;
          loading = false;
        });
        int restantes = maxIntentos - intentosFallidos;
        if (restantes <= 0) {
          CustomSnackbar.error(
              context, "Código incorrecto. No tienes más intentos.");
        } else {
          CustomSnackbar.error(
              context, "Código incorrecto. Te quedan $restantes intentos.");
        }
        return;
      }

      String cursoId = cursoSnap.docs.first.id;
      String nombreCurso =
          (cursoSnap.docs.first.data() as Map<String, dynamic>)['nombre'] ?? '';

      // Verificar si ya está matriculado
      QuerySnapshot matriculaExiste = await FirebaseFirestore.instance
          .collection('matriculas')
          .where('estudiante_uid', isEqualTo: estudianteUid)
          .where('curso_id', isEqualTo: cursoId)
          .where('activo', isEqualTo: true)
          .get();

      if (matriculaExiste.docs.isNotEmpty) {
        if (!mounted) return;
        CustomSnackbar.warning(context, "Ya estás inscrito en este curso");
        setState(() => loading = false);
        return;
      }

      // Matricular estudiante
      await FirebaseFirestore.instance.collection('matriculas').add({
        'estudiante_uid': estudianteUid,
        'curso_id': cursoId,
        'fecha_ingreso': DateTime.now(),
        'activo': true,
      });

      if (!mounted) return;
      CustomSnackbar.success(
          context, "¡Te uniste a $nombreCurso exitosamente!");
      Navigator.pop(context, true);
    } catch (e) {
      CustomSnackbar.error(
          context, "Error al ingresar al curso. Intenta de nuevo.");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    bool bloqueado = intentosFallidos >= maxIntentos;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text("Incorporarse a la clase",
            style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.vpn_key,
                      color: Color(0xFF1A237E), size: 40),
                ),
                const SizedBox(height: 20),
                const Text("Ingresa el código de la clase",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E))),
                const SizedBox(height: 8),
                const Text(
                  "Tu docente te proporcionará el código para unirte",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),

                const SizedBox(height: 24),

                // Indicador de intentos
                if (intentosFallidos > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: bloqueado
                          ? Colors.red.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: bloqueado
                            ? Colors.red.shade300
                            : Colors.orange.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          bloqueado ? Icons.lock : Icons.warning_amber,
                          color: bloqueado ? Colors.red : Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bloqueado
                                ? "Acceso bloqueado. Contacta a tu docente."
                                : "Código incorrecto: $intentosFallidos/$maxIntentos intentos",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: bloqueado
                                  ? Colors.red
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Campo código
                TextField(
                  controller: codigoController,
                  enabled: !bloqueado,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  maxLength: 7,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      color: Color(0xFF1A237E)),
                  onChanged: (value) {
                    String formateado = _formatearCodigo(value);
                    if (formateado != value) {
                      codigoController.value = TextEditingValue(
                        text: formateado,
                        selection:
                            TextSelection.collapsed(offset: formateado.length),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "Ej: MSY-6RU",
                    hintStyle: const TextStyle(
                        color: Colors.grey, fontSize: 24, letterSpacing: 4),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFB71C1C), width: 2),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (loading || bloqueado) ? null : ingresarCurso,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          bloqueado ? Colors.grey : const Color(0xFFB71C1C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Unirse a la clase",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar",
                      style: TextStyle(color: Color(0xFF1A237E))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
