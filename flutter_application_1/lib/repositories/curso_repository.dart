import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/curso_model.dart';

class CursoRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Buscar curso por código de acceso
  Future<CursoModel?> getCursoPorCodigo(String codigo) async {
    try {
      QuerySnapshot snap = await _db
          .collection('cursos')
          .where('codigo_acceso', isEqualTo: codigo)
          .where('activo', isEqualTo: true)
          .get();

      if (snap.docs.isEmpty) return null;

      var doc = snap.docs.first;
      return CursoModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // Stream de cursos del docente en tiempo real (Eventos)
  Stream<List<CursoModel>> streamCursosDocente(String docenteUid) {
    return _db
        .collection('cursos')
        .where('docente_uid', isEqualTo: docenteUid)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                CursoModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Stream de todos los cursos (Admin) en tiempo real
  Stream<List<CursoModel>> streamTodosLosCursos() {
    return _db.collection('cursos').snapshots().map((snap) => snap.docs
        .map((doc) =>
            CursoModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  // Crear curso
  Future<String> crearCurso(CursoModel curso) async {
    DocumentReference ref = await _db.collection('cursos').add(curso.toMap());
    return ref.id;
  }

  // Eliminar estudiante de curso
  Future<void> eliminarEstudianteDeCurso(
      String estudianteUid, String cursoId) async {
    QuerySnapshot snap = await _db
        .collection('matriculas')
        .where('estudiante_uid', isEqualTo: estudianteUid)
        .where('curso_id', isEqualTo: cursoId)
        .get();

    for (var doc in snap.docs) {
      await doc.reference.update({'activo': false});
    }
  }
}
