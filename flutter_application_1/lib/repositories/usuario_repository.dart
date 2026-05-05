import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';

class UsuarioRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Obtener usuario por UID
  Future<UsuarioModel?> getUsuario(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('usuarios').doc(uid).get();

      if (!doc.exists) return null;

      return UsuarioModel.fromMap(uid, doc.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // Stream en tiempo real del usuario (Eventos)
  Stream<UsuarioModel?> streamUsuario(String uid) {
    return _db.collection('usuarios').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UsuarioModel.fromMap(uid, doc.data() as Map<String, dynamic>);
    });
  }

  // Actualizar datos del usuario
  Future<void> actualizarUsuario(String uid, Map<String, dynamic> datos) async {
    await _db.collection('usuarios').doc(uid).update(datos);
  }
}
