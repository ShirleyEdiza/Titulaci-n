class CursoModel {
  final String id;
  final String nombre;
  final String codigoAcceso;
  final String docenteUid;
  final String nivel;
  final bool activo;
  final DateTime fechaCreacion;

  CursoModel({
    required this.id,
    required this.nombre,
    required this.codigoAcceso,
    required this.docenteUid,
    required this.nivel,
    required this.activo,
    required this.fechaCreacion,
  });

  factory CursoModel.fromMap(String id, Map<String, dynamic> data) {
    return CursoModel(
      id: id,
      nombre: data['nombre'] ?? '',
      codigoAcceso: data['codigo_acceso'] ?? '',
      docenteUid: data['docente_uid'] ?? '',
      nivel: data['nivel'] ?? 'A1',
      activo: data['activo'] ?? true,
      fechaCreacion: data['fecha_creacion']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'codigo_acceso': codigoAcceso,
      'docente_uid': docenteUid,
      'nivel': nivel,
      'activo': activo,
      'fecha_creacion': fechaCreacion,
    };
  }
}
