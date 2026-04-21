class TurnoModel {
  final int turno;
  final String preguntaIA;
  final String respuestaTexto;
  final String audioUrl;
  final List<Map<String, dynamic>> erroresGramaticales;
  final double pronunciacionScore;
  final List<String> palabrasMalPronunciadas;

  TurnoModel({
    required this.turno,
    required this.preguntaIA,
    required this.respuestaTexto,
    required this.audioUrl,
    required this.erroresGramaticales,
    required this.pronunciacionScore,
    required this.palabrasMalPronunciadas,
  });

  Map<String, dynamic> toMap() {
    return {
      'turno': turno,
      'pregunta_ia': preguntaIA,
      'respuesta_texto': respuestaTexto,
      'audio_url': audioUrl,
      'errores_gramaticales': erroresGramaticales,
      'pronunciacion_score': pronunciacionScore,
      'palabras_mal_pronunciadas': palabrasMalPronunciadas,
    };
  }
}

class SesionModel {
  final String id;
  final String estudianteUid;
  final String cursoId;
  final DateTime fecha;
  final int duracionSegundos;
  final int totalTurnos;
  final List<TurnoModel> conversacion;

  SesionModel({
    required this.id,
    required this.estudianteUid,
    required this.cursoId,
    required this.fecha,
    required this.duracionSegundos,
    required this.totalTurnos,
    required this.conversacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'estudiante_uid': estudianteUid,
      'curso_id': cursoId,
      'fecha': fecha,
      'duracion_segundos': duracionSegundos,
      'total_turnos': totalTurnos,
      'conversacion': conversacion.map((t) => t.toMap()).toList(),
    };
  }
}
