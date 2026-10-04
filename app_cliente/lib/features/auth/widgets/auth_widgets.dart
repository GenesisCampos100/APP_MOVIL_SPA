import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

InputDecoration _decoracion({
  String? hint,
  String? errorText,
  Widget? suffix,
  bool deshabilitado = false,
}) {
  OutlineInputBorder borde(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c),
      );
  return InputDecoration(
    hintText: hint,
    errorText: errorText,
    suffixIcon: suffix,
    isDense: true,
    filled: deshabilitado,
    fillColor: const Color(0xFFE6E6E6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    border: borde(Colors.black54),
    enabledBorder: borde(Colors.black54),
    disabledBorder: borde(Colors.black26),
    focusedBorder: borde(Colors.black),
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
                Text(subtitulo!, style: const TextStyle(fontSize: 12, color: AppColors.gris)),
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
          decoration: _decoracion(errorText: errorText, deshabilitado: !enabled),
        ),
      ],
    );
  }
}

/// Campo de contraseña con el ojito para mostrar u ocultar.
class AuthCampoPassword extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  const AuthCampoPassword({
    super.key,
    this.label = 'Contraseña',
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
        Text(widget.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: _oculto,
          onSubmitted: widget.onSubmitted,
          decoration: _decoracion(
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
    return FilledButton(
      onPressed: cargando ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.black,
        disabledBackgroundColor: Colors.black26,
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: cargando
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(texto),
    );
  }
}
