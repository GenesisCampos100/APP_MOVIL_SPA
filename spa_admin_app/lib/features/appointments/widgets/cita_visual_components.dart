import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/core/preferences/staff_preferences.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';

/// Presentación compartida entre Administración y Recepción.
/// No altera datos de citas, llamadas HTTP ni permisos.
enum CitaAvisoTipo { exito, error, advertencia, informacion }

void mostrarAvisoCita(
  BuildContext context,
  String mensaje, {
  CitaAvisoTipo tipo = CitaAvisoTipo.informacion,
}) {
  final Color fondo;
  final IconData icono;
  switch (tipo) {
    case CitaAvisoTipo.exito:
      fondo = const Color(0xFF237A51);
      icono = Icons.check_circle_rounded;
      break;
    case CitaAvisoTipo.error:
      fondo = const Color(0xFFB83E4F);
      icono = Icons.error_outline_rounded;
      break;
    case CitaAvisoTipo.advertencia:
      fondo = const Color(0xFF93651B);
      icono = Icons.warning_amber_rounded;
      break;
    case CitaAvisoTipo.informacion:
      fondo = const Color(0xFF396C96);
      icono = Icons.info_outline_rounded;
      break;
  }
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: fondo,
      behavior: SnackBarBehavior.floating,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 4),
      content: Row(
        children: [
          Icon(icono, color: Colors.white, size: 22),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}

const _mesesCita = <String>[
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];
const _diasSemanaCita = <String>['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

const _mesesCitaEn = <String>[
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _diasSemanaCitaEn = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _tCita(String es, String en) => AuthSession.esEmpleado
    ? StaffPreferences.tr(es, en) : es;

String fechaLegibleCita(DateTime fecha) =>
    AuthSession.esEmpleado && StaffPreferences.language.value == 'en'
        ? '${_mesesCitaEn[fecha.month - 1]} ${fecha.day}, ${fecha.year}'
        : '${fecha.day} de ${_mesesCita[fecha.month - 1]} de ${fecha.year}';

Future<DateTime?> abrirCalendarioCita(
  BuildContext context, {
  required DateTime fechaActual,
  required DateTime fechaMinima,
  required DateTime fechaMaxima,
}) {
  final inicial = fechaActual.isBefore(fechaMinima)
      ? fechaMinima
      : (fechaActual.isAfter(fechaMaxima) ? fechaMaxima : fechaActual);
  return showDatePicker(
    context: context,
    initialDate: inicial,
    firstDate: fechaMinima,
    lastDate: fechaMaxima,
    helpText: _tCita('Selecciona la fecha de la cita', 'Choose appointment date'),
    cancelText: _tCita('Volver', 'Back'),
    confirmText: _tCita('Elegir fecha', 'Choose date'),
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFDCA3BA) : AppColors.primaryPink,
          onPrimary: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF291D28) : Colors.white,
          surface: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF312730) : Colors.white,
        ),
        datePickerTheme: DatePickerThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF312730) : Colors.white,
          headerBackgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF634154) : AppColors.primaryPink,
          headerForegroundColor: Colors.white,
        ),
      ),
      child: child!,
    ),
  );
}

/// Una tira de siete días y un acceso al calendario mensual.
/// El backend sigue siendo la única fuente de horas disponibles.
class SelectorFechaCita extends StatelessWidget {
  final DateTime fecha;
  final DateTime fechaMinima;
  final DateTime fechaMaxima;
  final ValueChanged<DateTime> onSeleccionar;
  final VoidCallback onAbrirCalendario;
  final bool habilitado;

