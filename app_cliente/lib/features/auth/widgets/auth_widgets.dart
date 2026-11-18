import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../core/i18n/textos.dart';

/// Decoración de los campos de texto de la app (cambia con el tema).
/// [relleno] y [sinContador] sirven para el campo de teléfono.
InputDecoration decoracionCampo(
  BuildContext context, {
  String? hint,
  String? errorText,
  Widget? suffix,
  bool deshabilitado = false,
  EdgeInsetsGeometry relleno = const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
  bool sinContador = false,
}) {
  final c = context.aura;
  OutlineInputBorder borde(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: c.textoSecundario),
    errorText: errorText,
    suffixIcon: suffix,
    counterText: sinContador ? '' : null,
    isDense: true,
    filled: deshabilitado,
    fillColor: c.campoBloqueado,
    contentPadding: relleno,
    border: borde(context.bordeCampo),
    enabledBorder: borde(context.bordeCampo),
    disabledBorder: borde(c.borde),
    focusedBorder: borde(c.texto),
    errorBorder: borde(Colors.red),
    focusedErrorBorder: borde(Colors.red),
  );
}

/// Estructura común de las pantallas de acceso: título centrado,
/// subtítulo y contenido con scroll.
class AuthPagina extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget> hijos;
  final bool conAtras;

  const AuthPagina({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.hijos,
    this.conAtras = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: conAtras ? AppBar() : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, conAtras ? 8 : 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 28),
              if (subtitulo != null) ...[
                Text(subtitulo!, style: TextStyle(fontSize: 12, color: context.aura.textoSecundario)),
                const SizedBox(height: 14),
              ],
              ...hijos,
            ],
          ),
        ),
      ),
    );
  }
}

class AuthCampo extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? errorText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AuthCampo({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: decoracionCampo(context, errorText: errorText, deshabilitado: !enabled),
        ),
      ],
    );
  }
}

/// Campo de contraseña con el ojito para mostrar u ocultar.
class AuthCampoPassword extends StatefulWidget {
  final String? label; // si es null, se usa "Contraseña" en el idioma elegido
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  const AuthCampoPassword({
    super.key,
    this.label,
    required this.controller,
    this.errorText,
    this.onSubmitted,
  });

  @override
  State<AuthCampoPassword> createState() => _AuthCampoPasswordState();
}

class _AuthCampoPasswordState extends State<AuthCampoPassword> {
  bool _oculto = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label ?? context.t('auth.password'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: _oculto,
          onSubmitted: widget.onSubmitted,
          decoration: decoracionCampo(
            context,
            errorText: widget.errorText,
            suffix: IconButton(
              icon: Icon(_oculto ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
              onPressed: () => setState(() => _oculto = !_oculto),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthBoton extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final bool cargando;

  const AuthBoton({super.key, required this.texto, this.onPressed, this.cargando = false});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return FilledButton(
      onPressed: cargando ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: c.boton,
        foregroundColor: c.textoBoton,
        disabledBackgroundColor: c.boton.withValues(alpha: 0.26),
        disabledForegroundColor: c.textoBoton,
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: cargando
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: c.textoBoton),
            )
          : Text(texto),
    );
  }
}
