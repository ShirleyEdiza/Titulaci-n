import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool loading = false;
  bool enviado = false;

  Future<void> recuperar() async {
    if (emailController.text.isEmpty) {
      CustomSnackbar.warning(context, "Ingresa tu correo electrónico");
      return;
    }

    setState(() => loading = true);
    final result =
        await _authService.recuperarContrasena(emailController.text.trim());
    setState(() {
      loading = false;
      if (result['success']) enviado = true;
    });

    if (!mounted) return;
    if (result['success']) {
      CustomSnackbar.success(context, result['message']);
    } else {
      CustomSnackbar.error(context, result['message']);
    }
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
                    child: enviado
                        ? _PantallaEnviado(email: emailController.text.trim())
                        : _FormularioRecuperar(
                            emailController: emailController,
                            loading: loading,
                            onRecuperar: recuperar,
                          ),
                  ),
                  if (!enviado) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Volver al inicio de sesión",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormularioRecuperar extends StatelessWidget {
  final TextEditingController emailController;
  final bool loading;
  final VoidCallback onRecuperar;

  const _FormularioRecuperar({
    required this.emailController,
    required this.loading,
    required this.onRecuperar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_reset, size: 50, color: Color(0xFFB71C1C)),
        const SizedBox(height: 12),
        const Text("Recuperar Contraseña",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E))),
        const SizedBox(height: 6),
        const Text(
          "Te enviaremos un enlace a tu correo para restablecer tu contraseña.",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Requisitos de la nueva contraseña
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Color(0xFF1A237E)),
                  SizedBox(width: 6),
                  Text("Tu nueva contraseña debe tener:",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E))),
                ],
              ),
              const SizedBox(height: 6),
              ...[
                "Mínimo 8 caracteres",
                "Una letra mayúscula (A-Z)",
                "Una letra minúscula (a-z)",
                "Un número (0-9)",
                "Un carácter especial (!@#\$&*)",
              ].map(
                (req) => Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 13, color: Color(0xFF1A237E)),
                      const SizedBox(width: 6),
                      Text(req,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF1A237E))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "Correo electrónico",
            prefixIcon: const Icon(Icons.email, color: Color(0xFFB71C1C)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: loading ? null : onRecuperar,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Enviar correo de recuperación",
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _PantallaEnviado extends StatelessWidget {
  final String email;

  const _PantallaEnviado({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.mark_email_read, size: 60, color: Color(0xFF1B5E20)),
        const SizedBox(height: 16),
        const Text("¡Correo enviado correctamente!",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E))),
        const SizedBox(height: 8),
        const SizedBox(height: 8),
        const Text(
          "Por seguridad, después de actualizar tu contraseña deberás volver a iniciar sesión.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          "Enviamos el enlace de recuperación a:\n$email",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1B5E20).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Color(0xFF1B5E20)),
                  SizedBox(width: 6),
                  Text("Recuerda que tu contraseña debe tener:",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20))),
                ],
              ),
              const SizedBox(height: 6),
              ...[
                "Mínimo 8 caracteres",
                "Una letra mayúscula (A-Z)",
                "Una letra minúscula (a-z)",
                "Un número (0-9)",
                "Un carácter especial (!@#\$&*)",
              ].map(
                (req) => Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 13, color: Color(0xFF1B5E20)),
                      const SizedBox(width: 6),
                      Text(req,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF1B5E20))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text("Revisa también tu carpeta de spam",
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Volver al inicio de sesión",
              style: TextStyle(color: Color(0xFF1A237E))),
        ),
      ],
    );
  }
}
