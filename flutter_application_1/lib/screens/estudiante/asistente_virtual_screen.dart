import 'package:flutter/material.dart';
import '../../widgets/virtual_assistant_avatar.dart';

class AsistenteVirtualScreen extends StatefulWidget {
  final String cursoId;
  final String nombreCurso;

  const AsistenteVirtualScreen({
    super.key,
    required this.cursoId,
    required this.nombreCurso,
  });

  @override
  State<AsistenteVirtualScreen> createState() => _AsistenteVirtualScreenState();
}

class _AsistenteVirtualScreenState extends State<AsistenteVirtualScreen> {
  bool iniciado = false;
  bool pausado = false;

  final List<String> preguntas = const [
    "How are you?",
    "What is your name?",
    "Where are you from?",
    "What do you like to do?",
    "Can you describe your family?",
  ];

  int preguntaActual = 0;

  void iniciar() {
    setState(() {
      iniciado = true;
      pausado = false;
      preguntaActual = 0;
    });
  }

  void pausar() {
    setState(() {
      pausado = !pausado;
    });
  }

  void terminar() {
    setState(() {
      iniciado = false;
      pausado = false;
      preguntaActual = 0;
    });
  }

  void siguientePregunta() {
    if (!iniciado || pausado) return;

    setState(() {
      preguntaActual = (preguntaActual + 1) % preguntas.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final estado = !iniciado
        ? "Presiona iniciar para comenzar"
        : pausado
            ? "Interacción pausada"
            : "Escucha y responde en inglés";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Asistente virtual",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.nombreCurso,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const VirtualAssistantAvatar(),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
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
              child: Column(
                children: [
                  const Text(
                    "Practice your speaking",
                    style: TextStyle(
                      color: Color(0xFF1A237E),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    estado,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: iniciado && !pausado
                          ? const Color(0xFF1A237E).withOpacity(0.08)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: iniciado && !pausado
                            ? const Color(0xFF1A237E)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      iniciado
                          ? preguntas[preguntaActual]
                          : "Example: How are you?",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (iniciado && !pausado)
                    TextButton.icon(
                      onPressed: siguientePregunta,
                      icon: const Icon(Icons.navigate_next),
                      label: const Text("Siguiente pregunta"),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: iniciar,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Iniciar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: iniciado ? pausar : null,
                    icon: Icon(pausado ? Icons.play_circle : Icons.pause),
                    label: Text(pausado ? "Continuar" : "Pausar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9A825),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: iniciado ? terminar : null,
              icon: const Icon(Icons.stop),
              label: const Text("Terminar interacción"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
