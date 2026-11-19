import 'package:flutter/material.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/aura_colores.dart';
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
      setState(() => _error = context.t('auth.err_correo'));
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
        _error = context.t('auth.err_conexion');
      });
    }
  }

 
  @override
  Widget build(BuildContext context) {
    return AuthPagina(
      titulo: context.t('auth.titulo_acceso'),
      subtitulo: context.t('auth.sub_acceso'),
      conAtras: !widget.embebido,
      hijos: [
        AuthCampo(
          label: context.t('auth.correo'),
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
        AuthBoton(
          texto: context.t('comun.continuar'),
          cargando: _cargando,
          onPressed: _continuar,
        ),
      ],
    );
  }
}
