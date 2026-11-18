import 'package:flutter/material.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../shared/widgets/pantalla_exito.dart';
import '../../auth/auth_state.dart';
import '../../auth/widgets/auth_widgets.dart';

/// Abre "Cambiar contraseña" (solo con sesión iniciada).
void abrirCambiarContrasena(BuildContext context) {
  if (!AuthState.instance.isLoggedIn) return;
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
  );
}

/// Cambiar contraseña: pide la actual, la nueva y su confirmación.
/// Al terminar muestra la pantalla de éxito con la palomita verde.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _repo = AuthRepository();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();

  String? _errActual, _errNueva, _errConfirmar;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_actual, _nueva, _confirmar]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  bool get _completo =>
      _actual.text.isNotEmpty && _nueva.text.isNotEmpty && _confirmar.text.isNotEmpty;

  bool _validar() {
    final n = _nueva.text;
    final cumpleReglas = n.length >= 8 &&
        RegExp(r'[A-Za-z]').hasMatch(n) &&
        RegExp(r'\d').hasMatch(n);

    String? errNueva;
    if (!cumpleReglas) {
      errNueva = context.t('pass.err_regla');
    } else if (n == _actual.text) {
      errNueva = context.t('pass.err_igual');
    }

    setState(() {
      _errActual = null;
      _errNueva = errNueva;
      _errConfirmar = _confirmar.text != n ? context.t('pass.err_no_coincide') : null;
    });
    return _errNueva == null && _errConfirmar == null;
  }

  Future<void> _guardar() async {
    if (!_validar()) return;
    final usuario = AuthState.instance.usuario;
    if (usuario == null) return;

    setState(() => _cargando = true);
    try {
      final ok = await _repo.cambiarContrasena(usuario.correo, _actual.text, _nueva.text);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _cargando = false;
          _errActual = context.t('pass.err_actual');
        });
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaExito(
            titulo: context.t('pass.ok_titulo'),
            mensaje: context.t('pass.ok_msg'),
            textoBoton: context.t('comun.listo'),
            onContinuar: (ctx) => Navigator.pop(ctx),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('pass.err_guardar'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('pass.titulo'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t('pass.intro'),
              style: TextStyle(fontSize: 12, color: context.aura.textoSecundario),
            ),
            const SizedBox(height: 20),
            AuthCampoPassword(
              label: context.t('pass.actual'),
              controller: _actual,
              errorText: _errActual,
            ),
            const SizedBox(height: 16),
            AuthCampoPassword(
              label: context.t('pass.nueva'),
              controller: _nueva,
              errorText: _errNueva,
            ),
            if (_errNueva == null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 2),
                child: Text(context.t('pass.regla'),
                    style: TextStyle(fontSize: 11, color: context.aura.textoSecundario)),
              ),
            const SizedBox(height: 16),
            AuthCampoPassword(
              label: context.t('pass.confirmar'),
              controller: _confirmar,
              errorText: _errConfirmar,
              onSubmitted: (_) {
                if (_completo) _guardar();
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: AuthBoton(
            texto: context.t('pass.guardar'),
            cargando: _cargando,
            onPressed: _completo ? _guardar : null,
          ),
        ),
      ),
    );
  }
}
