import 'dart:convert';
import 'package:http/http.dart' as http;

class IAService {
  Future<String> enviarMensaje(String mensaje) async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.3.139:8000/chat"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "mensaje": mensaje,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data["respuesta"];
      }

      return "Error communicating with assistant.";
    } catch (e) {
      return "Connection error with IA server.";
    }
  }
}
