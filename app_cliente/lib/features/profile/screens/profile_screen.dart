import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/usuario_sesion.dart';
import '../../appointments/screens/appointments_screen.dart';
import '../../auth/auth_state.dart';
import '../../auth/screens/auth_email_screen.dart';

// Colores del mockup del perfil
const Color _bordeTarjeta = Color(0xFFE3E3E3);
const Color _textoItem = Color(0xFF2B2B2B);
const Color _rojoSesion = Color(0xFFD98C97);

/// Sin sesión: muestra el inicio de sesión. Con sesión: muestra el perfil.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthState.instance,
      builder: (context, _) {
        final u = AuthState.instance.usuario;
        if (u == null) return const AuthEmailScreen(embebido: true);
        return _PerfilConSesion(usuario: u);
      },
    );
  }
}

class _PerfilConSesion extends StatelessWidget {
  final UsuarioSesion usuario;
  const _PerfilConSesion({required this.usuario});

  @override
  Widget build(BuildContext context) {
    void proximamente(String que) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$que: próximamente')),
    );

    // Ventana de confirmación antes de cerrar la sesión.
    Future<void> confirmarCerrarSesion() async {
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
                  '¿Cerrar sesión?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
                          backgroundColor: _rojoSesion,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cerrar sesión'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (confirmar == true) AuthState.instance.cerrarSesion();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Center(child: _Avatar(usuario: usuario)),
            const SizedBox(height: 14),
            Center(
              child: Text(
                usuario.nombreCompleto,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 28),
            _Tarjeta(children: [
              _FilaMenu(
                icono: Icons.person_outline,
                texto: 'Mi perfil',
                onTap: () => proximamente('Mi perfil'),
              ),
              _FilaMenu(
                icono: Icons.favorite_border,
                texto: 'Favoritos',
                onTap: () => proximamente('Favoritos'),
              ),
              _FilaMenu(
                icono: Icons.calendar_today_outlined,
                texto: 'Mis citas',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppointmentsScreen(conAtras: true)),
                ),
              ),
              _FilaMenu(
                icono: Icons.notifications_none,
                texto: 'Notificaciones',
                onTap: () => proximamente('Notificaciones'),
              ),
            ]),
            const SizedBox(height: 14),
            _Tarjeta(children: [
              _FilaMenu(
                icono: Icons.settings_outlined,
                texto: 'Configuración',
                onTap: () => proximamente('Configuración'),
              ),
              _FilaMenu(
                icono: Icons.language,
                texto: 'Español',
                onTap: () => proximamente('Idioma'),
              ),
            ]),
            const SizedBox(height: 14),
            _Tarjeta(children: [
              _FilaMenu(
                icono: Icons.logout,
                texto: 'Cerrar Sesion',
                color: _rojoSesion,
                flecha: false,
                onTap: confirmarCerrarSesion,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Foto de perfil circular. Si no hay foto, muestra la inicial del nombre.
class _Avatar extends StatelessWidget {
  final UsuarioSesion usuario;
  const _Avatar({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final foto = usuario.foto;
    return CircleAvatar(
      radius: 56,
      backgroundColor: AppColors.rosa,
      backgroundImage: foto != null ? NetworkImage(foto) : null,
      child: foto == null
          ? Text(
        usuario.inicial,
        style: const TextStyle(
          fontSize: 44,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      )
          : null,
    );
  }
}

/// Tarjeta con borde suave y esquinas redondeadas.
class _Tarjeta extends StatelessWidget {
  final List<Widget> children;
  const _Tarjeta({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _bordeTarjeta),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _FilaMenu extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;
  final Color? color;
  final bool flecha;

  const _FilaMenu({
    required this.icono,
    required this.texto,
    required this.onTap,
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
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  fontSize: 15,
                  color: color ?? _textoItem,
                  fontWeight: color != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (flecha) const Icon(Icons.chevron_right, size: 20, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}
