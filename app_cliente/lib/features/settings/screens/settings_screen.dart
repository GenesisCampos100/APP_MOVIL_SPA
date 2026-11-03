import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/auth_state.dart';
import '../ajustes_state.dart';
import 'change_password_screen.dart';

const Color _rojo = Color(0xFFE5174D);
const Color _borde = Color(0xFFE3E3E3);

/// Abre la pantalla de Configuración (desde el Perfil).
void abrirConfiguracion(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SettingsScreen()),
  );
}

/// Abre el selector de idioma (fila "Español" del Perfil).
void abrirIdioma(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Idioma', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language),
              title: const Text('Español'),
              trailing: const Icon(Icons.check, color: AppColors.rosaFuerte),
              onTap: () => Navigator.pop(ctx),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: false,
              leading: Icon(Icons.language, color: Colors.black26),
              title: Text('English', style: TextStyle(color: Colors.black38)),
              trailing: Text('Próximamente',
                  style: TextStyle(fontSize: 11, color: AppColors.gris)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Configuración: preferencias de notificaciones, cuenta, legal y
/// eliminar cuenta.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _proximamente(BuildContext context, String que) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$que: próximamente')),
      );

  @override
  Widget build(BuildContext context) {
    final correo = AuthState.instance.usuario?.correo ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: ListenableBuilder(
        listenable: AjustesState.instance,
        builder: (context, _) {
          final ajustes = AjustesState.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _Seccion(
                titulo: 'Notificaciones',
                filas: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    secondary: const Icon(Icons.alarm, color: Colors.black87),
                    title: const Text('Recordatorios de citas', style: TextStyle(fontSize: 15)),
                    subtitle: const Text('Avisos para confirmar y recordar tus citas',
                        style: TextStyle(fontSize: 12, color: AppColors.gris)),
                    value: ajustes.recordatorios,
                    onChanged: ajustes.setRecordatorios,
                  ),
                ],
              ),
              _Seccion(
                titulo: 'Cuenta',
                filas: [
                  _Fila(
                    icono: Icons.mail_outline,
                    texto: 'Correo',
                    valor: correo,
                  ),
                  _Fila(
                    icono: Icons.lock_outline,
                    texto: 'Cambiar contraseña',
                    onTap: () => abrirCambiarContrasena(context),
                  ),
                ],
              ),
              _Seccion(
                titulo: 'Legal',
                filas: [
                  _Fila(
                    icono: Icons.privacy_tip_outlined,
                    texto: 'Política de privacidad',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _TextoScreen(titulo: 'Política de privacidad'),
                      ),
                    ),
                  ),
                  _Fila(
                    icono: Icons.description_outlined,
                    texto: 'Términos y condiciones',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _TextoScreen(titulo: 'Términos y condiciones'),
                      ),
                    ),
                  ),
                ],
              ),
              _Seccion(
                titulo: '',
                filas: [
                  _Fila(
                    icono: Icons.delete_outline,
                    texto: 'Eliminar cuenta',
                    color: _rojo,
                    flecha: false,
                    onTap: () => _confirmarEliminar(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Aura Spa · versión 1.0.0',
                    style: TextStyle(fontSize: 11, color: AppColors.gris)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¿Eliminar tu cuenta?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Esta acción no se puede deshacer.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.gris),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: _rojo,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Eliminar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar != true || !context.mounted) return;

    // DEMOSTRACIÓN: solo cierra la sesión. Con la API sería DELETE /cuenta,
    // que desactiva la cuenta (usuarios.estado = false).
    final messenger = ScaffoldMessenger.of(context);
    AuthState.instance.cerrarSesion();
    Navigator.popUntil(context, ModalRoute.withName(AppRoutes.shell));
    messenger.showSnackBar(const SnackBar(content: Text('Tu cuenta fue eliminada')));
  }
}

/// Título gris + tarjeta con borde que agrupa varias filas.
class _Seccion extends StatelessWidget {
  final String titulo;
  final List<Widget> filas;
  const _Seccion({required this.titulo, required this.filas});

  @override
  Widget build(BuildContext context) {
    final contenido = <Widget>[];
    for (var i = 0; i < filas.length; i++) {
      if (i > 0) contenido.add(const Divider(height: 1, color: Color(0xFFEDEDED)));
      contenido.add(filas[i]);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titulo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
              child: Text(titulo,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gris)),
            ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _borde),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: contenido),
          ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String texto;
  final String? valor; // texto gris a la derecha (sin flecha)
  final VoidCallback? onTap;
  final Color? color;
  final bool flecha;

  const _Fila({
    required this.icono,
    required this.texto,
    this.valor,
    this.onTap,
    this.color,
    this.flecha = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icono, size: 22, color: color ?? Colors.black87),
            const SizedBox(width: 18),
            Text(
              texto,
              style: TextStyle(
                fontSize: 15,
                color: color ?? const Color(0xFF2B2B2B),
                fontWeight: color != null ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (valor != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  valor!,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.gris),
                ),
              ),
            ] else
              const Spacer(),
            if (flecha && valor == null)
              const Icon(Icons.chevron_right, size: 20, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}

/// Pantalla de texto simple para Política de privacidad y Términos.
class _TextoScreen extends StatelessWidget {
  final String titulo;
  const _TextoScreen({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Aquí se mostrará el texto completo de "$titulo" de Aura Spa. '
            'Pendiente de redactar por el equipo.',
            style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.gris),
          ),
        ],
      ),
    );
  }
}
