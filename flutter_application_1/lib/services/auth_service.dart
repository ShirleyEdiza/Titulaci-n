import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int maxIntentos = 3;

  String _normalizarEmail(String email) {
    return email.trim().toLowerCase();
  }

  String _idIntento(String email) {
    return _normalizarEmail(email).replaceAll('.', '_');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final emailNormalizado = _normalizarEmail(email);
    final intentoRef =
        _db.collection('intentos_login').doc(_idIntento(emailNormalizado));

    try {
      final intentoDoc = await intentoRef.get();

      if (intentoDoc.exists) {
        final data = intentoDoc.data() ?? {};
        final bloqueado = data['bloqueado'] ?? false;
        final bloqueoHasta = data['bloqueo_hasta'];

        if (bloqueado == true && bloqueoHasta is Timestamp) {
          final fechaBloqueo = bloqueoHasta.toDate();

          if (DateTime.now().isBefore(fechaBloqueo)) {
            final minutosRestantes =
                fechaBloqueo.difference(DateTime.now()).inMinutes + 1;

            return {
              'success': false,
              'message':
                  'Cuenta bloqueada. Intenta en $minutosRestantes minutos.',
            };
          } else {
            await intentoRef.delete();
          }
        }
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailNormalizado,
        password: password,
      );

      final user = userCredential.user;

      if (user == null) {
        return {
          'success': false,
          'message': 'No se pudo iniciar sesión.',
        };
      }

      final userDoc = await _db.collection('usuarios').doc(user.uid).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Usuario no registrado en el sistema.',
        };
      }

      final data = userDoc.data() as Map<String, dynamic>;

      final activo = data['activo'] ?? true;

      if (activo == false) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Usuario desactivado.',
        };
      }

      await intentoRef.delete().catchError((_) {});

      return {
        'success': true,
        'rol': data['rol'] ?? data['role'] ?? 'estudiante',
        'usuario': UsuarioModel.fromMap(user.uid, data),
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'user-not-found') {
        final restantes = await _registrarIntentoFallido(
          intentoRef,
          emailNormalizado,
        );

        if (restantes <= 0) {
          return {
            'success': false,
            'message':
                'Cuenta bloqueada por 15 minutos por múltiples intentos fallidos.',
          };
        }

        return {
          'success': false,
          'message':
              'Correo o contraseña incorrectos. Te quedan $restantes intentos.',
        };
      }

      if (e.code == 'invalid-email') {
        return {
          'success': false,
          'message': 'Correo inválido.',
        };
      }

      if (e.code == 'too-many-requests') {
        return {
          'success': false,
          'message': 'Demasiados intentos. Intenta más tarde.',
        };
      }

      return {
        'success': false,
        'message': 'Error al iniciar sesión.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al conectar con el servidor.',
      };
    }
  }

  Future<int> _registrarIntentoFallido(
    DocumentReference<Map<String, dynamic>> intentoRef,
    String email,
  ) async {
    final doc = await intentoRef.get();

    int intentos = 1;

    if (doc.exists) {
      final data = doc.data() ?? {};
      intentos = ((data['intentos'] ?? 0) as int) + 1;
    }

    final bloqueado = intentos >= maxIntentos;

    await intentoRef.set({
      'email': email,
      'intentos': intentos,
      'bloqueado': bloqueado,
      'ultima_vez': FieldValue.serverTimestamp(),
      if (bloqueado)
        'bloqueo_hasta':
            Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 15))),
    }, SetOptions(merge: true));

    return maxIntentos - intentos;
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String nombre,
  ) async {
    try {
      final emailNormalizado = _normalizarEmail(email);

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailNormalizado,
        password: password,
      );

      await _db.collection('usuarios').doc(userCredential.user!.uid).set({
        'email': emailNormalizado,
        'nombre': nombre,
        'rol': 'estudiante',
        'activo': true,
        'fecha_registro': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } on FirebaseAuthException catch (e) {
      String message = 'Error al registrar';

      if (e.code == 'email-already-in-use') {
        message = 'Este correo ya está registrado';
      } else if (e.code == 'weak-password') {
        message =
            'La contraseña debe tener mayúscula, minúscula, número y carácter especial.';
      } else if (e.code == 'invalid-email') {
        message = 'Correo inválido';
      }

      return {'success': false, 'message': message};
    }
  }

  Future<Map<String, dynamic>> recuperarContrasena(String email) async {
    try {
      final emailNormalizado = _normalizarEmail(email);

      await _auth.sendPasswordResetEmail(email: emailNormalizado);

      return {
        'success': true,
        'message': 'Correo de recuperación enviado a $emailNormalizado',
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return {'success': false, 'message': 'Correo no registrado'};
      }

      if (e.code == 'invalid-email') {
        return {'success': false, 'message': 'Correo inválido'};
      }

      return {'success': false, 'message': 'Error al enviar correo'};
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
