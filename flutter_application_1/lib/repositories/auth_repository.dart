import '../services/auth_service.dart';
import '../models/usuario_model.dart';

class AuthRepository {
  final AuthService _authService = AuthService();

  // El ViewModel llama al Repository
  // El Repository llama al Service
  // El Service llama a Firebase

  Future<Map<String, dynamic>> login(String email, String password) async {
    return await _authService.login(email, password);
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String nombre) async {
    return await _authService.register(email, password, nombre);
  }

  Future<Map<String, dynamic>> recuperarContrasena(String email) async {
    return await _authService.recuperarContrasena(email);
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}
