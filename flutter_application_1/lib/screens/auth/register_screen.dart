import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nombreController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool loading = false;
  final String rol = "estudiante";

  // Validaciones de contraseña
  bool get tieneMayuscula => passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get tieneMinuscula => passwordController.text.contains(RegExp(r'[a-z]'));
  bool get tieneNumero => passwordController.text.contains(RegExp(r'[0-9]'));
  bool get tieneEspecial =>
      passwordController.text.contains(RegExp(r'[!@#\$&*~%^()_+]'));
  bool get tieneOchoCaracteres => passwordController.text.length >= 8;
  bool get passwordValida =>
      tieneMayuscula &&
      tieneMinuscula &&
      tieneNumero &&
      tieneEspecial &&
      tieneOchoCaracteres;

  Future<void> register() async {
    if (nombreController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _showSnack("Completa todos los campos");
      return;
    }

    if (!passwordValida) {
      _showSnack("La contraseña no cumple los requisitos de seguridad");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showSnack("Las contraseñas no coinciden");
      return;
    }

    setState(() => loading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(userCredential.user!.uid)
          .set({
        "email": emailController.text.trim(),
        "nombre": nombreController.text.trim(),
        "rol": rol,
        "activo": true,
        "fecha_registro": DateTime.now(),
      });

      if (!mounted) return;
      _showSnack("¡Cuenta creada exitosamente!");
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = "Error al registrar";
      if (e.code == 'email-already-in-use') {
        message = "Este correo ya está registrado";
      } else if (e.code == 'weak-password') {
        message = "La contraseña es muy débil";
      } else if (e.code == 'invalid-email') {
        message = "Correo inválido";
      }
      _showSnack(message);
    }

    setState(() => loading = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _requisito(String texto, bool cumplido) {
    return Row(
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
            color: cumplido ? Colors.green : Colors.red,
          ),
        ),
      ],
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
                  const Text(
                    "SURUPUCYU",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                  const Text(
                    "SpeakApp",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFF9A825),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                        const Text(
                          "Crear Cuenta",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const Text(
                          "Regístrate para comenzar a practicar",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),

                        // Nombre
                        _buildTextField(
                          controller: nombreController,
                          label: "Nombre completo",
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 14),

                        // Email
                        _buildTextField(
                          controller: emailController,
                          label: "Correo electrónico",
                          icon: Icons.email,
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),

                        // Password
                        _buildTextField(
                          controller: passwordController,
                          label: "Contraseña",
                          icon: Icons.lock,
                          isPassword: true,
                          visible: _passwordVisible,
                          onToggle: () => setState(
                              () => _passwordVisible = !_passwordVisible),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),

                        // Requisitos de contraseña
                        if (passwordController.text.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Requisitos de contraseña:",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _requisito(
                                    "Mínimo 8 caracteres", tieneOchoCaracteres),
                                _requisito(
                                    "Una letra mayúscula", tieneMayuscula),
                                _requisito(
                                    "Una letra minúscula", tieneMinuscula),
                                _requisito("Un número", tieneNumero),
                                _requisito("Un carácter especial (!@#\$&*)",
                                    tieneEspecial),
                              ],
                            ),
                          ),

                        const SizedBox(height: 14),

                        // Confirmar password
                        _buildTextField(
                          controller: confirmPasswordController,
                          label: "Confirmar contraseña",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          visible: _confirmPasswordVisible,
                          onToggle: () => setState(() =>
                              _confirmPasswordVisible =
                                  !_confirmPasswordVisible),
                        ),

                        // Indicador de coincidencia
                        if (confirmPasswordController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Icon(
                                  passwordController.text ==
                                          confirmPasswordController.text
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 16,
                                  color: passwordController.text ==
                                          confirmPasswordController.text
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  passwordController.text ==
                                          confirmPasswordController.text
                                      ? "Las contraseñas coinciden"
                                      : "Las contraseñas no coinciden",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: passwordController.text ==
                                            confirmPasswordController.text
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: loading ? null : register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB71C1C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    "Crear Cuenta",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("¿Ya tienes cuenta?",
                          style: TextStyle(color: Colors.white70)),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Inicia sesión",
                          style: TextStyle(
                            color: Color(0xFFF9A825),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool visible = false,
    VoidCallback? onToggle,
    TextInputType keyboard = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !visible : false,
      keyboardType: keyboard,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFB71C1C)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 2),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  visible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF1A237E),
                ),
                onPressed: onToggle,
              )
            : null,
      ),
    );
  }
}
