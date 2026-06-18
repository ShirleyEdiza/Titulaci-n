import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int maxIntentos = 3;

  String _normalizarEmail(String email) {
    return email.trim().toLowerCase();
  }

  String _idIntento(String email) {
    return _normalizarEmail(email).replaceAll('.', '_').replaceAll('@', '_');
  }

  Future<bool> correoExiste(String email) async {
    try {
      final emailNormalizado = _normalizarEmail(email);

      final query = await _db
          .collection('usuarios')
          .where('email', isEqualTo: emailNormalizado)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 3));

      return query.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final emailNormalizado = _normalizarEmail(email);
    final intentoRef =
        _db.collection('intentos_login').doc(_idIntento(emailNormalizado));

    try {
      // 1. Primero validar si está bloqueado.
      final intentoDoc =
          await intentoRef.get().timeout(const Duration(seconds: 5));

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
            await intentoRef.delete().timeout(const Duration(seconds: 3));
          }
        }
      }

      // 2. Autenticación con Firebase.
      final userCredential = await _auth
          .signInWithEmailAndPassword(
            email: emailNormalizado,
            password: password,
          )
          .timeout(const Duration(seconds: 10));

      final user = userCredential.user;

      if (user == null) {
        return {
          'success': false,
          'message': 'No se pudo iniciar sesión.',
        };
      }

      // 3. Leer datos del usuario por UID.
      final userDoc = await _db
          .collection('usuarios')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 6));

      if (!userDoc.exists) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Usuario no registrado en el sistema.',
        };
      }

      final data = userDoc.data() ?? {};

      final activo = data['activo'] ?? true;

      if (activo == false) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Usuario desactivado.',
        };
      }

      // 4. Limpia intentos, pero no bloquea el login si falla.
      intentoRef.delete().catchError((_) {});

      return {
        'success': true,
        'rol': data['rol'] ?? data['role'] ?? 'estudiante',
        'usuario': UsuarioModel.fromMap(user.uid, data),
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return {
          'success': false,
          'message': 'El correo ingresado no existe.',
        };
      }

      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
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
          'message': 'Contraseña incorrecta. Te quedan $restantes intentos.',
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
        'message':
            'No se pudo conectar. Revisa tu internet e intenta nuevamente.',
      };
    }
  }

  Future<int> _registrarIntentoFallido(
    DocumentReference<Map<String, dynamic>> intentoRef,
    String email,
  ) async {
    try {
      final doc = await intentoRef.get().timeout(const Duration(seconds: 4));

      int intentos = 1;

      if (doc.exists) {
        final data = doc.data() ?? {};
        final valor = data['intentos'] ?? 0;
        intentos = valor is int ? valor + 1 : 1;
      }

      final bloqueado = intentos >= maxIntentos;

      await intentoRef.set({
        'email': email,
        'intentos': intentos,
        'bloqueado': bloqueado,
        'ultima_vez': FieldValue.serverTimestamp(),
        if (bloqueado)
          'bloqueo_hasta': Timestamp.fromDate(
            DateTime.now().add(const Duration(minutes: 15)),
          ),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));

      return maxIntentos - intentos;
    } catch (_) {
      return maxIntentos - 1;
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String nombre,
  ) async {
    try {
      final emailNormalizado = _normalizarEmail(email);

      final userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailNormalizado,
            password: password,
          )
          .timeout(const Duration(seconds: 10));

      await _db.collection('usuarios').doc(userCredential.user!.uid).set({
        'email': emailNormalizado,
        'nombre': nombre,
        'rol': 'estudiante',
        'activo': true,
        'fecha_registro': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 6));

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
    } catch (_) {
      return {
        'success': false,
        'message': 'No se pudo completar el registro. Revisa tu conexión.',
      };
    }
  }

  Future<Map<String, dynamic>> recuperarContrasena(String email) async {
    try {
      final emailNormalizado = _normalizarEmail(email);

      final response = await http
          .post(
            Uri.parse('https://titulaci-n.onrender.com/recuperar-password'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': emailNormalizado,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'No se pudo enviar el correo.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'No se pudo conectar con el servidor.',
      };
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
