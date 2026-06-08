import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalisisService {
  Future<Map<String, dynamic>> analizarTexto(String texto) async {
    try {
      final response = await http
          .post(
            Uri.parse("https://titulaci-n.onrender.com/analizar"),
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "mensaje": texto,
              "historial_usuario": [],
              "historial_asistente": [],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final resultado = data["resultado"];

        if (resultado is String) {
          return jsonDecode(resultado);
        }

        if (resultado is Map<String, dynamic>) {
          return resultado;
        }
      }

      return _respuestaError(texto);
    } catch (e) {
      print("ERROR ANALISIS SERVICE: $e");
      return _respuestaError(texto);
    }
  }

  Map<String, dynamic> _respuestaError(String texto) {
    return {
      "texto_corregido": texto,
      "errores_detectados": [],
      "puntuacion_gramatica": 0,
      "nivel_detectado": "A1",
      "comentario": "No se pudo analizar el texto.",
      "sugerencias": [],
      "puntos_fuertes": [],
    };
  }
}
