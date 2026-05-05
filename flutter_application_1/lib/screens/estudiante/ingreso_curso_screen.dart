import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';

class IngresoCodigoScreen extends StatefulWidget {
  final String cursoId;
  final String nombreCurso;

  const IngresoCodigoScreen({
    super.key,
    required this.cursoId,
    required this.nombreCurso,
  });

  @override
  State<IngresoCodigoScreen> createState() => _IngresoCodigoScreenState();
}

class _IngresoCodigoScreenState extends State<IngresoCodigoScreen> {
  final codigoController = TextEditingController();
  bool loading = false;
  int intentosFallidos = 0;
  static const int maxIntentos = 3;

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

    if (codigoLimpio.length != 6) {
      CustomSnackbar.error(context, "El código debe tener el formato XXX-XXX");
      return;
    }

    setState(() => loading = true);

    try {
      // Verificar el código contra el curso específico
      DocumentSnapshot cursoDoc = await FirebaseFirestore.instance
          .collection('cursos')
          .doc(widget.cursoId)
          .get();

      if (!cursoDoc.exists) {
        CustomSnackbar.error(context, "Curso no encontrado");
        setState(() => loading = false);
        return;
      }

      var cursoData = cursoDoc.data() as Map<String, dynamic>;
      String codigoCorrecto =
          (cursoData['codigo_acceso'] ?? '').replaceAll('-', '');

      if (codigoLimpio != codigoCorrecto) {
        setState(() {
          intentosFallidos++;
          loading = false;
        });
        int restantes = maxIntentos - intentosFallidos;
        if (restantes <= 0) {
          CustomSnackbar.error(context,
              "Código incorrecto. No tienes más intentos. Contacta a tu docente.");
        } else {
          CustomSnackbar.error(
              context, "Código incorrecto. Te quedan $restantes intentos.");
        }
        return;
      }

      String estudianteUid = FirebaseAuth.instance.currentUser!.uid;

      // Verificar si ya está matriculado
      QuerySnapshot matriculaExiste = await FirebaseFirestore.instance
          .collection('matriculas')
          .where('estudiante_uid', isEqualTo: estudianteUid)
          .where('curso_id', isEqualTo: widget.cursoId)
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
        'curso_id': widget.cursoId,
        'fecha_ingreso': DateTime.now(),
        'activo': true,
      });

      if (!mounted) return;
      CustomSnackbar.success(
          context, "¡Te uniste a ${widget.nombreCurso} exitosamente!");
      Navigator.pop(context, true);
    } catch (e) {
      CustomSnackbar.error(context, "Error al ingresar. Intenta de nuevo.");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    bool bloqueado = intentosFallidos >= maxIntentos;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF283593)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text("SURUPUCYU",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3)),
                  const Text("SpeakApp",
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFF9A825),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.vpn_key,
                            size: 60,
                            color: bloqueado
                                ? Colors.grey
                                : const Color(0xFFB71C1C)),
                        const SizedBox(height: 16),
                        const Text("Incorporación a la clase",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E))),
                        const SizedBox(height: 4),
                        Text(
                          widget.nombreCurso,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFB71C1C),
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Digite el código proporcionado por su docente",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
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
                                    ? Colors.red.shade200
                                    : Colors.orange.shade200,
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
                                        : "Intentos fallidos: $intentosFallidos/$maxIntentos",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: bloqueado
                                          ? Colors.red
                                          : Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

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
                            color: Color(0xFF1A237E),
                          ),
                          onChanged: (value) {
                            String formateado = _formatearCodigo(value);
                            if (formateado != value) {
                              codigoController.value = TextEditingValue(
                                text: formateado,
                                selection: TextSelection.collapsed(
                                    offset: formateado.length),
                              );
                            }
                          },
                          decoration: InputDecoration(
                            counterText: "",
                            hintText: "XXX-XXX",
                            hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 28,
                                letterSpacing: 6),
                            prefixIcon: const Icon(Icons.class_,
                                color: Color(0xFFB71C1C)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFB71C1C), width: 2),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                (loading || bloqueado) ? null : ingresarCurso,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bloqueado
                                  ? Colors.grey
                                  : const Color(0xFFB71C1C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("Ingresar a la clase",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancelar",
                              style: TextStyle(color: Color(0xFF1A237E))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
