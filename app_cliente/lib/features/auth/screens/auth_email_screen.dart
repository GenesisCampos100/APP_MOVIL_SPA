import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/repositories/auth_repository.dart';
import '../widgets/auth_widgets.dart';

/// "Ingresa a Aura Spa": punto de entrada único para iniciar sesión o
/// registrarse. [embebido] = true cuando se muestra dentro de una pestaña.
class AuthEmailScreen extends StatefulWidget {
  final bool embebido;
  const AuthEmailScreen({super.key, this.embebido = false});

  @override
  State<AuthEmailScreen> createState() => _AuthEmailScreenState();
}

class _AuthEmailScreenState extends State<AuthEmailScreen> {
  final _repo = AuthRepository();
  final _correo = TextEditingController();
  String? _error;
  bool _cargando = false;

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    final correo = _correo.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
      setState(() => _error = 'Ingresa un correo válido');
      return;
    }
    setState(() {
      _error = null;
      _cargando = true;
    });
    try {
      final existe = await _repo.existeCorreo(correo);
      if (!mounted) return;
      setState(() => _cargando = false);
      Navigator.pushNamed(
        context,
        existe ? AppRoutes.authPassword : AppRoutes.authRegistro,
        arguments: correo,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo conectar. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPagina(
      titulo: 'Ingresa a Aura Spa',
      subtitulo: 'Usa tu correo para verificar y continuar.',
      conAtras: !widget.embebido,
      hijos: [
        AuthCampo(
          label: 'Correo electronico',
          controller: _correo,
          errorText: _error,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _continuar(),
        ),
        const SizedBox(height: 24),
        AuthBoton(texto: 'Continuar', cargando: _cargando, onPressed: _continuar),
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('o', style: TextStyle(color: Colors.black54)),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Acceso con Google: próximamente')),
          ),
          icon: const Icon(Icons.g_mobiledata, size: 30),
          label: const Text('Continuar con Google'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(46),
            side: const BorderSide(color: Colors.black54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
