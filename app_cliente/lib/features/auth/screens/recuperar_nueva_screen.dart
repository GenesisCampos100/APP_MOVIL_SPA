import 'package:flutter/material.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../data/repositories/recuperacion_repository.dart';
import '../../../shared/widgets/pantalla_exito.dart';
import '../widgets/auth_widgets.dart';

/// Paso 3: escribir la nueva contraseña (el código ya fue validado).
class RecuperarNuevaScreen extends StatefulWidget {
  final String correo;
  final String token;
  const RecuperarNuevaScreen({super.key, required this.correo, required this.token});

  @override
  State<RecuperarNuevaScreen> createState() => _RecuperarNuevaScreenState();
}

class _RecuperarNuevaScreenState extends State<RecuperarNuevaScreen> {
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();

  String? _errNueva, _errConfirmar;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_nueva, _confirmar]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  bool get _completo => _nueva.text.isNotEmpty && _confirmar.text.isNotEmpty;

  bool _validar() {
    final n = _nueva.text;
    final cumple = n.length >= 8 &&
        RegExp(r'[A-Za-z]').hasMatch(n) &&
        RegExp(r'\d').hasMatch(n);
    setState(() {
      _errNueva = cumple ? null : context.t('rec.err_regla');
      _errConfirmar =
          _confirmar.text != n ? context.t('rec.err_no_coincide') : null;
    });
    return _errNueva == null && _errConfirmar == null;
  }

  Future<void> _guardar() async {
    if (_cargando || !_validar()) return;
    setState(() => _cargando = true);
    try {
      await RecuperacionRepository.instance.restablecer(
        correo: widget.correo,
        token: widget.token,
        nuevaContrasena: _nueva.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaExito(
            titulo: context.t('rec.ok_titulo'),
            mensaje: context.t('rec.ok_msg'),
            textoBoton: context.t('rec.ok_boton'),
            // Regresa a la pantalla de contraseña del login.
            onContinuar: (ctx) => Navigator.pop(ctx),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.t('rec.err_generico'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPagina(
      titulo: context.t('rec.nueva_titulo'),
      subtitulo: context.t('rec.nueva_sub'),
      hijos: [
        AuthCampoPassword(
          label: context.t('rec.nueva'),
          controller: _nueva,
          errorText: _errNueva,
        ),
        if (_errNueva == null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              context.t('rec.regla'),
              style: TextStyle(fontSize: 11, color: context.aura.textoSecundario),
            ),
          ),
        const SizedBox(height: 16),
        AuthCampoPassword(
          label: context.t('rec.confirmar_nueva'),
          controller: _confirmar,
          errorText: _errConfirmar,
          onSubmitted: (_) {
            if (_completo) _guardar();
          },
        ),
        const SizedBox(height: 24),
        AuthBoton(
          texto: context.t('rec.guardar'),
          cargando: _cargando,
          onPressed: _completo ? _guardar : null,
        ),
      ],
    );
  }
}
