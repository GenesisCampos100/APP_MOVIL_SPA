import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/notificacion.dart';
import '../../../data/repositories/notificaciones_repository.dart';
import '../../auth/auth_flow.dart';
import '../../auth/auth_state.dart';
import '../../shell/shell_controller.dart';

const Color _rojo = Color(0xFFE5174D);
const Color _verde = Color(0xFF4CAF50);

/// Abre las notificaciones desde cualquier parte (campana del Inicio o Perfil).
/// Si no hay sesión, primero pide iniciar sesión.
Future<void> abrirNotificaciones(BuildContext context) async {
  if (!AuthState.instance.isLoggedIn) {
    final ok = await AuthFlow.iniciar(context);
    if (!ok || !context.mounted) return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
  );
}

/// Lista de notificaciones del ciclo de una cita:
/// registrada -> confirma tu cita (24 h antes) -> confirmada / cancelada
/// -> ¿cómo estuvo tu servicio?
///
///  - Deslizar una hacia un lado la elimina (con "Deshacer").
///  - El ícono de basura limpia todas (con confirmación).
///  - "Confirma tu cita" no se puede borrar hasta que se confirme.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = NotificacionesRepository.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final items = repo.items;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notificaciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            actions: [
              if (items.isNotEmpty)
                IconButton(
                  tooltip: 'Limpiar todo',
                  onPressed: () => _confirmarLimpiar(context),
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
              const SizedBox(width: 4),
            ],
          ),
          body: items.isEmpty
              ? const _Vacio()
              : _Lista(items: items, noLeidas: repo.noLeidas),
        );
      },
    );
  }

  Future<void> _confirmarLimpiar(BuildContext context) async {
    final hayPendientes = NotificacionesRepository.instance.hayPendientes;
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
                '¿Limpiar todas las notificaciones?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              if (hayPendientes) ...[
                const SizedBox(height: 8),
                const Text(
                  'Las que requieren tu confirmación se conservarán.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.gris),
                ),
              ],
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
                      child: const Text('Limpiar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmar == true) NotificacionesRepository.instance.limpiarTodo();
  }
}

class _Lista extends StatelessWidget {
  final List<Notificacion> items;
  final int noLeidas;
  const _Lista({required this.items, required this.noLeidas});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (noLeidas > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
            child: Row(
              children: [
                Text('$noLeidas sin leer',
                    style: const TextStyle(fontSize: 12, color: AppColors.gris)),
                const Spacer(),
                TextButton(
                  onPressed: NotificacionesRepository.instance.marcarTodasLeidas,
                  child: const Text('Marcar todas como leídas',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        for (final n in items) _Tarjeta(notificacion: n),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final Notificacion notificacion;
  const _Tarjeta({required this.notificacion});

  static IconData _icono(String tipo) {
    switch (tipo) {
      case Notificacion.citaCreada:
        return Icons.event_available;
      case Notificacion.confirmarCita:
        return Icons.alarm;
      case Notificacion.citaConfirmada:
        return Icons.check_circle_outline;
      case Notificacion.citaCancelada:
        return Icons.event_busy_outlined;
      case Notificacion.resena:
        return Icons.star_outline_rounded;
      default:
        return Icons.notifications_none;
    }
  }

  static Color _color(String tipo) {
    switch (tipo) {
      case Notificacion.citaConfirmada:
        return _verde;
      case Notificacion.citaCancelada:
        return _rojo;
      default:
        return AppColors.rosaFuerte;
    }
  }

  static String _tiempo(DateTime fecha) {
    final d = DateTime.now().difference(fecha);
    if (d.inMinutes < 1) return 'ahora';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    if (d.inDays == 1) return 'ayer';
    if (d.inDays < 30) return 'hace ${d.inDays} días';
    final meses = d.inDays ~/ 30;
    return meses == 1 ? 'hace 1 mes' : 'hace $meses meses';
  }

  Widget _fondoBorrar(AlignmentGeometry alineacion) => Container(
        color: _rojo,
        alignment: alineacion,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      );

  void _abrir(BuildContext context) {
    final n = notificacion;
    NotificacionesRepository.instance.marcarLeida(n.id);
    if (n.idCita != null) {
      // Las notificaciones de citas llevan a la pestaña "Citas".
      ShellController.irA(2);
      Navigator.popUntil(context, ModalRoute.withName(AppRoutes.shell));
    }
  }

  void _confirmar(BuildContext context) {
    NotificacionesRepository.instance.confirmarAsistencia(notificacion.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Cita confirmada')));
  }

  @override
  Widget build(BuildContext context) {
    final n = notificacion;
    final repo = NotificacionesRepository.instance;
    final color = _color(n.tipo);
    final pendiente = n.requiereAccion;

    return Dismissible(
      key: ValueKey(n.id),
      // Una "Confirma tu cita" pendiente no se puede borrar deslizando.
      direction: pendiente ? DismissDirection.none : DismissDirection.horizontal,
      background: _fondoBorrar(Alignment.centerLeft),
      secondaryBackground: _fondoBorrar(Alignment.centerRight),
      onDismissed: (_) {
        repo.eliminar(n.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Notificación eliminada'),
              action: SnackBarAction(
                label: 'Deshacer',
                onPressed: () => repo.restaurar(n),
              ),
            ),
          );
      },
      child: InkWell(
        onTap: () => _abrir(context),
        child: Container(
          color: n.leida ? Colors.white : AppColors.rosaSuave.withValues(alpha: 0.45),
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icono(n.tipo), size: 22, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.titulo,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: n.leida ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      n.mensaje,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.3, color: AppColors.gris),
                    ),
                    const SizedBox(height: 6),
                    Text(_tiempo(n.fechaEnvio),
                        style: const TextStyle(fontSize: 11, color: AppColors.gris)),
                    if (pendiente) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 36,
                        child: FilledButton(
                          onPressed: () => _confirmar(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Confirmar cita', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ] else if (n.tipo == Notificacion.confirmarCita && n.atendida) ...[
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.check_circle, size: 14, color: _verde),
                          SizedBox(width: 4),
                          Text('Cita confirmada',
                              style: TextStyle(fontSize: 11, color: _verde)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!n.leida)
                Container(
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.rosaFuerte,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.rosaSuave,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none, size: 56, color: AppColors.rosaFuerte),
            ),
            const SizedBox(height: 24),
            const Text('Sin notificaciones',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            const Text(
              'Aquí aparecerán los avisos de tus citas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.gris),
            ),
          ],
        ),
      ),
    );
  }
}
