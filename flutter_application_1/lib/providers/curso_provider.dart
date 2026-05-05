import 'package:flutter/material.dart';
import '../models/curso_model.dart';
import '../repositories/curso_repository.dart';

class CursoProvider extends ChangeNotifier {
  final CursoRepository _cursoRepo = CursoRepository();

  CursoModel? _cursoActual;
  bool _loading = false;
  String _error = '';

  CursoModel? get cursoActual => _cursoActual;
  bool get loading => _loading;
  String get error => _error;

  // Buscar curso por código
  Future<bool> buscarCursoPorCodigo(String codigo) async {
    _loading = true;
    _error = '';
    notifyListeners();

    CursoModel? curso = await _cursoRepo.getCursoPorCodigo(codigo);

    if (curso != null) {
      _cursoActual = curso;
      _loading = false;
      notifyListeners();
      return true;
    } else {
      _error = 'Código de curso inválido';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Stream cursos del docente en tiempo real
  Stream<List<CursoModel>> streamCursosDocente(String docenteUid) {
    return _cursoRepo.streamCursosDocente(docenteUid);
  }

  // Stream todos los cursos (Admin)
  Stream<List<CursoModel>> streamTodosLosCursos() {
    return _cursoRepo.streamTodosLosCursos();
  }
}
