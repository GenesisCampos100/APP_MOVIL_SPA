import 'package:flutter/foundation.dart';

/// Permite cambiar de pestaña desde cualquier pantalla.
/// 0 Inicio · 1 Servicios · 2 Citas · 3 Perfil
class ShellController {
  static final ValueNotifier<int> tab = ValueNotifier<int>(0);
  static void irA(int indice) => tab.value = indice;
}
