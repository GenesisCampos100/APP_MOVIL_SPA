import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formato.dart';
import '../../../data/models/cita.dart';
import '../../../data/repositories/citas_repository.dart';
import '../../auth/auth_state.dart';

const Color _rojo = Color(0xFFE5174D);

// Colores de los botones desactivados (fondo, borde y texto, de claro a gris).
const Color _fondoDesactivado = Color(0xFFF2F2F2);
const Color _textoDesactivado = Color(0xFFB8B8B8);

/// Hora de inicio de la cita como fecha y hora completas.
DateTime inicioDeCita(Cita c) {
  final p = c.horaInicio.split(':');
  return DateTime(c.fecha.year, c.fecha.month, c.fecha.day, int.parse(p[0]), int.parse(p[1]));
}

/// Solo se puede cancelar o reagendar con más de 24 horas de anticipación.
bool citaModificable(Cita c) =>
    inicioDeCita(c).difference(DateTime.now()) > const Duration(hours: 24);

/// Botones "Reagendar" y "Cancelar" de una cita confirmada.
/// Si faltan 24 horas o menos, se ven desactivados (gris claro) y aparece
/// una nota que explica por qué.
class AccionesCita extends StatelessWidget {
  final Cita cita;

  // Colores solicitados
  static const texto = Color(0xFF222222);
  static const gris = Color(0xFF8A8A8A);

  const AccionesCita({super.key, required this.cita});

  @override
  Widget build(BuildContext context) {
    final habilitado = citaModificable(cita);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _Boton(
                texto: 'Reagendar',
                colorFondo: texto, // Aplicando el color #222222
                habilitado: habilitado,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reagendar: próximamente')),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Boton(
                texto: 'Cancelar',
                colorFondo: gris, // Aplicando el color #8A8A8A
                habilitado: habilitado,
                onPressed: () => confirmarCancelacion(context, cita),
              ),
            ),
          ],
        ),
        if (!habilitado)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.gris),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Solo puedes cancelar o reagendar hasta 24 horas antes de tu cita.',
                    style: TextStyle(fontSize: 11, color: AppColors.gris),
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
  final Color colorFondo;
  final VoidCallback onPressed;

  const _Boton({
    required this.texto,
    required this.habilitado,
    required this.colorFondo,
    required this.onPressed
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: habilitado ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: colorFondo,
        foregroundColor: Colors.white, // Texto en blanco cuando está activo
        disabledForegroundColor: _textoDesactivado,
        disabledBackgroundColor: _fondoDesactivado,
        minimumSize: const Size.fromHeight(40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(texto),
    );
  }
}

/// Ventana "¿Cancelar tu cita?". Si se confirma, la cita pasa a Cancelada.
Future<void> confirmarCancelacion(BuildContext context, Cita c) async {
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
              '¿Cancelar tu cita?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.rosaSuave.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.servicioNombre,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text('${fechaCorta(c.fecha)}\n${hora12(c.horaInicio)}',
                      style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text('Con ${c.empleadoNombre}',
                      style: const TextStyle(fontSize: 12, color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Esta acción no se puede deshacer y el horario quedará libre para otra persona.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.gris),
            ),
            const SizedBox(height: 22),
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
                    child: const Text('Volver'),
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
                    child: const Text('Sí, cancelar'),
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

  final messenger = ScaffoldMessenger.of(context);
  CitasRepository.instance.cancelar(AuthState.instance.usuario?.correo ?? '', c.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.event_busy_outlined, size: 18, color: AppColors.rosa),
            SizedBox(width: 10),
            Expanded(child: Text('Cita cancelada')),
          ],
        ),
      ),
    );
}
