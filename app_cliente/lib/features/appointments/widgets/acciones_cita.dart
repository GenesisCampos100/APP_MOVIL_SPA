import 'package:flutter/material.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../core/utils/errores.dart';
import '../../../core/utils/formato.dart';
import '../../../data/models/cita.dart';
import '../../../data/repositories/citas_repository.dart';
import '../../../data/models/servicio.dart';
import '../../booking/screens/agendar_cita_screen.dart';

const Color _rojo = Color(0xFFE5174D);

/// Hora de inicio de la cita como fecha y hora completas.
DateTime inicioDeCita(Cita c) {
  final p = c.horaInicio.split(':');
  return DateTime(c.fecha.year, c.fecha.month, c.fecha.day, int.parse(p[0]), int.parse(p[1]));
}

/// Solo se puede cancelar o reagendar con más de 24 horas de anticipación.
bool citaModificable(Cita c) =>
    inicioDeCita(c).difference(DateTime.now()) > const Duration(hours: 24);

/// Botones "Reagendar" y "Cancelar" de una cita confirmada.
/// Si faltan 24 horas o menos, se ven desactivados (gris pálido) y aparece
/// una nota que explica por qué. [onCambio] se llama cuando la cita cambia
/// (por ejemplo, al cancelarla) para que la lista se vuelva a cargar.
class AccionesCita extends StatelessWidget {
  final Cita cita;
  final VoidCallback? onCambio;
  const AccionesCita({super.key, required this.cita, this.onCambio});

  Future<void> _reagendar(BuildContext context) async {
    final servicio = Servicio(
      id: cita.idServicio,
      nombre: cita.servicioNombre,
      minutos: cita.duracionAplicada,
      precio: cita.precioAplicado,
      categoria: cita.servicioCategoria,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgendarCitaScreen(
          servicio: servicio,
          idCitaReagendar: cita.id,
        ),
      ),
    );

    if (!context.mounted) return;

    onCambio?.call();
  }

  Future<void> _reservarDeNuevo(BuildContext context) async {
    final servicio = Servicio(
      id: cita.idServicio,
      nombre: cita.servicioNombre,
      minutos: cita.duracionAplicada,
      precio: cita.precioAplicado,
      categoria: cita.servicioCategoria,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgendarCitaScreen(
          servicio: servicio,
        ),
      ),
    );

    if (!context.mounted) return;

    onCambio?.call();
  }

  @override
  Widget build(BuildContext context) {
    final cancelada = cita.estado == Cita.cancelada;

    final puedeReservarDeNuevo =
        cancelada && inicioDeCita(cita).isAfter(DateTime.now());

    if (cancelada) {
      if (!puedeReservarDeNuevo) {
        return const SizedBox.shrink();
      }

      final c = context.aura;

      return SizedBox(
        width: double.infinity,
        child: _Boton(
          texto: 'Reservar de nuevo',
          habilitado: true,
          fondo: c.boton,
          textoColor: c.textoBoton,
          onPressed: () => _reservarDeNuevo(context),
        ),
      );
    }
    final habilitado = citaModificable(cita);
    final c = context.aura;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _Boton(
                texto: context.t('citas.reagendar'),
                habilitado: habilitado,
                fondo: c.boton,
                textoColor: c.textoBoton,
                onPressed: () => _reagendar(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Boton(
                texto: context.t('citas.cancelar'),
                habilitado: habilitado,
                fondo: c.campoBloqueado,
                textoColor: c.texto,
                onPressed: () => confirmarCancelacion(context, cita, onCambio: onCambio),
              ),
            ),
          ],
        ),
        if (!habilitado)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: c.textoSecundario),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.t('citas.nota_24h'),
                    style: TextStyle(fontSize: 11, color: c.textoSecundario),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Boton extends StatelessWidget {
  final String texto;
  final bool habilitado;
  final Color fondo;
  final Color textoColor;
  final VoidCallback onPressed;

  const _Boton({
    required this.texto,
    required this.habilitado,
    required this.fondo,
    required this.textoColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return FilledButton(
      onPressed: habilitado ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: fondo,
        foregroundColor: textoColor,
        disabledBackgroundColor: c.superficie,
        disabledForegroundColor: c.textoSecundario.withValues(alpha: 0.5),
        elevation: 0,
        minimumSize: const Size.fromHeight(40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: habilitado ? Colors.transparent : c.borde),
        ),
      ),
      child: Text(texto),
    );
  }
}

/// Ventana "¿Cancelar tu cita?". Si se confirma, se pide cancelar la cita.
Future<void> confirmarCancelacion(
  BuildContext context,
  Cita c, {
  VoidCallback? onCambio,
}) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) {
     final ac = ctx.aura;
     return Dialog(
      backgroundColor: ac.superficie,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ctx.t('citas.cancelar_pregunta'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ac.rosaSuave.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.servicioNombre.isEmpty ? ctx.t('citas.servicio') : c.servicioNombre,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: ac.texto)),
                  const SizedBox(height: 4),
                  Text('${fechaCorta(c.fecha)} - ${hora12(c.horaInicio)}',
                      style: TextStyle(fontSize: 12, color: ac.texto)),
                  const SizedBox(height: 2),
                  Text(
                    ctx.t('citas.con', {
                      'nombre': c.empleadoNombre.isEmpty
                          ? ctx.t('citas.empleado_asignado')
                          : c.empleadoNombre
                    }),
                    style: TextStyle(fontSize: 12, color: ac.texto),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ctx.t('citas.cancelar_aviso'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: ac.textoSecundario),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: FilledButton.styleFrom(
                      backgroundColor: ac.boton,
                      foregroundColor: ac.textoBoton,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(ctx.t('comun.volver')),
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
                    child: Text(ctx.t('citas.si_cancelar')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    },
  );

  if (confirmar != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await CitasRepository.instance.cancelarCita(c.id);
    onCambio?.call();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.event_busy_outlined, size: 18, color: AppColors.rosa),
              const SizedBox(width: 10),
              Expanded(child: Text(context.t('citas.cancelada'))),
            ],
          ),
        ),
      );
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(textoError(context, e))),
      );
  }
}
