class PasswordValidator {
  static String? validar(String password) {
    if (password.trim().isEmpty) {
      return "Ingrese una contraseña.";
    }

    if (password.length < 8) {
      return "La contraseña debe tener al menos 8 caracteres.";
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Debe incluir al menos una letra mayúscula.";
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Debe incluir al menos una letra minúscula.";
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Debe incluir al menos un número.";
    }

    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=]').hasMatch(password)) {
      return "Debe incluir al menos un carácter especial.";
    }

    return null;
  }

  static String? validarConfirmacion(String password, String confirmacion) {
    final error = validar(password);

    if (error != null) return error;

    if (password != confirmacion) {
      return "Las contraseñas no coinciden.";
    }

    return null;
  }
}
