import 'package:flutter/foundation.dart';

/// Preferencias de la app. Por ahora solo viven en memoria (se pierden al
/// cerrar la app). Para que se conserven hay dos opciones:
///   - guardarlas en el celular con el paquete shared_preferences, o
///   - guardarlas en la base de datos (PUT /clientes/preferencias).
class AjustesState extends ChangeNotifier {
  AjustesState._();
  static final AjustesState instance = AjustesState._();

  bool _recordatorios = true;

  bool get recordatorios => _recordatorios;

  void setRecordatorios(bool valor) {
    _recordatorios = valor;
    notifyListeners();
  }
}
