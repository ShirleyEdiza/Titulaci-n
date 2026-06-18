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

  // Error del nombre en tiempo real
  String? _errorNombre;
  String? _errorGeneral;

  // ─── Validaciones de nombre ───────────────────────────────
  String? _validarNombre(String nombre) {
    if (nombre.isEmpty) return null; // no mostrar error si está vacío aún

    if (nombre.trim().isEmpty) {
      return "El nombre no puede ser solo espacios";
    }
    if (nombre.trim().length < 3) {
      return "El nombre debe tener al menos 3 caracteres";
    }
    if (nombre.trim().length > 50) {
      return "El nombre no puede tener más de 50 caracteres";
    }
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$").hasMatch(nombre.trim())) {
      return "El nombre solo puede contener letras";
    }
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.length < 2 || partes.any((p) => p.isEmpty)) {
      return "Ingresa tu nombre y apellido";
    }
    return null;
  }

  // ─── Validaciones de contraseña ───────────────────────────
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

  // ─── Registro ─────────────────────────────────────────────
  Future<void> register() async {
    // Validar nombre
    final errorNombre = _validarNombre(nombreController.text);
    if (nombreController.text.isEmpty || errorNombre != null) {
      setState(
          () => _errorNombre = errorNombre ?? "Ingresa tu nombre completo");
      _mostrarError(_errorNombre!);
      return;
    }

    // Validar email
    if (emailController.text.isEmpty) {
      _mostrarError("Ingresa tu correo electrónico");
      return;
    }

    final existeCorreo = await FirebaseFirestore.instance
        .collection("usuarios")
        .where("email", isEqualTo: emailController.text.trim().toLowerCase())
        .limit(1)
        .get();

    if (existeCorreo.docs.isNotEmpty) {
      _mostrarError("El correo electrónico ingresado ya está registrado.");
      return;
    }

    // Validar contraseña
    if (passwordController.text.isEmpty) {
      _mostrarError("Ingresa una contraseña");
      return;
    }

    if (!passwordValida) {
      _mostrarError("La contraseña no cumple los requisitos de seguridad");
      return;
    }

    // Validar confirmación
    if (confirmPasswordController.text.isEmpty) {
      _mostrarError("Confirma tu contraseña");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _mostrarError("Las contraseñas no coinciden");
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
      _mostrarExito(
          "Cuenta creada correctamente. Ahora puedes iniciar sesión.");

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
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
      _mostrarError(message);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  bool _esError = true;

  void _mostrarExito(String msg) {
    setState(() {
      _errorGeneral = msg;
      _esError = false;
    });
  }

  void _mostrarError(String msg) {
    setState(() {
      _errorGeneral = msg;
      _esError = true;
    });
  }

  // ─── Widget requisito contraseña ──────────────────────────
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
              color: cumplido ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────
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
                  // Header
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

                  // Card
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

                        // ── Campo Nombre ──────────────────
                        TextField(
                          controller: nombreController,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (value) {
                            setState(() {
                              _errorNombre = _validarNombre(value);
                              _errorGeneral = null;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: "Nombre completo",
                            hintText: "Ej: Ana López",
                            prefixIcon: const Icon(Icons.person,
                                color: Color(0xFFB71C1C)),
                            errorText: _errorNombre,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFB71C1C), width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 1),
                            ),
                          ),
                        ),

                        // Indicador nombre válido
                        if (nombreController.text.isNotEmpty &&
                            _errorNombre == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 6, left: 4),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    size: 14, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  "Nombre válido",
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.green),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 14),

                        // ── Campo Email ───────────────────
                        _buildTextField(
                          controller: emailController,
                          label: "Correo electrónico",
                          hint: "Ej: ana@gmail.com",
                          icon: Icons.email,
                          keyboard: TextInputType.emailAddress,
                          onChanged: (_) => setState(() {
                            _errorGeneral = null;
                          }),
                        ),
                        const SizedBox(height: 14),

                        // ── Campo Contraseña ──────────────
                        _buildTextField(
                          controller: passwordController,
                          label: "Contraseña",
                          icon: Icons.lock,
                          isPassword: true,
                          visible: _passwordVisible,
                          onToggle: () => setState(
                              () => _passwordVisible = !_passwordVisible),
                          onChanged: (_) => setState(() {
                            _errorGeneral = null;
                          }),
                        ),

                        // Requisitos contraseña
                        if (passwordController.text.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 10),
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

                        // ── Confirmar Contraseña ──────────
                        _buildTextField(
                          controller: confirmPasswordController,
                          label: "Confirmar contraseña",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          visible: _confirmPasswordVisible,
                          onToggle: () => setState(() =>
                              _confirmPasswordVisible =
                                  !_confirmPasswordVisible),
                          onChanged: (_) => setState(() {
                            _errorGeneral = null;
                          }),
                        ),

                        // Indicador coincidencia
                        if (confirmPasswordController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 4),
                            child: Row(
                              children: [
                                Icon(
                                  passwordController.text ==
                                          confirmPasswordController.text
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 14,
                                  color: passwordController.text ==
                                          confirmPasswordController.text
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  passwordController.text ==
                                          confirmPasswordController.text
                                      ? "Las contraseñas coinciden"
                                      : "Las contraseñas no coinciden",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: passwordController.text ==
                                            confirmPasswordController.text
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),
                        // ── Mensaje de error bonito ───────
                        if (_errorGeneral != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _esError
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _esError
                                    ? Colors.red.shade200
                                    : Colors.green.shade200,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _esError
                                      ? Icons.error_outline
                                      : Icons.check_circle_outline,
                                  color: _esError ? Colors.red : Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorGeneral!,
                                    style: TextStyle(
                                      color:
                                          _esError ? Colors.red : Colors.green,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // ── Botón Registrar ───────────────
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

                  // Link a login
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

  // ─── TextField reutilizable ───────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String hint = "",
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
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
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
