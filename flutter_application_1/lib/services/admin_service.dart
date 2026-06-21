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
    const mayus = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const minus = 'abcdefghijklmnopqrstuvwxyz';
    const nums = '123456789';
    const especiales = '@#*';

    final rnd = Random();

    final chars = [
      mayus[rnd.nextInt(mayus.length)],
      minus[rnd.nextInt(minus.length)],
      nums[rnd.nextInt(nums.length)],
      especiales[rnd.nextInt(especiales.length)],
      ...List.generate(
        6,
        (_) {
          const todos =
              'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz123456789@#*';
          return todos[rnd.nextInt(todos.length)];
        },
      ),
    ];

    chars.shuffle(rnd);
    return chars.join();
  }
}
