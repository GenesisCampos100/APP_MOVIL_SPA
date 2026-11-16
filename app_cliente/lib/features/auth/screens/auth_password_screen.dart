import 'package:flutter/material.dart';
import '../../../core/i18n/textos.dart';
import '../../../data/repositories/auth_repository.dart';
import '../auth_flow.dart';
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
      setState(() => _error = context.t('auth.err_password_vacia'));
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
          _error = context.t('auth.err_password');
        });
        return;
      }
      AuthFlow.terminar(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = context.t('auth.err_conexion');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPagina(
      titulo: context.t('auth.bienvenido'),
      subtitulo: context.t('auth.sub_bienvenido'),
      hijos: [
        AuthCampo(
          label: context.t('auth.correo'),
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
              SnackBar(
                content: Text(context.t('comun.proximamente',
                    {'que': context.t('auth.recuperar_q')})),
              ),
            ),
            child: Text(context.t('auth.olvidaste'), style: const TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(height: 8),
        AuthBoton(texto: context.t('comun.continuar'), cargando: _cargando, onPressed: _continuar),
      ],
    );
  }
}
