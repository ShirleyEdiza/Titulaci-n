import 'dart:convert';
import 'package:http/http.dart' as http;

class IAService {
  Future<String> enviarMensaje(
    String mensaje, {
    List<String> historialUsuario = const [],
    List<String> historialAsistente = const [],
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("http://192.168.3.139:8000/chat"),
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "mensaje": mensaje,
              "historial_usuario": historialUsuario,
              "historial_asistente": historialAsistente,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print("RESPUESTA BACKEND: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final respuesta = data["respuesta"] ?? "No response.";

        return respuesta;
      }

      return "Error communicating with assistant.";
    } catch (e) {
      print("ERROR IA SERVICE: $e");
      return "Connection error with IA server.";
    }
  }
}
