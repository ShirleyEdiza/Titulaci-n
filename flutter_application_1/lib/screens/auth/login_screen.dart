import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../estudiante/home_estudiante.dart';
import '../docente/home_docente.dart';
import '../admin/home_admin.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool loading = false;
  bool obscurePassword = true;
  String? _errorGeneral;

  void _mostrarError(String mensaje) {
    setState(() {
      _errorGeneral = mensaje;
    });
  }

  Future<void> login() async {
    if (emailController.text.trim().isEmpty) {
      _mostrarError("El campo correo electrónico está vacío.");
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      _mostrarError("El campo contraseña está vacío.");
      return;
    }

    setState(() => loading = true);

    final result = await _authService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() => loading = false);
    if (!mounted) return;

    if (result['success']) {
      String rol = result['rol'];
      if (rol == 'admin') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeAdmin()));
      } else if (rol == 'docente') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeDocente()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeEstudiante()));
      }
    } else {
      _mostrarError(result['message']);
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
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          bottom: 15,
                          child: CustomPaint(
                            size: const Size(55, 30),
                            painter: _MontanhaPainter(),
                          ),
                        ),
                        const Positioned(
                          top: 12,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: Color(0xFFF9A825),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      letterSpacing: 2,
                    ),
                  ),
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
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Iniciar Sesión",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const Text(
                          "Ingresa tus credenciales para continuar",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setState(() {
                            _errorGeneral = null;
                          }),
                          decoration: InputDecoration(
                            labelText: "Correo electrónico",
                            prefixIcon: const Icon(Icons.email,
                                color: Color(0xFFB71C1C)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFB71C1C), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          onChanged: (_) => setState(() {
                            _errorGeneral = null;
                          }),
                          decoration: InputDecoration(
                            labelText: "Contraseña",
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
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(0xFF1A237E),
                              ),
                              onPressed: () => setState(
                                  () => obscurePassword = !obscurePassword),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen()),
                            ),
                            child: const Text(
                              "¿Olvidaste tu contraseña?",
                              style: TextStyle(color: Color(0xFFB71C1C)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_errorGeneral != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorGeneral!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: loading ? null : login,
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
                                    "Iniciar Sesión",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("¿No tienes cuenta?",
                          style: TextStyle(color: Colors.white70)),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: const Text(
                          "Regístrate",
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
}

class _MontanhaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A237E)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.35, 0);
    path.lineTo(size.width * 0.65, size.height * 0.3);
    path.lineTo(size.width * 0.8, size.height * 0.1);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
    final snowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final snowPath = Path();
    snowPath.moveTo(size.width * 0.28, size.height * 0.15);
    snowPath.lineTo(size.width * 0.35, 0);
    snowPath.lineTo(size.width * 0.42, size.height * 0.15);
    snowPath.close();
    canvas.drawPath(snowPath, snowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