  const SelectorFechaCita({
    super.key,
    required this.fecha,
    required this.fechaMinima,
    required this.fechaMaxima,
    required this.onSeleccionar,
    required this.onAbrirCalendario,
    this.habilitado = true,
  });

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime(fechaMinima.year, fechaMinima.month, fechaMinima.day);
    final seleccionado = DateTime(fecha.year, fecha.month, fecha.day);
    final inicio = seleccionado.isAfter(hoy.add(const Duration(days: 6)))
        ? seleccionado
        : hoy;

    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? scheme.surfaceContainerHigh : const Color(0xFFFFF9FA),
        border: Border.all(color: dark ? scheme.outlineVariant : const Color(0xFFF0DDE3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_outlined, color: dark ? scheme.primary : AppColors.primaryPink, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fechaLegibleCita(fecha),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: habilitado ? onAbrirCalendario : null,
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: Text(_tCita('Ver mes', 'View month')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (indice) {
                final dia = inicio.add(Duration(days: indice));
                final activo = _mismoDia(dia, seleccionado);
                final permitido = habilitado && !dia.isAfter(fechaMaxima);
                return Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: permitido ? () => onSeleccionar(dia) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 49,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: activo ? (dark ? scheme.primary : AppColors.primaryPink) : (dark ? scheme.surface : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: activo ? (dark ? scheme.primary : AppColors.primaryPink) : (dark ? scheme.outlineVariant : const Color(0xFFF0E1E7)),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            AuthSession.esEmpleado && StaffPreferences.language.value == 'en'
                                ? _diasSemanaCitaEn[dia.weekday - 1]
                                : _diasSemanaCita[dia.weekday - 1],
                            style: TextStyle(
                              fontSize: 10,
                              color: activo ? (dark ? scheme.onPrimary : Colors.white) : (dark ? scheme.onSurfaceVariant : AppColors.textMuted),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${dia.day}',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: activo ? (dark ? scheme.onPrimary : Colors.white) : (dark ? scheme.onSurface : AppColors.textDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tCita('Selecciona un día o abre el calendario para otras fechas.',
                'Choose a day or open the calendar for another date.'),
            style: TextStyle(fontSize: 11,
                color: dark ? scheme.onSurfaceVariant : AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class SelectorHorariosCita extends StatelessWidget {
  final List<String> horas;
  final String? seleccion;
  final bool cargando;
  final bool habilitado;
  final String? error;
  final String mensajeVacio;
  final ValueChanged<String> onSeleccionar;
  final VoidCallback? onReintentar;

  const SelectorHorariosCita({
    super.key,
    required this.horas,
    required this.seleccion,
    required this.cargando,
    required this.habilitado,
    required this.error,
    required this.mensajeVacio,
    required this.onSeleccionar,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? scheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dark ? scheme.outlineVariant : const Color(0xFFE9E1E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: dark ? scheme.primary : AppColors.primaryPink, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(_tCita('Horarios disponibles', 'Available times'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
              if (!cargando && error == null && horas.isNotEmpty)
                Text(_tCita('${horas.length} opciones', '${horas.length} options'),
                  style: TextStyle(fontSize: 11, color: dark ? scheme.onSurfaceVariant : AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 11),
          if (cargando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFB83E4F)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(error!, style: const TextStyle(color: Color(0xFFB83E4F)))),
                ]),
                if (onReintentar != null)
                  TextButton.icon(
                    onPressed: onReintentar,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(_tCita('Reintentar', 'Retry')),
                  ),
              ],
            )
          else if (horas.isEmpty)
            Text(mensajeVacio, style: TextStyle(color: dark ? scheme.onSurfaceVariant : AppColors.textMuted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: horas.map((hora) {
                final activa = seleccion == hora;
                return ChoiceChip(
                  avatar: Icon(Icons.access_time_rounded,
                    size: 16, color: activa ? (dark ? scheme.onPrimary : Colors.white) : (dark ? scheme.primary : AppColors.primaryPink)),
                  label: Text(hora, style: TextStyle(
                    color: activa ? (dark ? scheme.onPrimary : Colors.white) : (dark ? scheme.onSurface : AppColors.textDark),
                    fontWeight: FontWeight.w700,
                  )),
                  selected: activa,
                  showCheckmark: false,
                  selectedColor: dark ? scheme.primary : AppColors.primaryPink,
                  backgroundColor: dark ? scheme.surface : const Color(0xFFFFF7F9),
                  side: BorderSide(color: activa ? (dark ? scheme.primary : AppColors.primaryPink) : (dark ? scheme.outlineVariant : const Color(0xFFF1DFE5))),
                  onSelected: habilitado ? (_) => onSeleccionar(hora) : null,
                );
              }).toList(),
            ),
          if (seleccion != null && !cargando && error == null) ...[
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF237A51), size: 17),
              const SizedBox(width: 6),
              Expanded(child: Text(_tCita('Horario elegido: $seleccion', 'Selected time: $seleccion'),
                style: TextStyle(fontSize: 12, color: dark ? scheme.primary : const Color(0xFF237A51), fontWeight: FontWeight.w700))),
            ]),
          ],
        ],
      ),
    );
  }
}
