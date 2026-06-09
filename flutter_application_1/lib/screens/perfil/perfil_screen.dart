import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _guardarNombre() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nombre = _nombreController.text.trim();

    if (nombre.length < 3) {
      _mensaje("Ingrese un nombre válido.");
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

      _mensaje("Nombre actualizado correctamente.");
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
      _mensaje("Ingrese su contraseña actual.");
      return;
    }

    final error = PasswordValidator.validarConfirmacion(nueva, confirmar);
    if (error != null) {
      _mensaje(error);
      return;
    }

    setState(() => cargando = true);

    try {
      final credencial = EmailAuthProvider.credential(
        email: user.email!,
        password: actual,
      );

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
        _mensaje("La contraseña actual es incorrecta.");
      } else if (e.code == 'weak-password') {
        _mensaje("La nueva contraseña es muy débil.");
      } else {
        _mensaje("No se pudo cambiar la contraseña.");
      }
    } catch (e) {
      _mensaje("Ocurrió un error al cambiar la contraseña.");
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

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
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
            decoration: const InputDecoration(
              labelText: "Nombre",
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
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
          const SizedBox(height: 10),
          _passwordField(
            controller: _confirmarController,
            label: "Confirmar nueva contraseña",
            ocultar: ocultarConfirmar,
            onToggle: () {
              setState(() => ocultarConfirmar = !ocultarConfirmar);
            },
          ),
          const SizedBox(height: 10),
          const Text(
            "Debe tener mínimo 8 caracteres, mayúscula, minúscula, número y carácter especial.",
            style: TextStyle(fontSize: 11, color: Colors.grey),
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
