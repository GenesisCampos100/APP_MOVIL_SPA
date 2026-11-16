import '../../../shared/widgets/prefijo_telefono.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/aura_colores.dart';
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
      setState(() => _error = context.t('tel.err_10'));
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
            titulo: context.t('tel.ok_titulo'),
            mensaje: context.t('tel.ok_msg'),
            textoBoton: context.t('comun.continuar'),
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
        _error = context.t('tel.err_guardar');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('tel.titulo'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                context.t('tel.sub'),
                style: TextStyle(fontSize: 12, color: context.aura.textoSecundario),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PrefijoTelefono(),
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
                      decoration: decoracionCampo(
                        context,
                        errorText: _error,
                        relleno: PrefijoTelefono.relleno,
                        sinContador: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              AuthBoton(texto: context.t('comun.continuar'), cargando: _cargando, onPressed: _continuar),
            ],
          ),
        ),
      ),
    );
  }
}
