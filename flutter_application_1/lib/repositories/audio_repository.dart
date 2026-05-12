import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AudioRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> subirAudio({
    required String pathAudio,
    required String estudianteUid,
  }) async {
    final file = File(pathAudio);

    if (!await file.exists()) {
      return "";
    }

    final nombreArchivo = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    final ref = _storage.ref().child(
          'audios/$estudianteUid/$nombreArchivo',
        );

    final uploadTask = await ref.putFile(file);

    if (uploadTask.state == TaskState.success) {
      return await ref.getDownloadURL();
    }

    return "";
  }

  Future<void> guardarRespuesta({
    required String estudianteUid,
    required String textoUsuario,
    required String respuestaAsistente,
    required String audioUrl,
  }) async {
    await _firestore.collection('respuestas').add({
      'estudianteUid': estudianteUid,
      'texto_generado': textoUsuario,
      'respuesta_ia': respuestaAsistente,
      'audio_url': audioUrl,
      'fecha_respuesta': FieldValue.serverTimestamp(),
      'estado': 'registrado',
    });
  }
}
