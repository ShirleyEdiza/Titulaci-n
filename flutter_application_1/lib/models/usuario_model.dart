class UsuarioModel {
  final String uid;
  final String email;
  final String rol;
  final String nombre;
  final bool activo;
  final DateTime fechaRegistro;

  UsuarioModel({
    required this.uid,
    required this.email,
    required this.rol,
    required this.nombre,
    required this.activo,
    required this.fechaRegistro,
  });

  factory UsuarioModel.fromMap(String uid, Map<String, dynamic> data) {
    return UsuarioModel(
      uid: uid,
      email: data['email'] ?? '',
      rol: data['rol'] ?? 'estudiante',
      nombre: data['nombre'] ?? '',
      activo: data['activo'] ?? true,
      fechaRegistro: data['fecha_registro']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'rol': rol,
      'nombre': nombre,
      'activo': activo,
      'fecha_registro': fechaRegistro,
    };
  }
}
