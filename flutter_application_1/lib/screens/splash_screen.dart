import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E), // azul marino
              Color(0xFFB71C1C), // rojo
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo dibujado
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Montaña
                      Positioned(
                        bottom: 30,
                        child: CustomPaint(
                          size: const Size(90, 50),
                          painter: _MontanhaPainter(),
                        ),
                      ),
                      // Sol
                      Positioned(
                        top: 22,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9A825),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Libro
                      Positioned(
                        bottom: 18,
                        left: 22,
                        child: Icon(
                          Icons.menu_book,
                          color: const Color(0xFF1A237E),
                          size: 22,
                        ),
                      ),
                      // Carro antiguo
                      Positioned(
                        bottom: 18,
                        right: 22,
                        child: Icon(
                          Icons.directions_car,
                          color: const Color(0xFFB71C1C),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "SURUPUCYU",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Unidad Educativa Intercultural Bilingüe",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 40),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Text(
                    "SpeakApp",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFFF9A825),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                const CircularProgressIndicator(
                  color: Colors.white54,
                  strokeWidth: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Pintor de montaña
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

    // Nieve en la punta
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
