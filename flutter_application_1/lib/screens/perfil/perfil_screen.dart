import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';

import '../../utils/password_validator.dart';
import '../auth/login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _nombreController = TextEditingController();
  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _confirmarController = TextEditingController();

  bool cargando = false;
  bool ocultarActual = true;
  bool ocultarNueva = true;
  bool ocultarConfirmar = true;

  String rol = "";
  String email = "";

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    final data = doc.data() ?? {};

    setState(() {
      _nombreController.text = data['nombre'] ?? '';
      rol = data['rol'] ?? data['role'] ?? 'usuario';
      email = user.email ?? data['email'] ?? '';
    });
  }

  String? _validarNombreCompleto(String valor) {
    final nombre = valor.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (nombre.isEmpty) {
      return "El nombre es obligatorio.";
    }

    if (nombre.length < 7) {
      return "Ingrese un nombre y apellido válidos. Ejemplo: Ana Chela.";
    }

    if (RegExp(r'[0-9]').hasMatch(nombre)) {
      return "El nombre no debe contener números.";
    }

    if (RegExp(r'[^A-Za-zÁÉÍÓÚáéíóúÑñ\s]').hasMatch(nombre)) {
      return "El nombre no debe contener símbolos ni caracteres especiales.";
    }

    final partes = nombre.split(' ');

    if (partes.length < 2) {
      return "Ingrese nombre y apellido. Ejemplo: Ana Chela.";
    }

    if (partes.any((p) => p.length < 3)) {
      return "El nombre y apellido deben tener al menos 3 letras.";
    }

    if (partes
        .any((p) => RegExp(r'^(.)\1+$', caseSensitive: false).hasMatch(p))) {
      return "Ingrese un nombre real, no letras repetidas.";
    }

    return null;
  }

  Future<void> _guardarNombre() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nombre =
        _nombreController.text.trim().replaceAll(RegExp(r'\s+'), ' ');

    final errorNombre = _validarNombreCompleto(nombre);
    if (errorNombre != null) {
      _mensaje(errorNombre, error: true);
      return;
    }

    setState(() => cargando = true);

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .update({
        'nombre': nombre,
        'fecha_actualizacion': FieldValue.serverTimestamp(),
      });

      await user.updateDisplayName(nombre);
      await user.reload();

      if (!mounted) return;

      setState(() {
        _nombreController.text = nombre;
      });

      _mensaje("Nombre actualizado correctamente.");

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _mensaje("No se pudo actualizar el nombre.");
    }

    if (mounted) setState(() => cargando = false);
  }

  Future<void> _cambiarPassword() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      _mensaje("No hay usuario autenticado.");
      return;
    }

    final actual = _actualController.text.trim();
    final nueva = _nuevaController.text.trim();
    final confirmar = _confirmarController.text.trim();

    if (actual.isEmpty) {
      _mensaje("Ingrese su contraseña actual.", error: true);
      return;
    }

    if (actual == nueva) {
      _mensaje(
        "La nueva contraseña debe ser diferente a la contraseña actual.",
        error: true,
      );
      return;
    }

    final error = PasswordValidator.validarConfirmacion(nueva, confirmar);
    if (error != null) {
      _mensaje(error, error: true);
      return;
    }

    setState(() => cargando = true);

    try {
      final credencial = EmailAuthProvider.credential(
        email: user.email!,
        password: actual,
      );

      await user.reauthenticateWithCredential(credencial);
      await user.updatePassword(nueva);

      _actualController.clear();
      _nuevaController.clear();
      _confirmarController.clear();

      _mensaje(
          "✓ Contraseña actualizada correctamente.\nPor seguridad deberás volver a iniciar sesión.");

      await Future.delayed(const Duration(seconds: 2));

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _mensaje("La contraseña actual es incorrecta.", error: true);
      } else if (e.code == 'weak-password') {
        _mensaje("La nueva contraseña es muy débil.", error: true);
      } else {
        _mensaje("No se pudo cambiar la contraseña.", error: true);
      }
    } catch (e) {
      _mensaje("Ocurrió un error al cambiar la contraseña.", error: true);
    }

    if (mounted) setState(() => cargando = false);
  }

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _mensaje(String texto, {bool error = false}) {
    if (error) {
      CustomSnackbar.error(context, texto);
    } else {
      CustomSnackbar.success(context, texto);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text("Mi perfil"),
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  _cardDatos(),
                  const SizedBox(height: 16),
                  _cardPassword(),
                  const SizedBox(height: 16),
                  _botonSalir(),
                ],
              ),
            ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFF1A237E),
            child: Text(
              _nombreController.text.isNotEmpty
                  ? _nombreController.text[0].toUpperCase()
                  : "U",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _nombreController.text.isEmpty ? "Usuario" : _nombreController.text,
            style: const TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          Text(
            "$rol · $email",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _cardDatos() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Datos personales",
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nombreController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: "Nombre",
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          _nombreRules(),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _guardarNombre,
            icon: const Icon(Icons.save),
            label: const Text("Guardar cambios"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardPassword() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Cambiar contraseña",
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _passwordField(
            controller: _actualController,
            label: "Contraseña actual",
            ocultar: ocultarActual,
            onToggle: () {
              setState(() => ocultarActual = !ocultarActual);
            },
          ),
          const SizedBox(height: 10),
          _passwordField(
            controller: _nuevaController,
            label: "Nueva contraseña",
            ocultar: ocultarNueva,
            onToggle: () {
              setState(() => ocultarNueva = !ocultarNueva);
            },
          ),
          const SizedBox(height: 8),
          _passwordRules(),
          const SizedBox(height: 10),
          _passwordField(
            controller: _confirmarController,
            label: "Confirmar nueva contraseña",
            ocultar: ocultarConfirmar,
            onToggle: () {
              setState(() => ocultarConfirmar = !ocultarConfirmar);
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _cambiarPassword,
            icon: const Icon(Icons.lock_reset),
            label: const Text("Actualizar contraseña"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool ocultar,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: ocultar,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(ocultar ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Widget _passwordRules() {
    final password = _nuevaController.text;

    Widget item(String texto, bool cumple) {
      return Row(
        children: [
          Icon(
            cumple ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: cumple ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              color: cumple ? Colors.green : Colors.grey,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        item("Mínimo 8 caracteres", password.length >= 8),
        item("Una letra mayúscula", RegExp(r'[A-Z]').hasMatch(password)),
        item("Una letra minúscula", RegExp(r'[a-z]').hasMatch(password)),
        item("Un número", RegExp(r'[0-9]').hasMatch(password)),
        item("Un carácter especial",
            RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)),
      ],
    );
  }

  Widget _nombreRules() {
    final nombre =
        _nombreController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final cumple = _validarNombreCompleto(nombre) == null;

    return Row(
      children: [
        Icon(
          cumple ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: cumple ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            "Ingrese nombre y apellido. Ejemplo: Ana Chela",
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _botonSalir() {
    return OutlinedButton.icon(
      onPressed: _cerrarSesion,
      icon: const Icon(Icons.logout),
      label: const Text("Cerrar sesión"),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFB71C1C),
        side: const BorderSide(color: Color(0xFFB71C1C)),
        minimumSize: const Size(double.infinity, 46),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
