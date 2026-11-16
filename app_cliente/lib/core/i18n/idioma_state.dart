import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Idioma de la app: 'es' (español) o 'en' (inglés).
/// Por ahora solo vive en memoria: al cerrar la app vuelve a español.
/// Para que se conserve se puede guardar con shared_preferences.
class IdiomaState extends ChangeNotifier {
  IdiomaState._();
  static final IdiomaState instance = IdiomaState._();

  String _codigo = 'es';
  String get codigo => _codigo;
  bool get esIngles => _codigo == 'en';

  /// Nombre del idioma actual, tal como se muestra en el Perfil.
  String get nombre => esIngles ? 'English' : 'Español';

  void cambiar(String nuevo) {
    if (nuevo == _codigo) return;
    _codigo = nuevo;
    notifyListeners();
  }
}

/// Hace que todas las pantallas que usan context.t(...) se vuelvan a
/// construir cuando cambia el idioma.
class IdiomaScope extends InheritedNotifier<IdiomaState> {
  const IdiomaScope({
    super.key,
    required IdiomaState state,
    required super.child,
  }) : super(notifier: state);

  static String codigoDe(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<IdiomaScope>();
    return scope?.notifier?.codigo ?? IdiomaState.instance.codigo;
  }
}
