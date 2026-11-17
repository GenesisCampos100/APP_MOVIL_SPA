import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../data/repositories/recuperacion_repository.dart';
import '../widgets/auth_widgets.dart';
import 'recuperar_nueva_screen.dart';

bool _abriendo = false;

/// Se llama desde "¿Olvidaste tu contraseña?": pide el código y abre la
/// pantalla donde se escribe.
Future<void> abrirRecuperarContrasena(BuildContext context, String correo) async {
  if (_abriendo) return;
  _abriendo = true;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final mensajeError = context.t('rec.err_generico');
  try {
    await RecuperacionRepository.instance.solicitar(correo);
    navigator.push(
      MaterialPageRoute(builder: (_) => RecuperarCodigoScreen(correo: correo)),
    );
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(mensajeError)));
  } finally {
    _abriendo = false;
  }
}

/// Paso 2: código de 6 dígitos que llegó al correo.
class RecuperarCodigoScreen extends StatefulWidget {
  final String correo;
  const RecuperarCodigoScreen({super.key, required this.correo});

  @override
  State<RecuperarCodigoScreen> createState() => _RecuperarCodigoScreenState();
}

class _RecuperarCodigoScreenState extends State<RecuperarCodigoScreen> {
  static const _segundosReenvio = 30;

  final _repo = RecuperacionRepository.instance;
  final _codigo = TextEditingController();
  final _foco = FocusNode();

  String? _error;
  bool _cargando = false;
  int _restantes = _segundosReenvio;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _codigo.addListener(() {
      if (mounted) setState(() => _error = null);
    });
    _foco.addListener(() {
      if (mounted) setState(() {});
    });
    _iniciarCuenta();
  }

  void _iniciarCuenta() {
    _timer?.cancel();
    setState(() => _restantes = _segundosReenvio);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _restantes--);
      if (_restantes <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codigo.dispose();
    _foco.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_cargando || _codigo.text.length != 6) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final token = await _repo.verificar(widget.correo, _codigo.text.trim());
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecuperarNuevaScreen(correo: widget.correo, token: token),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = context.t('rec.err_codigo');
      });
    }
  }

  Future<void> _reenviar() async {
    if (_restantes > 0) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = context.t('rec.reenviado');
    final fallo = context.t('rec.err_generico');
    try {
      await _repo.solicitar(widget.correo);
      if (!mounted) return;
      _codigo.clear();
      _iniciarCuenta();
      messenger.showSnackBar(SnackBar(content: Text(ok)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(fallo)));
    }
  }

  Widget _casillas() {
    final texto = _codigo.text;
    final c = context.aura;
    return GestureDetector(
      onTap: () => _foco.requestFocus(),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              final lleno = i < texto.length;
              final activa = _foco.hasFocus && i == texto.length;
              return Container(
                width: 44,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.superficie,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _error != null
                        ? Colors.red
                        : (lleno || activa ? c.texto : c.borde),
                    width: activa ? 2 : 1,
                  ),
                ),
                child: Text(
                  lleno ? texto[i] : '',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
              );
            }),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _codigo,
                focusNode: _foco,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return AuthPagina(
      titulo: context.t('rec.titulo'),
      subtitulo: context.t('rec.sub', {'correo': widget.correo}),
      hijos: [
        const SizedBox(height: 10),
        _casillas(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
          ),
        const SizedBox(height: 24),
        AuthBoton(
          texto: context.t('rec.confirmar'),
          cargando: _cargando,
          onPressed: _codigo.text.length == 6 ? _confirmar : null,
        ),
        Center(
          child: TextButton(
            onPressed: _restantes > 0 ? null : _reenviar,
            child: Text(
              _restantes > 0
                  ? context.t('rec.reenviar_en', {'s': '$_restantes'})
                  : context.t('rec.reenviar'),
              style: TextStyle(
                fontSize: 12,
                color: _restantes > 0 ? c.textoSecundario : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
