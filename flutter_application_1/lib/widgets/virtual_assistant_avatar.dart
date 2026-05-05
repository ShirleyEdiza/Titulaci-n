import 'package:flutter/material.dart';

class VirtualAssistantAvatar extends StatefulWidget {
  const VirtualAssistantAvatar({super.key});

  @override
  State<VirtualAssistantAvatar> createState() => _VirtualAssistantAvatarState();
}

class _VirtualAssistantAvatarState extends State<VirtualAssistantAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _move;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _move = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _move,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _move.value),
          child: child,
        );
      },
      child: Container(
        width: 170,
        height: 170,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1A237E),
              Color(0xFFB71C1C),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // rostro
            Positioned(
              top: 38,
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFFD18A5B),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // cabello
            Positioned(
              top: 28,
              child: Container(
                width: 95,
                height: 55,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(60),
                    bottom: Radius.circular(20),
                  ),
                ),
              ),
            ),

            // sombrero
            Positioned(
              top: 18,
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  Container(
                    width: 115,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ],
              ),
            ),

            // ojos
            Positioned(
              top: 72,
              left: 58,
              child: _eye(),
            ),
            Positioned(
              top: 72,
              right: 58,
              child: _eye(),
            ),

            // boca
            Positioned(
              top: 105,
              child: Container(
                width: 28,
                height: 9,
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            // trenzas
            Positioned(
              top: 75,
              left: 31,
              child: _braid(),
            ),
            Positioned(
              top: 75,
              right: 31,
              child: _braid(),
            ),

            // ropa
            Positioned(
              bottom: 0,
              child: Container(
                width: 110,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFFB71C1C),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(45),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFF9A825),
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eye() {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: Colors.green.shade300,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
    );
  }

  Widget _braid() {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 2),
          width: 17,
          height: 17,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
