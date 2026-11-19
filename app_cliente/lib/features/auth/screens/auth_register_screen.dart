import 'package:flutter/material.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../core/utils/errores.dart';
import '../../../data/repositories/auth_repository.dart';
import '../widgets/auth_widgets.dart';

/// "Únete a Aura Spa": formulario de registro. El correo viene de la
/// pantalla anterior; si hay un error, se corrige regresando.
class AuthRegisterScreen extends StatefulWidget {
  final String correo;
  const AuthRegisterScreen({super.key, required this.correo});

  @override
  State<AuthRegisterScreen> createState() => _AuthRegisterScreenState();
}

class _AuthRegisterScreenState extends State<AuthRegisterScreen> {
  final _repo = AuthRepository();
  final _nombre = TextEditingController();
  final _apellidoP = TextEditingController(); // clientes.apellido_p
  final _apellidoM = TextEditingController(); // clientes.apellido_m
  final _password = TextEditingController();
  late final _correoCtrl = TextEditingController(text: widget.correo);

  bool _acepto = false;
  bool _cargando = false;
  String? _errNombre, _errApellidoP, _errPassword, _errTerminos, _errGeneral;

  @override
  void dispose() {
    _nombre.dispose();
    _apellidoP.dispose();
    _apellidoM.dispose();
    _password.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  bool _validar() {
    final pass = _password.text;
    final passValida = pass.length >= 8 &&
        RegExp(r'[A-Za-z]').hasMatch(pass) &&
        RegExp(r'\d').hasMatch(pass);
    setState(() {
      _errNombre = _nombre.text.trim().isEmpty ? context.t('auth.err_nombre') : null;
      // El apellido materno es opcional.
      _errApellidoP = _apellidoP.text.trim().isEmpty ? context.t('auth.err_apellido') : null;
      _errPassword = passValida ? null : context.t('auth.err_pass_regla');
      _errTerminos = _acepto ? null : context.t('auth.err_terminos');
      _errGeneral = null;
    });
    return _errNombre == null &&
        _errApellidoP == null &&
        _errPassword == null &&
        _errTerminos == null;
  }

  Future<void> _crearCuenta() async {
  if (_cargando || !_validar()) return;

  setState(() => _cargando = true);

  try {
    final requiereVerificacion = await _repo.registrar(
      correo: widget.correo,
      nombre: _nombre.text.trim(),
      apellido: _apellidoP.text.trim(),
      apellidoMaterno: _apellidoM.text.trim().isEmpty
          ? null
          : _apellidoM.text.trim(),
      password: _password.text,
    );

    if (!mounted) return;

    if (!requiereVerificacion) {
      setState(() {
        _errGeneral = context.t('auth.err_envio_codigo');
      });
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.authVerificar,
      arguments: widget.correo,
    );
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _errGeneral = textoError(context, e);
    });
  } finally {
    if (mounted) {
      setState(() => _cargando = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return AuthPagina(
      titulo: context.t('auth.reg_titulo'),
      subtitulo: context.t('auth.reg_sub'),
      hijos: [
        AuthCampo(label: context.t('auth.nombre'), controller: _nombre, errorText: _errNombre,
            textInputAction: TextInputAction.next),
        const SizedBox(height: 14),
        // Los dos apellidos en la misma línea
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AuthCampo(
                label: context.t('auth.apellido_p'),
                controller: _apellidoP,
                errorText: _errApellidoP,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AuthCampo(
                label: context.t('auth.apellido_m'),
                controller: _apellidoM,
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AuthCampo(label: context.t('auth.correo'), controller: _correoCtrl, enabled: false),
        const SizedBox(height: 14),
        AuthCampoPassword(controller: _password, errorText: _errPassword),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _acepto,
                activeColor: context.aura.boton,
                checkColor: context.aura.textoBoton,
                side: BorderSide(color: context.aura.bordeCampo, width: 1.5),
                onChanged: (v) => setState(() => _acepto = v ?? false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.t('auth.terminos'),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        if (_errTerminos != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_errTerminos!, style: const TextStyle(fontSize: 12, color: Colors.red)),
          ),
        if (_errGeneral != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_errGeneral!, style: const TextStyle(fontSize: 12, color: Colors.red)),
          ),
        const SizedBox(height: 20),
        AuthBoton(texto: context.t('auth.crear'), cargando: _cargando, onPressed: _crearCuenta),
      ],
    );
  }
}
