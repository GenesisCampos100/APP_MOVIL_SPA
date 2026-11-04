import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../shared/widgets/pantalla_exito.dart';
import '../../auth/auth_state.dart';
import '../../auth/widgets/auth_widgets.dart';
import '../reserva_borrador.dart';

/// "Ingresa tu número de teléfono": aparece una sola vez, cuando la persona
/// pasa de ser usuario a ser cliente al reservar. Se guarda como "+52" y
/// 10 dígitos (cabe en clientes.telefono VARCHAR(15)).
class TelefonoScreen extends StatefulWidget {
  final ReservaBorrador borrador;
  const TelefonoScreen({super.key, required this.borrador});

  @override
  State<TelefonoScreen> createState() => _TelefonoScreenState();
}

class _TelefonoScreenState extends State<TelefonoScreen> {
  final _repo = AuthRepository();
  final _ctrl = TextEditingController();
  String? _error;
  bool _cargando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    final numero = _ctrl.text.trim();
    if (numero.length != 10) {
      setState(() => _error = 'Ingresa un número de 10 dígitos');
      return;
    }
    setState(() {
      _error = null;
      _cargando = true;
    });
    final telefono = '+52$numero';
    try {
      final usuario = AuthState.instance.usuario;
      if (usuario != null) await _repo.guardarTelefono(usuario.correo, telefono);
      AuthState.instance.actualizarTelefono(telefono);
      if (!mounted) return;
      final borrador = widget.borrador;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaExito(
            titulo: 'Teléfono registrado',
            mensaje: 'Gracias, ya tenemos tu número de contacto.\nContinúa con tu reserva.',
            textoBoton: 'Continuar',
            onContinuar: (ctx) => Navigator.pushReplacementNamed(
              ctx,
              AppRoutes.especialista,
              arguments: borrador,
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo guardar. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder borde(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c),
        );

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingresa tu número de teléfono',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Necesitamos completar tu información para continuar.',
                style: TextStyle(fontSize: 12, color: AppColors.gris),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black54),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('+52', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      decoration: InputDecoration(
                        counterText: '',
                        isDense: true,
                        errorText: _error,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        border: borde(Colors.black54),
                        enabledBorder: borde(Colors.black54),
                        focusedBorder: borde(Colors.black),
                        errorBorder: borde(Colors.red),
                        focusedErrorBorder: borde(Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              AuthBoton(texto: 'Continuar', cargando: _cargando, onPressed: _continuar),
            ],
          ),
        ),
      ),
    );
  }
}
