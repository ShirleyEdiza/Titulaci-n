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

  Future<String> crearInteraccion({
    required String estudianteUid,
    required String cursoId,
    String modoIa = "gemini",
  }) async {
    final doc = await _firestore.collection('interacciones').add({
      'estudiante_uid': estudianteUid,
      'curso_id': cursoId,
      'fecha_inicio': FieldValue.serverTimestamp(),
      'fecha_fin': null,
      'estado': 'en_proceso',
      'modo_ia': modoIa,
      'total_respuestas': 0,
    });

    return doc.id;
  }

  Future<String> guardarRespuesta({
    required String interaccionId,
    required String estudianteUid,
    required String cursoId,
    required String textoUsuario,
    required String respuestaAsistente,
    required String audioUrl,
    String idiomaDetectado = "auto",
    int duracionAudio = 0,
  }) async {
    final doc = await _firestore.collection('respuestas').add({
      'interaccion_id': interaccionId,
      'estudiante_uid': estudianteUid,
      'curso_id': cursoId,
      'texto_generado': textoUsuario,
      'respuesta_ia': respuestaAsistente,
      'idioma_detectado': idiomaDetectado,
      'audio_url': audioUrl,
      'fecha_respuesta': FieldValue.serverTimestamp(),
      'duracion_audio': duracionAudio,
      'estado': 'registrado',
    });

    await _firestore.collection('interacciones').doc(interaccionId).update({
      'total_respuestas': FieldValue.increment(1),
    });

    return doc.id;
  }

  Future<void> finalizarInteraccion({
    required String interaccionId,
  }) async {
    await _firestore.collection('interacciones').doc(interaccionId).update({
      'fecha_fin': FieldValue.serverTimestamp(),
      'estado': 'finalizada',
    });
  }
}
