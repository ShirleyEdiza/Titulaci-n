import 'dart:math';

class AdminService {
  // 🔹 Generar código de curso
  String generarCodigo() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789';
    final rnd = Random();

    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  // 🔹 Generar contraseña para docente
  String generarPassword() {
    const chars = 'ABC123xyz@#';
    final rnd = Random();

    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }
}
