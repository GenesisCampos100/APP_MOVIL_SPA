import '../i18n/idioma_state.dart';

const _diasEs = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _diasEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _mesesCortosEs = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
const _mesesCortosEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _mesesLargosEs = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];
const _mesesLargosEn = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

bool get _en => IdiomaState.instance.esIngles;

/// "Mar 11 sep"  /  "Tue, Sep 11"
String fechaCorta(DateTime d) => _en
    ? '${_diasEn[d.weekday - 1]}, ${_mesesCortosEn[d.month - 1]} ${d.day}'
    : '${_diasEs[d.weekday - 1]} ${d.day} ${_mesesCortosEs[d.month - 1]}';

/// "Septiembre 2026"  /  "September 2026"
String mesAnio(DateTime d) =>
    '${(_en ? _mesesLargosEn : _mesesLargosEs)[d.month - 1]} ${d.year}';

/// "14:30" -> "2:30 pm"
String hora12(String hhmm) {
  final partes = hhmm.split(':');
  final h = int.parse(partes[0]);
  final m = partes[1];
  final sufijo = h >= 12 ? 'pm' : 'am';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:$m $sufijo';
}

/// "hace 1 mes"  /  "1 month ago"
String haceCuanto(DateTime fecha) {
  final dias = DateTime.now().difference(fecha).inDays;
  if (_en) {
    if (dias < 1) return 'today';
    if (dias < 30) return dias == 1 ? '1 day ago' : '$dias days ago';
    final meses = dias ~/ 30;
    if (meses < 12) return meses == 1 ? '1 month ago' : '$meses months ago';
    final anios = dias ~/ 365 < 1 ? 1 : dias ~/ 365;
    return anios == 1 ? '1 year ago' : '$anios years ago';
  }
  if (dias < 1) return 'hoy';
  if (dias < 30) return dias == 1 ? 'hace 1 día' : 'hace $dias días';
  final meses = dias ~/ 30;
  if (meses < 12) return meses == 1 ? 'hace 1 mes' : 'hace $meses meses';
  final anios = dias ~/ 365 < 1 ? 1 : dias ~/ 365;
  return anios == 1 ? 'hace 1 año' : 'hace $anios años';
}

/// "45 min", "1 hora" / "1 hour"
String duracionLegible(int minutos) {
  if (minutos == 60) return _en ? '1 hour' : '1 hora';
  return '$minutos min';
}

/// Tiempo transcurrido corto para notificaciones:
/// "ahora", "hace 10 min", "hace 3 h", "ayer"... / "now", "10 min ago"...
String tiempoRelativo(DateTime fecha) {
  final d = DateTime.now().difference(fecha);
  if (_en) {
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    if (d.inDays == 1) return 'yesterday';
    if (d.inDays < 30) return '${d.inDays} days ago';
    final m = d.inDays ~/ 30;
    return m == 1 ? '1 month ago' : '$m months ago';
  }
  if (d.inMinutes < 1) return 'ahora';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'hace ${d.inHours} h';
  if (d.inDays == 1) return 'ayer';
  if (d.inDays < 30) return 'hace ${d.inDays} días';
  final m = d.inDays ~/ 30;
  return m == 1 ? 'hace 1 mes' : 'hace $m meses';
}
