
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/repositories/auth_repository.dart';
import '../widgets/auth_widgets.dart';

class AuthVerifyScreen extends StatefulWidget {
  final String correo;

  // Personalización opcional para otros procesos de verificación.
  final String titulo;
  final String? subtitulo;

  // Permite utilizar otro endpoint sin modificar el diseño.
  final Future<bool> Function(String codigo)? onVerificar;

  // Acción que se ejecuta cuando la verificación es exitosa.
  final VoidCallback? onVerificacionExitosa;

  const AuthVerifyScreen({
    super.key,
    required this.correo,
    this.titulo = 'Verifica tu cuenta',
    this.subtitulo,
    this.onVerificar,
    this.onVerificacionExitosa,
  });

  @override
  State<AuthVerifyScreen> createState() => _AuthVerifyScreenState();
}

class _AuthVerifyScreenState extends State<AuthVerifyScreen> {
  final _repo = AuthRepository();
  final _codigo = TextEditingController();
  final _foco = FocusNode();

  String? _error;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _codigo.addListener(() {
      if (mounted) setState(() => _error = null);
    });
    _foco.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
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
      bool correcto;

      if (widget.onVerificar != null) {
        // Verificación personalizada, por ejemplo, cambio de correo.
        correcto = await widget.onVerificar!(_codigo.text.trim());
      } else {
        // Verificación original del registro.
        final usuario = await _repo.verificarCodigo(
          widget.correo,
          _codigo.text.trim(),
        );

        correcto = usuario != null;
      }

      if (!mounted) return;

      if (!correcto) {
        setState(() {
          _error = 'Código incorrecto o inválido';
        });
        return;
      }

      if (widget.onVerificacionExitosa != null) {
        widget.onVerificacionExitosa!();
      } else {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.authExito,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  Widget _casillas() {
    final texto = _codigo.text;

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
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _error != null
                        ? Colors.red
                        : (lleno || activa ? Colors.black : Colors.black38),
                    width: activa ? 2 : 1,
                  ),
                ),
                child: Text(
                  lleno ? texto[i] : '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
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
    return AuthPagina(
      titulo: widget.titulo,
      subtitulo: widget.subtitulo ??
          'Te enviamos un código a tu correo, ingrésalo aquí\n${widget.correo}',
      hijos: [
        const SizedBox(height: 10),
        _casillas(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
        const SizedBox(height: 24),
        AuthBoton(
          texto: 'Confirmar',
          cargando: _cargando,
          onPressed: _codigo.text.length == 6 ? _confirmar : null,
        ),
        Center(
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('La opción de reenviar código está pendiente'),
                ),
              );
            },
            child: const Text(
              'Reenviar código',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
