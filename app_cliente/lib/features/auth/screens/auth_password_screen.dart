import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../auth_flow.dart';
import '../auth_state.dart';
import '../widgets/auth_widgets.dart';

/// "Bienvenido de nuevo": el correo ya está verificado (campo bloqueado),
/// solo se pide la contraseña.
class AuthPasswordScreen extends StatefulWidget {
  final String correo;
  const AuthPasswordScreen({super.key, required this.correo});

  @override
  State<AuthPasswordScreen> createState() => _AuthPasswordScreenState();
}

class _AuthPasswordScreenState extends State<AuthPasswordScreen> {
  final _repo = AuthRepository();
  final _password = TextEditingController();
  String? _error;
  bool _cargando = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Ingresa tu contraseña');
      return;
    }
    setState(() {
      _error = null;
      _cargando = true;
    });
    try {
      final usuario = await _repo.iniciarSesion(widget.correo, _password.text);
      if (!mounted) return;
      if (usuario == null) {
        setState(() {
          _cargando = false;
          _error = 'Contraseña incorrecta';
        });
        return;
      }
      AuthState.instance.iniciarSesion(usuario);
      AuthFlow.terminar(context);
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
      titulo: 'Bienvenido de nuevo',
      subtitulo: 'Ingresa tu contraseña para continuar',
      hijos: [
        AuthCampo(
          label: 'Correo electronico',
          controller: TextEditingController(text: widget.correo),
          enabled: false,
        ),
        const SizedBox(height: 16),
        AuthCampoPassword(
          controller: _password,
          errorText: _error,
          onSubmitted: (_) => _continuar(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recuperar contraseña: próximamente')),
            ),
            child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(height: 8),
        AuthBoton(texto: 'Continuar', cargando: _cargando, onPressed: _continuar),
      ],
    );
  }
}
