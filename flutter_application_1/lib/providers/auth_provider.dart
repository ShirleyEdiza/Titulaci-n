import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/usuario_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final UsuarioRepository _usuarioRepo = UsuarioRepository();

  UsuarioModel? _usuario;
  bool _loading = false;
  String _error = '';

  UsuarioModel? get usuario => _usuario;
  bool get loading => _loading;
  String get error => _error;

  // LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    _loading = true;
    _error = '';
    notifyListeners();

    final result = await _authRepo.login(email, password);

    if (result['success']) {
      _usuario = result['usuario'];
    } else {
      _error = result['message'];
    }

    _loading = false;
    notifyListeners();

    return result;
  }

  // REGISTER
  Future<Map<String, dynamic>> register(
      String email, String password, String nombre) async {
    _loading = true;
    notifyListeners();

    final result = await _authRepo.register(email, password, nombre);

    _loading = false;
    notifyListeners();

    return result;
  }

  // RECUPERAR CONTRASEÑA
  Future<Map<String, dynamic>> recuperarContrasena(String email) async {
    _loading = true;
    notifyListeners();

    final result = await _authRepo.recuperarContrasena(email);

    _loading = false;
    notifyListeners();

    return result;
  }

  // LOGOUT
  Future<void> logout() async {
    await _authRepo.logout();
    _usuario = null;
    notifyListeners();
  }

  // Stream del usuario en tiempo real (Eventos)
  Stream<UsuarioModel?> streamUsuario(String uid) {
    return _usuarioRepo.streamUsuario(uid);
  }
}
