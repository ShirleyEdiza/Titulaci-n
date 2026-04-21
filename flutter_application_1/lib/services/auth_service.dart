import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Máximo de intentos fallidos
  static const int maxIntentos = 3;

  // LOGIN CON CONTROL DE INTENTOS
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Verificar intentos fallidos antes de intentar login
      QuerySnapshot intentosSnap = await _db
          .collection('intentos_login')
          .where('email', isEqualTo: email)
          .where('bloqueado', isEqualTo: true)
          .get();

      if (intentosSnap.docs.isNotEmpty) {
        var data = intentosSnap.docs.first.data() as Map<String, dynamic>;
        DateTime? bloqueoHasta = data['bloqueo_hasta']?.toDate();

        if (bloqueoHasta != null && DateTime.now().isBefore(bloqueoHasta)) {
          int minutosRestantes =
              bloqueoHasta.difference(DateTime.now()).inMinutes + 1;
          return {
            'success': false,
            'message':
                'Cuenta bloqueada. Intenta en $minutosRestantes minutos.',
          };
        } else {
          // Desbloquear si ya pasó el tiempo
          await intentosSnap.docs.first.reference.delete();
        }
      }

      // Intentar login
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Login exitoso - limpiar intentos
      await _limpiarIntentos(email);

      // Obtener datos del usuario
      DocumentSnapshot userDoc =
          await _db.collection('usuarios').doc(userCredential.user!.uid).get();

      if (!userDoc.exists) {
        return {
          'success': false,
          'message': 'Usuario no registrado en el sistema',
        };
      }

      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

      bool activo = data['activo'] ?? true;
      if (!activo) {
        return {'success': false, 'message': 'Usuario desactivado'};
      }

      return {
        'success': true,
        'rol': data['rol'] ?? 'estudiante',
        'usuario': UsuarioModel.fromMap(userCredential.user!.uid, data),
      };
    } on FirebaseAuthException catch (e) {
      // Registrar intento fallido
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        await _registrarIntentoFallido(email);
        int intentosRestantes = await _getIntentosRestantes(email);

        if (intentosRestantes <= 0) {
          return {
            'success': false,
            'message':
                'Cuenta bloqueada por 15 minutos por múltiples intentos fallidos.',
          };
        }

        return {
          'success': false,
          'message':
              'Contraseña incorrecta. Te quedan $intentosRestantes intentos.',
        };
      }

      if (e.code == 'user-not-found') {
        return {'success': false, 'message': 'Correo no registrado'};
      }

      if (e.code == 'invalid-email') {
        return {'success': false, 'message': 'Correo inválido'};
      }

      return {'success': false, 'message': 'Error al iniciar sesión'};
    }
  }

  // REGISTRO
  Future<Map<String, dynamic>> register(
      String email, String password, String nombre) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.collection('usuarios').doc(userCredential.user!.uid).set({
        'email': email,
        'nombre': nombre,
        'rol': 'estudiante',
        'activo': true,
        'fecha_registro': DateTime.now(),
      });

      return {'success': true};
    } on FirebaseAuthException catch (e) {
      String message = 'Error al registrar';

      if (e.code == 'email-already-in-use') {
        message = 'Este correo ya está registrado';
      } else if (e.code == 'weak-password') {
        message = 'La contraseña debe tener al menos 6 caracteres';
      } else if (e.code == 'invalid-email') {
        message = 'Correo inválido';
      }

      return {'success': false, 'message': message};
    }
  }

  // RECUPERAR CONTRASEÑA
  Future<Map<String, dynamic>> recuperarContrasena(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Correo de recuperación enviado a $email',
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return {'success': false, 'message': 'Correo no registrado'};
      }
      return {'success': false, 'message': 'Error al enviar correo'};
    }
  }

  // CERRAR SESIÓN
  Future<void> logout() async {
    await _auth.signOut();
  }

  // MÉTODOS PRIVADOS
  Future<void> _registrarIntentoFallido(String email) async {
    QuerySnapshot snap = await _db
        .collection('intentos_login')
        .where('email', isEqualTo: email)
        .get();

    if (snap.docs.isEmpty) {
      await _db.collection('intentos_login').add({
        'email': email,
        'intentos': 1,
        'bloqueado': false,
        'ultima_vez': DateTime.now(),
      });
    } else {
      var doc = snap.docs.first;
      var data = doc.data() as Map<String, dynamic>;
      int intentos = (data['intentos'] ?? 0) + 1;

      if (intentos >= maxIntentos) {
        await doc.reference.update({
          'intentos': intentos,
          'bloqueado': true,
          'bloqueo_hasta': DateTime.now().add(const Duration(minutes: 15)),
        });
      } else {
        await doc.reference.update({
          'intentos': intentos,
          'ultima_vez': DateTime.now(),
        });
      }
    }
  }

  Future<int> _getIntentosRestantes(String email) async {
    QuerySnapshot snap = await _db
        .collection('intentos_login')
        .where('email', isEqualTo: email)
        .get();

    if (snap.docs.isEmpty) return maxIntentos;
    var data = snap.docs.first.data() as Map<String, dynamic>;
    int intentos = data['intentos'] ?? 0;
    return maxIntentos - intentos;
  }

  Future<void> _limpiarIntentos(String email) async {
    QuerySnapshot snap = await _db
        .collection('intentos_login')
        .where('email', isEqualTo: email)
        .get();

    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}
