import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/repositories/auth_repository.dart';
import '../auth_state.dart';
import '../widgets/auth_widgets.dart';

/// "Verifica tu cuenta": código de 6 dígitos enviado al correo.
/// Un solo campo invisible recibe el teclado y se dibujan 6 casillas.
class AuthVerifyScreen extends StatefulWidget {
  final String correo;
  const AuthVerifyScreen({super.key, required this.correo});

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
    _codigo.addListener(() => setState(() => _error = null));
    _foco.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _codigo.dispose();
    _foco.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    setState(() => _cargando = true);
    try {
      final usuario = await _repo.verificarCodigo(widget.correo, _codigo.text);
      if (!mounted) return;
      if (usuario == null) {
        setState(() {
          _cargando = false;
          _error = 'Código incorrecto';
        });
        return;
      }
      AuthState.instance.iniciarSesion(usuario);
      Navigator.pushReplacementNamed(context, AppRoutes.authExito);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo verificar. Intenta de nuevo.';
      });
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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
              );
            }),
          ),
          // Campo real, invisible, que recibe lo que se escribe.
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
    return AuthPagina(
      titulo: 'Verifica tu cuenta',
      subtitulo: 'Te enviamos un código a tu correo, ingrésalo aquí\n${widget.correo}',
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
          texto: 'Confirmar',
          cargando: _cargando,
          onPressed: _codigo.text.length == 6 ? _confirmar : null,
        ),
        Center(
          child: TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Código reenviado')),
            ),
            child: const Text('Reenviar código', style: TextStyle(fontSize: 12)),
          ),
        ),
        if (kDebugMode)
          const Center(
            child: Text(
              'Modo prueba: el código es ${AuthRepository.codigoPrueba}',
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ),
      ],
    );
  }
}
