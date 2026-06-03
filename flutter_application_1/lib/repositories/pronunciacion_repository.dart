import 'package:cloud_firestore/cloud_firestore.dart';

class PronunciacionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> guardarPronunciacion({
    required String interaccionId,
    required String estudianteUid,
    required String cursoId,
    required String textoReconocido,
    required String textoReferencia,
    required Map<String, dynamic> resultado,
  }) async {
    await _firestore.collection('pronunciacion').add({
      'interaccion_id': interaccionId,
      'estudiante_uid': estudianteUid,
      'curso_id': cursoId,
      'texto_reconocido': textoReconocido,
      'texto_referencia': textoReferencia,
      'palabras_correctas': resultado['palabras_correctas'] ?? [],
      'palabras_observadas': resultado['palabras_observadas'] ?? [],
      'puntuacion_pronunciacion':
          (resultado['puntuacion_pronunciacion'] ?? 0).toDouble(),
      'comentario_oral': resultado['comentario_oral'] ?? "",
      'sugerencias_orales': resultado['sugerencias_orales'] ?? [],
      'fecha_pronunciacion': FieldValue.serverTimestamp(),
    });
  }
}
