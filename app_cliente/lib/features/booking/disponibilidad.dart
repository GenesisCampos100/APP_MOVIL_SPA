/// DISPONIBILIDAD DE PRUEBA (mock). Con la API, los horarios saldrán de la
/// tabla "horarios" del empleado menos las citas ya ocupadas.
///
/// Reglas actuales: de lunes a viernes, sin fechas pasadas, y si es hoy
/// solo horarios con al menos 1 hora de anticipación.
class Disponibilidad {
  static const horarios = ['10:00', '11:30', '13:00', '14:30', '16:00', '17:30'];

  static DateTime _hoy() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static bool diaHabil(DateTime d) {
    final dia = DateTime(d.year, d.month, d.day);
    if (dia.isBefore(_hoy())) return false;
    return dia.weekday != DateTime.saturday && dia.weekday != DateTime.sunday;
  }

  static bool horaDisponible(DateTime d, String hhmm) {
    if (!diaHabil(d)) return false;
    final dia = DateTime(d.year, d.month, d.day);
    if (dia != _hoy()) return true;
    final p = hhmm.split(':');
    final inicio = DateTime(d.year, d.month, d.day, int.parse(p[0]), int.parse(p[1]));
    return inicio.isAfter(DateTime.now().add(const Duration(minutes: 60)));
  }
}
