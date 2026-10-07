const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _mesesCortos = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
const _mesesLargos = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

/// "Mar 11 sep"
String fechaCorta(DateTime d) =>
    '${_dias[d.weekday - 1]} ${d.day} ${_mesesCortos[d.month - 1]}';

/// "Septiembre 2026"
String mesAnio(DateTime d) => '${_mesesLargos[d.month - 1]} ${d.year}';

/// "14:30" -> "2:30 pm"
String hora12(String hhmm) {
  final partes = hhmm.split(':');
  final h = int.parse(partes[0]);
  final m = partes[1];
  final sufijo = h >= 12 ? 'pm' : 'am';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:$m $sufijo';
}

/// "hace 1 mes", "hace 5 meses", "hace 3 días"...
String haceCuanto(DateTime fecha) {
  final dias = DateTime.now().difference(fecha).inDays;
  if (dias < 1) return 'hoy';
  if (dias < 30) return dias == 1 ? 'hace 1 día' : 'hace $dias días';
  final meses = dias ~/ 30;
  if (meses < 12) return meses == 1 ? 'hace 1 mes' : 'hace $meses meses';
  final anios = dias ~/ 365 < 1 ? 1 : dias ~/ 365;
  return anios == 1 ? 'hace 1 año' : 'hace $anios años';
}
