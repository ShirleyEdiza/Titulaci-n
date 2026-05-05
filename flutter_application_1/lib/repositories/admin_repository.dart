import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> obtenerCursos() {
    return _db
        .collection('cursos')
        .where('activo', isEqualTo: true)
        .snapshots();
  }

  Future<void> crearCurso(Map<String, dynamic> data) async {
    await _db.collection('cursos').add(data);
  }

  Future<void> actualizarCurso(String id, Map<String, dynamic> data) async {
    await _db.collection('cursos').doc(id).update(data);
  }

  Future<void> eliminarCurso(String id) async {
    await _db.collection('cursos').doc(id).update({'activo': false});
  }
}
