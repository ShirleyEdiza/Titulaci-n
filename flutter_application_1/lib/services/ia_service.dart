import 'dart:convert';
import 'package:http/http.dart' as http;

class IAService {
  String? _respuestaRapidaLocal(String mensaje) {
    final m = mensaje.toLowerCase().trim();

    if (m == "hello" || m == "hi" || m.contains("hello")) {
      return "Hello! How are you today?";
    }

    if (m.contains("my name is")) {
      return "Nice to meet you! Where are you from?";
    }

    if (m == "hola" || m.contains("hola")) {
      return "¡Hola! ¿Cómo estás hoy?";
    }

    return null;
  }

  Future<String> enviarMensaje(
    String mensaje, {
    List<String> historialUsuario = const [],
    List<String> historialAsistente = const [],
  }) async {
    final rapida = _respuestaRapidaLocal(mensaje);
    if (rapida != null) return rapida;

    try {
      final response = await http
          .post(
            Uri.parse("https://titulaci-n.onrender.com/chat"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "mensaje": mensaje,
              "historial_usuario": historialUsuario.take(4).toList(),
              "historial_asistente": historialAsistente.take(4).toList(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["respuesta"] ?? "Can you repeat, please?";
      }

      return "Can you repeat, please?";
    } catch (e) {
      return "Can you repeat, please?";
    }
  }
}