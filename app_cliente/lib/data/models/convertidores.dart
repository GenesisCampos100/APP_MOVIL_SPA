/// Convierten lo que llega de la API (JSON) a los tipos de Dart.
/// PostgreSQL + Node a veces entregan números como texto (por ejemplo
/// NUMERIC llega como "500.00"), por eso estas funciones aceptan ambos.

int aInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.parse(v.toString());
}

double aDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.parse(v.toString());
}

/// DATE de PostgreSQL ("2026-10-07" o "2026-10-07T00:00:00.000Z") -> DateTime.
DateTime aFecha(dynamic v) => DateTime.parse(v.toString().substring(0, 10));

/// DateTime -> "YYYY-MM-DD" para enviar a la API como DATE.
String aFechaSql(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// TIME de PostgreSQL ("14:30:00") -> "14:30".
String aHora(dynamic v) {
  final s = v.toString();
  return s.length >= 5 ? s.substring(0, 5) : s;
}
