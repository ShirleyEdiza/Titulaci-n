import 'dart:convert';
import 'package:http/http.dart' as http;

class PronunciacionService {
  final String baseUrl = "http://192.168.3.139:8000";

  Future<Map<String, dynamic>> analizarPronunciacion({
    required String textoReconocido,
    required String textoReferencia,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/pronunciacion"),
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "texto_reconocido": textoReconocido,
              "texto_referencia": textoReferencia,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["resultado"] is String) {
          return jsonDecode(data["resultado"]);
        }

        return Map<String, dynamic>.from(
          data["resultado"],
        );
      }

      return {};
    } catch (e) {
      print("ERROR PRONUNCIACION SERVICE: $e");
      return {};
    }
  }
}
