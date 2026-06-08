import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class TranscripcionService {
  final String baseUrl =
      "https://bouquet-replica-insulin-economic.trycloudflare.com";

  Future<String> transcribirAudio(String audioPath) async {
    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/transcribir"),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          "audio",
          audioPath,
        ),
      );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 40));

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["texto"] ?? "";
      }

      return "";
    } catch (e) {
      print("ERROR TRANSCRIPCION SERVICE: $e");
      return "";
    }
  }
}
