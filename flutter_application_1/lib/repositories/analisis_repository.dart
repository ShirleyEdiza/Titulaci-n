import 'package:cloud_firestore/cloud_firestore.dart';

class AnalisisRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> guardarAnalisis({
    required String respuestaId,
    required String interaccionId,
    required String estudianteUid,
    required String cursoId,
    required String textoOriginal,
    required Map<String, dynamic> resultado,
    int totalRespuestas = 0,
    double puntuacionPronunciacion = 0,
  }) async {
    await _firestore.collection('analisis').add({
      'respuesta_id': respuestaId,
      'interaccion_id': interaccionId,
      'estudiante_uid': estudianteUid,
      'curso_id': cursoId,
      'texto_original': textoOriginal,
      'texto_corregido': resultado['texto_corregido'] ?? textoOriginal,
      'errores_detectados': resultado['errores_detectados'] ?? [],
      'puntuacion_gramatica':
          (resultado['puntuacion_gramatica'] ?? 0).toDouble(),
      'puntuacion_pronunciacion': puntuacionPronunciacion,
      'total_respuestas': totalRespuestas,
      'finalizado': true,
      'nivel_detectado': resultado['nivel_detectado'] ?? 'A1',
      'fecha_analisis': FieldValue.serverTimestamp(),
    });
  }

  Future<void> guardarFeedback({
    required String interaccionId,
    required String estudianteUid,
    required String cursoId,
    required String comentario,
    required List sugerencias,
    required List puntosFuertes,
  }) async {
    await _firestore.collection('feedback').add({
      'interaccion_id': interaccionId,
      'estudiante_uid': estudianteUid,
      'curso_id': cursoId,
      'comentario': comentario,
      'sugerencias': sugerencias,
      'puntos_fuertes': puntosFuertes,
      'fecha_feedback': FieldValue.serverTimestamp(),
    });
  }
}
