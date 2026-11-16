import 'package:flutter/material.dart';

/// Colores que cambian entre el tema claro y el oscuro.
/// Uso:  color: context.aura.superficie
@immutable
class AuraColores extends ThemeExtension<AuraColores> {
  final Color fondo; //            fondo de las pantallas
  final Color superficie; //       tarjetas, ventanas y hojas
  final Color borde; //            bordes suaves
  final Color texto; //            texto principal e íconos
  final Color textoSecundario; //  texto gris
  final Color boton; //            botón principal (negro en claro, blanco en oscuro)
  final Color textoBoton; //       texto sobre el botón principal
  final Color rosaSuave; //        fondos rosa suave
  final Color campoBloqueado; //   campos de texto deshabilitados

  const AuraColores({
    required this.fondo,
    required this.superficie,
    required this.borde,
    required this.texto,
    required this.textoSecundario,
    required this.boton,
    required this.textoBoton,
    required this.rosaSuave,
    required this.campoBloqueado,
  });

  static const AuraColores claro = AuraColores(
    fondo: Colors.white,
    superficie: Colors.white,
    borde: Color(0xFFE3E3E3),
    texto: Color(0xFF222222),
    textoSecundario: Color(0xFF8A8A8A),
    boton: Colors.black,
    textoBoton: Colors.white,
    rosaSuave: Color(0xFFFBE4E6),
    campoBloqueado: Color(0xFFE6E6E6),
  );

  static const AuraColores oscuro = AuraColores(
    fondo: Color(0xFF121212),
    superficie: Color(0xFF1E1E1E),
    borde: Color(0xFF3A3A3C),
    texto: Color(0xFFF2F2F2),
    textoSecundario: Color(0xFFA0A0A0),
    boton: Colors.white,
    textoBoton: Colors.black,
    rosaSuave: Color(0xFF3A2A2D),
    campoBloqueado: Color(0xFF2A2A2A),
  );

  @override
  AuraColores copyWith({
    Color? fondo,
    Color? superficie,
    Color? borde,
    Color? texto,
    Color? textoSecundario,
    Color? boton,
    Color? textoBoton,
    Color? rosaSuave,
    Color? campoBloqueado,
  }) =>
      AuraColores(
        fondo: fondo ?? this.fondo,
        superficie: superficie ?? this.superficie,
        borde: borde ?? this.borde,
        texto: texto ?? this.texto,
        textoSecundario: textoSecundario ?? this.textoSecundario,
        boton: boton ?? this.boton,
        textoBoton: textoBoton ?? this.textoBoton,
        rosaSuave: rosaSuave ?? this.rosaSuave,
        campoBloqueado: campoBloqueado ?? this.campoBloqueado,
      );

  @override
  AuraColores lerp(ThemeExtension<AuraColores>? other, double t) {
    if (other is! AuraColores) return this;
    return AuraColores(
      fondo: Color.lerp(fondo, other.fondo, t)!,
      superficie: Color.lerp(superficie, other.superficie, t)!,
      borde: Color.lerp(borde, other.borde, t)!,
      texto: Color.lerp(texto, other.texto, t)!,
      textoSecundario: Color.lerp(textoSecundario, other.textoSecundario, t)!,
      boton: Color.lerp(boton, other.boton, t)!,
      textoBoton: Color.lerp(textoBoton, other.textoBoton, t)!,
      rosaSuave: Color.lerp(rosaSuave, other.rosaSuave, t)!,
      campoBloqueado: Color.lerp(campoBloqueado, other.campoBloqueado, t)!,
    );
  }
}

extension AuraContext on BuildContext {
  AuraColores get aura => Theme.of(this).extension<AuraColores>() ?? AuraColores.claro;

  /// Color del borde de los campos de texto (gris medio en claro, gris suave en oscuro).
  Color get bordeCampo =>
      Theme.of(this).brightness == Brightness.dark ? aura.textoSecundario : Colors.black54;
}
