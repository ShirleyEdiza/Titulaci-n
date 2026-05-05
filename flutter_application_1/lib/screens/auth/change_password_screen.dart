import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _newVisible = false;
  bool _confirmVisible = false;
  bool loading = false;

  bool get tieneMayuscula =>
      newPasswordController.text.contains(RegExp(r'[A-Z]'));
  bool get tieneMinuscula =>
      newPasswordController.text.contains(RegExp(r'[a-z]'));
  bool get tieneNumero =>
      newPasswordController.text.contains(RegExp(r'[0-9]'));
  bool get tieneEspecial =>
      newPasswordController.text.contains(RegExp(r'[!@#\$&*~%^()_+]'));
  bool get tieneOchoCaracteres => newPasswordController.text.length >= 8;
  bool get passwordValida =>
      tieneMayuscula &&
      tieneMinuscula &&
      tieneNumero &&
      tieneEspecial &&
      tieneOchoCaracteres;

  Future<void> cambiarPassword() async {
    if (newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      CustomSnackbar.warning(context, "Completa todos los campos");
      return;
    }
    if (!passwordValida) {
      CustomSnackbar.error(
          context, "La contraseña no cumple los requisitos de seguridad");
      return;
    }
    if (newPasswordController.text != confirmPasswordController.text) {
      CustomSnackbar.error(context, "Las contraseñas no coinciden");
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.currentUser!
          .updatePassword(newPasswordController.text.trim());
      if (!mounted) return;
      CustomSnackbar.success(context, "Contraseña actualizada exitosamente");
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = "Error al cambiar contraseña";
      if (e.code == 'requires-recent-login') {
        message =
            "Por seguridad vuelve a iniciar sesión e intenta de nuevo";
      }
      CustomSnackbar.error(context, message);
    }

    setState(() => loading = false);
  }

  Widget _requisito(String texto, bool cumplido) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(
            cumplido ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: cumplido ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
                fontSize: 12,
                color: cumplido ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock_reset,
                            size: 50, color: Color(0xFFB71C1C)),
                        const SizedBox(height: 12),
                        const Text("Nueva Contraseña",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E))),
                        const Text(
                          "Tu nueva contraseña debe cumplir los requisitos de seguridad",
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: newPasswordController,
                          obscureText: !_newVisible,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: "Nueva contraseña",
                            prefixIcon: const Icon(Icons.lock,
                                color: Color(0xFFB71C1C)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFB71C1C), width: 2),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _newVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(0xFF1A237E),
                              ),
                              onPressed: () => setState(
                                  () => _newVisible = !_newVisible),
                            ),
                          ),
                        ),
                        if (newPasswordController.text.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Requisitos de seguridad:",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey)),
                                const SizedBox(height: 6),
                                _requisito("Mínimo 8 caracteres",
                                    tieneOchoCaracteres),
                                _requisito(
                                    "Una letra mayúscula", tieneMayuscula),
                                _requisito(
                                    "Una letra minúscula", tieneMinuscula),
                                _requisito("Un número", tieneNumero),
                                _requisito(
                                    "Un carácter especial (!@#\$&*)",
                                    tieneEspecial),
                              ],
                            ),
                          ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: !_confirmVisible,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: "Confirmar nueva contraseña",
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: Color(0xFFB71C1C)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFB71C1C), width: 2),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _confirmVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(0xFF1A237E),
                              ),
                              onPressed: () => setState(() =>
                                  _confirmVisible = !_confirmVisible),
                            ),
                          ),
                        ),
                        if (confirmPasswordController.text.isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 6, left: 4),
                            child: Row(
                              children: [
                                Icon(
                                  newPasswordController.text ==
                                          confirmPasswordController.text
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 14,
                                  color: newPasswordController.text ==
                                          confirmPasswordController.text
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  newPasswordController.text ==
                                          confirmPasswordController.text
                                      ? "Las contraseñas coinciden"
                                      : "Las contraseñas no coinciden",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: newPasswordController.text ==
                                            confirmPasswordController.text
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: loading ? null : cambiarPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB71C1C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("Actualizar contraseña",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancelar",
                                style:
                                    TextStyle(color: Color(0xFF1A237E))),
                          ),
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